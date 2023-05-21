BITS 64

section .text
  ;----------------------------------------------------------------------------
  ; void sleep(u64 seconds)
  ;  Sleep for a given number of seconds.
  ;----------------------------------------------------------------------------
  global sleep
  sleep:
    mov qword rax, [rsp + 8]        ; rax = seconds
    mov qword [tv_sec], rax         ; sleep_struct.tv_sec = rax
    mov qword [tv_usec], 0          ; sleep_struct.tv_usec = 0
    mov rax, 35                     ; sys_nanosleep(
    mov rdi, sleep_struct           ;   &sleep_struct,
    xor rsi, rsi                    ;   NULL,
    syscall                         ; )
    ret

  ;----------------------------------------------------------------------------
  ; void sleep(u64 milliseconds)
  ;  Sleep for a given number of milliseconds.
  ;----------------------------------------------------------------------------
  global usleep
  usleep:
    mov qword rax, [rsp + 8]        ; rax = microseconds
    mov rdx, 1000000                ; rdx = 1000000 (1M)
    mul rdx                         ; rax = rax * rdx
    mov qword [tv_sec], 0           ; sleep_struct.tv_sec = 0
    mov qword [tv_usec], rax        ; sleep_struct.tv_usec = rax
    mov rax, 35                     ; sys_nanosleep(
    mov rdi, sleep_struct           ;   &sleep_struct,
    xor rsi, rsi                    ;   NULL,
    syscall                         ; )
    ret

  ;----------------------------------------------------------------------------
  ; void print_num(u64 num)
  ;  Prints a number to stdout.
  ;----------------------------------------------------------------------------
  global print_num
  print_num:
    mov rax, [rsp + 8]
    mov rdx, rax
    and rcx, 0xFFFFFFFFFFFFFFF0
    cmp rcx, 1
    ret

  ;----------------------------------------------------------------------------
  ; void num_to_str(u64 num, char* buf, u64 buf_len)
  ;  Converts a number to a string, placing it at the given address.
  ;----------------------------------------------------------------------------
  global num_to_str
  num_to_str:
    mov rax, [rsp + 8]               ; rax = num
    mov rbx, [rsp + 16]              ; rbx = buf
    mov rdi, [rsp + 24]              ; rdi = buf_len
    add rdi, rbx                     ; rdi = buf + buf_len
    sub rdi, 1                       ; rdi-- since buf[buf_len] is outside buf
    mov rcx, 10                      ; rcx = 10
    jl .loop_start
  .loop_start:
    cmp rbx, rdi
    jge .loop_end
    xor rdx, rdx                     ; rdx = 0
    div rcx                          ; rax = rax:rdx / rcx
    add rdx, '0'                     ; rdx += '0' (remainder to ASCII)
    mov byte [rdi], dl               ; buf[rdi - rbx] = dl
    dec rdi                          ; rdi++
    cmp rax, 0                       ; if rax != 0
    jne .loop_start                  ;   goto .loop_start
  .loop_end:
    ret

section .data
  sleep_struct:
    tv_sec  dq 0
    tv_usec dq 0
