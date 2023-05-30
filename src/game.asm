BITS 64

%include "macros.asm"

extern STDOUT
extern load_level
extern alt_buf
extern nrm_buf
extern hide_cursor
extern show_cursor
extern clr_scr
extern handle_input
extern do_menu
extern print_level
extern reset_player
extern print_player
extern print_score
extern update_player
extern usleep
extern goto_pos

global pacman
global play_game
global end_game
global print_help

SECTION .rodata

help_txt db "Controls:", 10, " * Move: Up/Down/Left/Right", 10, " * Pause: p", 10, " * Exit: q"
help_txt_len equ $ - help_txt

SECTION .data

ftime dq 100
score dq 0
fcount dq 10

SECTION .text
;----------------------------------------------------------------------------
; void pacman()
;----------------------------------------------------------------------------
pacman:
  call alt_buf
  call hide_cursor
  call clr_scr
  call do_menu
.end:
  call show_cursor
  call nrm_buf
  jmp end_game

;----------------------------------------------------------------------------
; void play_game()
;----------------------------------------------------------------------------
play_game:
  call clr_scr
  call load_level
  call reset_player
.loop:
.input:
  call handle_input
  cmp rax, 1
  je end_game
.draw:
  call clr_scr
  je end_game
  call print_help
  call print_score
  call print_level
  cmp rax, 0
  je .return
  call print_player
.update:
  call update_player
.delay:
  push qword [ftime]
  call usleep
  add rsp, 8
.repeat:
  jmp .loop
.return:
  ret

;----------------------------------------------------------------------------
; void end_game()
;----------------------------------------------------------------------------
end_game:
  call clr_scr
  call show_cursor
  call nrm_buf
  exit 0

;----------------------------------------------------------------------------
; void print_help()
;----------------------------------------------------------------------------
print_help:
  screen_pos 1, 33
  print STDOUT, help_txt, help_txt_len
  ret
