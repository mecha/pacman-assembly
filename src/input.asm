BITS 64

%include "macros.asm"

KEY_ENTER equ 1
KEY_UP equ 2
KEY_DOWN equ 3
KEY_LEFT equ 4
KEY_RIGHT equ 5
KEY_PAUSE equ 6
KEY_QUIT equ 7

extern STDIN
extern STDOUT
extern player_move_up
extern player_move_down
extern player_move_left
extern player_move_right
extern goto_pos

global handle_input
global read_input
global KEY_ENTER
global KEY_UP
global KEY_DOWN
global KEY_LEFT
global KEY_RIGHT
global KEY_PAUSE
global KEY_QUIT

%macro get_char 0
  mov byte [input], 0
  read STDIN, input, 1
  xor rdx, rdx
  mov rdx, [input]
%endmacro


SECTION .rodata

paused_clr db "      "
paused_str db "PAUSED"
paused_str_len equ $-paused_str


SECTION .data

input dq 0


SECTION .text

;----------------------------------------------------------------------------
; u64 handle_input()
;   Returns 1 if the user wants to quit the game.
;----------------------------------------------------------------------------
handle_input:
  mov qword rax, 0
  get_char

.check_arrow:
  cmp rdx, 27
  jne .check_quit
.check_arrow_esc:
  get_char
  cmp rdx, 0
  je .exit
.check_arrow_bracket:
  cmp rdx, '['
  jne .check_quit
.get_arrow_char:
  get_char
  jmp .check_up

.check_up:
  cmp rdx, 'A'
  jne .check_down
  call player_move_up
  jmp .done

.check_down:
  cmp rdx, 'B'
  jne .check_left
  call player_move_down
  jmp .done

.check_left:
  cmp rdx, 'D'
  jne .check_right
  call player_move_left
  jmp .done

.check_right:
  cmp rdx, 'C'
  jne .check_quit
  call player_move_right
  jmp .done

.check_quit:
  cmp rdx, 'q'
  je .exit
  jmp .check_pause

.check_pause:
  cmp rdx, 'p'
  jne .done
  screen_pos 38, 1
  print STDOUT, paused_str, paused_str_len
.pause_loop:
  get_char
  cmp rdx, 'p'
  jne .pause_loop
  screen_pos 38, 1
  print STDOUT, paused_clr, paused_str_len
  jmp .done

.exit:
  mov qword rax, 1
  ret

.done:
  mov qword rax, 0
  ret

;----------------------------------------------------------------------------
; int read_input()
; Reads input and returns the key code.
;----------------------------------------------------------------------------
read_input:
  xor rax, rax                               ; Clear rax
  get_char                                   ; Read char byte (goes into rdx)

.check_enter:
  cmp rdx, 13                                ; Check if ENTER
  jne .check_quit                            ; If not, goto .check_arrow
  mov qword rax, KEY_ENTER                   ; Set rax to KEY_ENTER
  jmp .return                                ; Goto .return

.check_quit:
  cmp rdx, 'q'                               ; Check if 'q'
  jne .check_pause                           ; If not, goto .check_pause
  mov qword rax, KEY_QUIT                    ; Set rax to KEY_QUIT
  jmp .return                                  ; Goto .return

.check_pause:
  cmp rdx, 'p'                               ; Check if 'p'
  jne .check_arrow                           ; If not, goto .check_arrow
  mov qword rax, KEY_PAUSE                   ; Set rax to KEY_PAUSE
  jmp .return                                ; Goto .return

.check_arrow:
  cmp rdx, 27                                ; Check if ESC
  jne .return                                ; If not, return
  get_char                                   ; Read char byte
  cmp rdx, 0                                 ; Check if 0
  je .return                                 ; If yes, return. It's the ESC key
  cmp rdx, '['                               ; Else, check if '['
  jne .return                                ; If not, return
.get_arrow_char:
  get_char                                   ; Read char byte
  cmp rdx, 'A'                               ; Check if 'A'
  jne .check_down                            ; If not, goto .check_down
  mov qword rax, KEY_UP                      ; Set rax to KEY_UP
  jmp .return                                ; Goto .return
.check_down:
  cmp rdx, 'B'                               ; Check if 'B'
  jne .check_left                            ; If not, goto .check_left
  mov qword rax, KEY_DOWN                    ; Set rax to KEY_DOWN
  jmp .return                                ; Goto .return
.check_left:
  cmp rdx, 'D'                               ; Check if 'D'
  jne .check_right                           ; If not, goto .check_right
  mov qword rax, KEY_LEFT                    ; Set rax to KEY_LEFT
  jmp .return                                ; Goto .return
.check_right:
  cmp rdx, 'C'                               ; Check if 'C'
  jne .return                                ; If not, goto .return
  mov qword rax, KEY_RIGHT                   ; Set rax to KEY_RIGHT
  jmp .return                                ; Goto .return

.return:
  ret
