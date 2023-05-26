BITS 64

%include "macros.asm"

extern STDIN
extern STDOUT
extern STDERR
extern goto_pos
extern sleep
extern print_num
extern color_reset
extern color_yellow
extern color_blue
extern end_game

global LVL_MAX_X
global LVL_MAX_Y
global load_level
global print_level
global lvl_is_wall
global lvl_consume

LVL_BUF_LEN equ 5200
LVL_MAX_X equ 44
LVL_MAX_Y equ 31


SECTION .rodata

lvl_file_path db "level.dat", 0
lvl_file_path_len equ $ - lvl_file_path

success_msg db "Opened level file", 10, 0
success_msg_len equ $ - success_msg

error_msg db "Failed to open file", 10, 0
error_msg_len equ $ - error_msg

char_map db "╔╗╚╝║═┌┐└┘│─"
dot_char dw "⋅"
power_char dw "●"


SECTION .data

lvl_file_h dq 0
lvl_buf times LVL_BUF_LEN db 0
num_dots dq 0


SECTION .text

;----------------------------------------------------------------------------
; void load_level()
;----------------------------------------------------------------------------
load_level:
  open lvl_file_path, 0, 0666o                ; open file
  cmp rax, 0                                  ; if error
  jl .error                                   ;   goto .error
  mov [lvl_file_h], rax                       ; store file handle
  read [lvl_file_h], lvl_buf, LVL_BUF_LEN     ; read file contents into buffer
  close [lvl_file_h]                          ; close the file
  ret

.error:
  print STDERR, error_msg, error_msg_len
  exit 1

;----------------------------------------------------------------------------
; void print_level()
;   Possible to use a character map here? Would need to figure out how
;   to store the colors with the characters though.
;----------------------------------------------------------------------------
print_level:
  mov r8, 1                                   ; x = 1
  mov r9, 2                                   ; y = 2
  xor r10, r10                                ; offset in lvl_buf, start at 0
  mov qword [num_dots], 0                     ; num_dots = 0
.loop_start:
.move_cursor:
  push r8                                     ; save x (screen_pos overwrites these)
  push r9                                     ; save y
  push r10                                    ; save offset
  screen_pos r8, r9                           ; goto x, y
  pop r10                                     ; restore offset
  pop r9                                      ; restore y
  pop r8                                      ; restore x
.check_char:
  xor rax, rax                                ; rax = 0
  mov byte al, [lvl_buf + r10]                ; al = lvl_buf[r10]
  cmp al, 'z'                                 ; if al == 'z'
  je .loop_end                                ;   goto .print_end
  cmp al, 10                                  ; if al == '\n'
  je .print_nl                                ;   goto .print_nl
  cmp al, '.'                                 ; if al == '.'
  je .print_dot                               ;   goto .print_dot
  cmp al, ','                                 ; if al == ','
  je .print_power                             ;   goto .print_power
  cmp al, 'z'                                 ; if al == 'z'
  je .loop_end                                ;   goto .print_end
  cmp al, 'm'                                 ; if al >= 'm'
  jge .print_other                            ;   goto .print_other
  cmp al, 'a'                                 ; if al >= 'a'
  jge .print_wall                             ;   goto .print_wall
  jmp .loop_continue                          ; else goto .loop_continue
.print_nl:
  inc r9                                      ; y++
  xor r8, r8                                  ; x = 0
  jmp .loop_continue                          ; goto .loop_continue
.print_dot:
  inc qword [num_dots]                        ; num_dots++
  call color_yellow                           ; set color to yellow
  print STDOUT, dot_char, 4                   ; print dot
  call color_reset                            ; reset color
  jmp .loop_continue                          ; goto .loop_continue
.print_power:
  inc qword [num_dots]                        ; num_dots++
  print STDOUT, power_char, 4                 ; print power up
  jmp .loop_continue                          ; goto .loop_continue
.print_wall:
  sub al, 'a'                                 ; al =- 'a' (get offset from 'a')
  sub rsp, 8                                  ; allocate 8 bytes on stack
  xor rdx, rdx                                ; rdx = 0
  mov byte dl, [char_map + 3*rax]             ; dl = char_map[3*rax]
  mov byte [rsp], dl                          ; store char on stack
  mov byte dl, [char_map + 3*rax + 1]         ; dl = char_map[3*rax + 1]
  mov byte [rsp + 1], dl                      ; store color on stack
  mov byte dl, [char_map + 3*rax + 2]         ; dl = char_map[3*rax + 2]
  mov byte [rsp + 2], dl                      ; store color on stack
  call color_blue                             ; set color to blue
  print STDOUT, rsp, 3                        ; print wall (3 characters)
  call color_reset                            ; reset color
  add rsp, 8                                  ; free wall string from stack
  jmp .loop_continue                          ; goto .loop_continue
.print_other:
  push qword 32                               ; push space char
  print STDOUT, rsp, 1                        ; print space char
  add rsp, 8                                  ; free char from stack
  jmp .loop_continue                          ; goto .loop_continue
.loop_continue:
  inc r8                                      ; x++
  inc r10                                     ; offset++
  jmp .loop_start                             ; repeat
.loop_end:
  mov rax, [num_dots]
  cmp rax, 0                                  ; if num_dots == 0
  jle end_game                                ;   goto end_game
  ret                                         ; else return

;----------------------------------------------------------------------------
; void lvl_is_wall(u64 x, u64 y)
;----------------------------------------------------------------------------
lvl_is_wall:
.get_index:
  push rbp                                    ; save old frame pointer
  mov rbp, rsp                                ; set new frame pointer
  push qword [rbp + 24]                       ; push y
  push qword [rbp + 16]                        ; push x
  call lvl_ctoi                               ; lvl_ctoi(x, y)
  add rsp, 16                                 ; pop args
.check_if_wall:
  xor rdx, rdx                                ; rdx = 0
  mov byte dl, [lvl_buf + rax]                ; dl = lvl_buf[rax]
  cmp dl, 'a'                                 ; if dl < 'a'
  jl .not_wall                                ;   goto .not_wall
.is_wall:
  mov rax, 1                                  ; return 1 (wall)
  jmp .return
.not_wall:
  mov rax, 0                                  ; return 0 (not wall)
.return:
  pop rbp                                     ; restore old frame pointer
  ret

;----------------------------------------------------------------------------
; u64 lvl_consume(u64 x, u64 y)
;   Attempts to consume a dot or power at specific coordinates.
;   Returns 1 if a dot was consumed.
;   Returns 2 if a power was consumed.
;   Returns 0 if nothing was consumed.
;----------------------------------------------------------------------------
lvl_consume:
  push rbp                                    ; save old frame pointer
  mov rbp, rsp                                ; set new frame pointer
  push qword [rbp + 24]                       ; push y
  push qword [rbp + 16]                        ; push x
  call lvl_ctoi                               ; rax = lvl_ctoi(x, y)
  add rsp, 16                                 ; pop args
  xor rdx, rdx                                ; rdx = 0
  mov rdx, [lvl_buf + rax]                    ; rdx = lvl_buf[rax]
  mov byte [lvl_buf + rax], ' '               ; lvl_buf[rax] = ' '
  cmp dl, '.'                                 ; if dl == '.'
  je .dot                                     ;   goto .dot
  cmp dl, ','                                 ; else if dl == ','
  je .power                                   ;  goto .power
  jmp .none                                   ; else goto .none
.dot:                                         ; for dot:
  mov qword rax, 1                            ;   return 1
  jmp .return
.power:                                       ; for power:
  mov qword rax, 2                            ;   return 2
  jmp .return
.none:
  xor rax, rax                                ; return 0
.return:
  pop rbp                                     ; restore old frame pointer
  ret

;----------------------------------------------------------------------------
; u64 lvl_ctoi(u64 x, u64 y)
;   Translates level coords to buffer index
;   Formula: (y * (LVL_MAX_X + 1)) + x)
;----------------------------------------------------------------------------
lvl_ctoi:
  mov rax, LVL_MAX_X + 1                      ; rax = LVL_MAX_X + 1
  mul qword [rsp + 16]                        ; rax *= y
  add rax, [rsp + 8]                          ; rax += x
  ret

