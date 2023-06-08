BITS 64

global sleep
global usleep
global time
global num_to_str


SECTION .data

  rseed dq 0
  rseq  dq 0

sleep_struct:
  tv_sec  dq 0
  tv_usec dq 0


SECTION .text
;----------------------------------------------------------------------------
; void sleep(u64 seconds)
;  Sleep for a given number of seconds.
;----------------------------------------------------------------------------
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
; u64 time()
;  Gets the system time in seconds since the Unix epoch.
;----------------------------------------------------------------------------
time:
  mov rax, 201                     ; sys_time(
  xor rdi, rdi                     ;   NULL
  syscall                          ; )
  ret

;----------------------------------------------------------------------------
; void srand()
;  Seeds the random number generator.
;----------------------------------------------------------------------------
srand:
  call time                        ; rax = time()
  or rax, 1                        ; rax |= 1 (make sure it's odd)
  mov [rseed], rax                 ; rseed = rax
  ret

;----------------------------------------------------------------------------
; u64 rand()
;  Gets a random number.
;----------------------------------------------------------------------------
rand:
  mov qword rbx, [rseed]           ; rbx = rseed
  mov qword rcx, [rseq]            ; rcx = rseq
  call time                        ; rax = time()
  mul rax                          ; rax *= rax
  add rcx, rbx                     ; rcx += rbx
  add rax, rcx                     ; rax += rcx
  mov al, ah                       ; al = ah
  mov ah, dl                       ; ah = dl
  mov [rseq], rcx                  ; rseq = rcx
  ret

;----------------------------------------------------------------------------
; void num_to_str(u64 num, char* buf, u64 buf_len)
;  Converts a number to a string, placing it at the given address.
;----------------------------------------------------------------------------
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
