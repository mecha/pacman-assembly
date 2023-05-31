BITS 64

%include "macros.asm"

NUM_MENU_ITEMS equ 2
MENU_X equ 5
MENU_Y equ 11

extern STDOUT
extern KEY_ENTER
extern KEY_UP
extern KEY_DOWN
extern clr_scr
extern goto_pos
extern play_game
extern quit
extern read_input

global do_menu


SECTION .rodata

sel_str db "⯈ ", 0
sel_str_len equ $-sel_str

play_str db "Start Game", 0
play_str_len equ $-play_str

quit_str db "Quit", 0
quit_str_len equ $-quit_str

menu_input_map dq menu_enter, menu_up, menu_down, 0, 0, 0, 0

logo   db  "  ╔══════════════════════════════════════════════════════╗", 10
logo_1 db  "  ║ ██████   █████   ██████ ███    ███  █████  ███    ██ ║", 10
logo_2 db  "  ║ ██   ██ ██   ██ ██      ████  ████ ██   ██ ████   ██ ║", 10
logo_3 db  "  ║ ██████  ███████ ██      ██ ████ ██ ███████ ██ ██  ██ ║", 10
logo_4 db  "  ║ ██      ██   ██ ██      ██  ██  ██ ██   ██ ██  ██ ██ ║", 10
logo_5 db  "  ║ ██      ██   ██  ██████ ██      ██ ██   ██ ██   ████ ║", 10
logo_7 db  "  ╚══════════════════════════════════════════════════════╝", 10
logo_len equ $-logo

credits db "    By Miguel Muscat - github.com/mecha", 10
credits_len equ $-credits


SECTION .data

sel_n dq 0


SECTION .text
;----------------------------------------------------------------------------
; void do_menu()
;----------------------------------------------------------------------------
do_menu:
.loop:
  call clr_scr
.logo:
  screen_pos 1, 2
  print STDOUT, logo, logo_len
.menu:
  screen_pos MENU_X, MENU_Y
  print STDOUT, play_str, play_str_len
  screen_pos MENU_X, MENU_Y + 1
  print STDOUT, quit_str, quit_str_len
.credits:
  screen_pos 1, MENU_Y + NUM_MENU_ITEMS + 2
  print STDOUT, credits, credits_len
.highlight:
  mov qword rbx, 11
  add rbx, [sel_n]
  screen_pos 3, rbx
  print STDOUT, sel_str, sel_str_len
.input:
  call read_input
  cmp rax, KEY_ENTER
  je .do_selection
  cmp rax, KEY_UP
  je .menu_up
  cmp rax, KEY_DOWN
  je .menu_down
  jmp .input
.menu_up:
  call menu_up
  jmp .loop
.menu_down:
  call menu_down
  jmp .loop
.do_selection:
  call menu_enter
  jmp .loop
  ret

;----------------------------------------------------------------------------
; void menu_up()
;----------------------------------------------------------------------------
menu_up:
  cmp qword [sel_n], 0
  je .loop_around
  dec qword [sel_n]
  ret
.loop_around:
  mov qword [sel_n], NUM_MENU_ITEMS - 1
  ret

;----------------------------------------------------------------------------
; void menu_down()
;----------------------------------------------------------------------------
menu_down:
  cmp qword [sel_n], NUM_MENU_ITEMS - 1
  je .loop_around
  inc qword [sel_n]
  ret
.loop_around:
  mov qword [sel_n], 0
  ret

;----------------------------------------------------------------------------
; void menu_enter()
;----------------------------------------------------------------------------
menu_enter:
  mov rax, [sel_n]
  cmp rax, 0
  je play_game
  cmp rax, 1
  jmp quit
.return:
  ret
