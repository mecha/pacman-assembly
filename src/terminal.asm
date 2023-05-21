BITS 64

%include "macros.asm"

STDIN equ 0
STDOUT equ 1
STDERR equ 2

global STDIN
global STDOUT
global STDERR

section .text
  ;----------------------------------------------------------------------------
  ; void clr_scr()
  ;   Clear the screen.
  ;----------------------------------------------------------------------------
  global clr_scr
  clr_scr:
    print STDOUT, CLR_SCR, CLR_SCR_LEN
    ret

  ;----------------------------------------------------------------------------
  ; void nrm_buf()
  ;   Switch to the normal buffer.
  ;----------------------------------------------------------------------------
  global nrm_buf
  nrm_buf:
    print STDOUT, NRM_BUF, NRM_BUF_LEN
    ret

  ;----------------------------------------------------------------------------
  ; void alt_buf()
  ;   Switch to the alternate buffer.
  ;----------------------------------------------------------------------------
  global alt_buf
  alt_buf:
    print STDOUT, ALT_BUF, ALT_BUF_LEN
    ret

  ;----------------------------------------------------------------------------
  ; void show_cursor()
  ;   Show the cursor.
  ;----------------------------------------------------------------------------
  global show_cursor
  show_cursor:
    print STDOUT, SHOW_CURSOR, SHOW_CURSOR_LEN
    ret

  ;----------------------------------------------------------------------------
  ; void hide_cursor()
  ;   Hide the cursor.
  ;----------------------------------------------------------------------------
  global hide_cursor
  hide_cursor:
    print STDOUT, HIDE_CURSOR, HIDE_CURSOR_LEN
    ret

  ;----------------------------------------------------------------------------
  ; void color_reset()
  ;   Resets the color to normal.
  ;----------------------------------------------------------------------------
  global color_reset
  color_reset:
    print STDOUT, C_RESET, 4
    ret

  ;----------------------------------------------------------------------------
  ; void color_yellow()
  ;   Sets the color to yellow.
  ;----------------------------------------------------------------------------
  global color_yellow
  color_yellow:
    print STDOUT, C_YELLOW, 5
    ret

  ;----------------------------------------------------------------------------
  ; void color_blue()
  ;   Sets the color to blue.
  ;----------------------------------------------------------------------------
  global color_blue
  color_blue:
    print STDOUT, C_BLUE, 5
    ret

  ;----------------------------------------------------------------------------
  ; void goto_pos(u64 row, u64 col)
  ;   Move the cursos to (row, col)
  ;----------------------------------------------------------------------------
  global goto_pos
  goto_pos:
    mov r12, 10
    mov r8, [rsp + 16]                ; r8 = row
    mov r9, r8                        ; r9 = row
    mov r10, [rsp + 8]                ; r10 = col
    mov r11, r10                      ; r11 = col
  .digit_1_to_str:
    mov rax, r8                       ; rax = row
    mov rdx, 0                        ; rdx = 0
    div r12                           ; rax = rax:rdx / r12 (10)
    mov r8, rax                       ; r8 = rax (result)
    mov r9, rdx                       ; r9 = rdx (remainder)
    add r8, '0'                       ; r8 += '0' (ASCII 48)
    add r9, '0'                       ; r9 += '0'
  .digit_2_to_str:
    mov rax, r10                      ; rax = col
    xor rdx, rdx                      ; rdx = 0
    div r12                           ; rax = rax:rdx / r12 (10)
    mov r10, rax                      ; r10 = rax (result)
    mov r11, rdx                      ; r11 = rdx (remainder)
    add r10, '0'                      ; r10 += '0' (ASCII 48)
    add r11, '0'                      ; r11 += '0'
  .prep_regs:
    mov rax, r8                       ; rax = row tens
    mov rdx, r9                       ; rdx = row units
    mov rsi, r10                      ; rsi = col tens
    mov rdi, r11                      ; rdi = col units
  .build_str:
    sub rsp, 8                        ; allocate 8 bytes on the stack
    mov byte [rsp], 27                ; rsp[0] = 27
    mov byte [rsp + 1], '['           ; rsp[1] = '['
    mov byte [rsp + 2], al            ; rsp[2] = row tens
    mov byte [rsp + 3], dl            ; rsp[3] = row units
    mov byte [rsp + 4], ';'           ; rsp[4] = ';'
    mov byte [rsp + 5], sil           ; rsp[5] = col tens
    mov byte [rsp + 6], dil           ; rsp[6] = col units
    mov byte [rsp + 7], 'H'           ; rsp[7] = 'H'
  .print:
    print STDOUT, rsp, 8              ; print string on the stack
  .done:
    add rsp, 8                        ; free string from the stack
    ret

section .rodata
  CLR_SCR db 27, "[2J", 0
  CLR_SCR_LEN equ $ - CLR_SCR

  NRM_BUF db 27, "[?1049l", 0
  NRM_BUF_LEN equ $ - NRM_BUF

  ALT_BUF db 27, "[?1049h", 0
  ALT_BUF_LEN equ $ - ALT_BUF

  SHOW_CURSOR db 27, "[?25h", 0
  SHOW_CURSOR_LEN equ $ - SHOW_CURSOR

  HIDE_CURSOR db 27, "[?25l", 0
  HIDE_CURSOR_LEN equ $ - HIDE_CURSOR

  C_RESET db 27, '[0m'    ; Normal color ANSI escape code
  C_YELLOW db 27, '[33m'   ; Yellow color ANSI escape code
  C_BLUE db 27, '[34m'   ; Blue color ANSI escape code

  global C_RESET
  global C_YELLOW
  global C_BLUE
