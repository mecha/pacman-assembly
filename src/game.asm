BITS 64

%include "macros.asm"

section .text
  extern STDOUT
  extern usleep
  extern load_level
  extern print_level
  extern handle_input
  extern print_player
  extern update_player
  extern print_score
  extern clr_scr
  extern goto_pos
  extern nrm_buf
  extern alt_buf
  extern show_cursor
  extern hide_cursor

  ;----------------------------------------------------------------------------
  ; void pacman()
  ;----------------------------------------------------------------------------
  global pacman
  pacman:
    call load_level
    call alt_buf
    call hide_cursor

  .loop:

  .input:
    call handle_input
    cmp rax, 1
    je .loop_end

  .draw:
    call clr_scr
    call print_level
    call print_help
    call print_player
    call print_score

  .update:
    call update_player

  .delay:
    push qword [ftime]
    call usleep
    add rsp, 8

  .repeat:
    jmp .loop

  .loop_end:
    call clr_scr
    call show_cursor
    call nrm_buf
    ret

  ;----------------------------------------------------------------------------
  ; void print_help()
  ;----------------------------------------------------------------------------
  global print_help
  print_help:
    screen_pos 1, 33
    print STDOUT, help_txt, help_txt_len
    ret

section .rodata
  help_txt db "Controls:", 10, " * Move: Up/Down/Left/Right", 10, " * Pause: p", 10, " * Exit: q"
  help_txt_len equ $ - help_txt

section .data
  ftime dq 100
  fcount dq 10
  score dq 0
