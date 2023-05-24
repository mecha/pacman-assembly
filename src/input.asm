BITS 64

%include "macros.asm"

extern STDIN
extern player_move_up
extern player_move_down
extern player_move_left
extern player_move_right

global handle_input

%macro get_char 0
  mov byte [input], 0
  read STDIN, input, 1
  xor rdx, rdx
  mov rdx, [input]
%endmacro


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
.pause_loop:
  get_char
  cmp rdx, 'p'
  jne .pause_loop
  jmp .done

.exit:
  mov qword rax, 1
  ret

.done:
  mov qword rax, 0
  ret
