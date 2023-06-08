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
extern print_enemies
extern update_player
extern did_any_ghost_hit_player
extern update_enemies
extern usleep
extern goto_pos
extern srand

global pacman
global play_game
global quit
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
  call srand
  call alt_buf
  call hide_cursor
  call clr_scr
  call do_menu
.end:
  jmp quit

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
  je .return
.draw:
  call clr_scr
  call print_help
  call print_score
  call print_level
  cmp rax, 0
  je .return
  call print_player
  call print_enemies
  call did_any_ghost_hit_player
  cmp rax, 1
  je .return
.update:
  call update_player
  call update_enemies
.delay:
  push qword [ftime]
  call usleep
  add rsp, 8
.repeat:
  jmp .loop
.return:
  ret

;----------------------------------------------------------------------------
; void quit()
;----------------------------------------------------------------------------
quit:
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
