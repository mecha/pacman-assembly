BITS 64

%include "macros.asm"

extern STDOUT
extern LVL_MAX_X
extern LVL_MAX_Y
extern goto_pos
extern lvl_is_wall
extern lvl_consume
extern num_to_str
extern color_reset
extern color_yellow

global reset_player
global print_player
global print_score
global print_lives
global update_player
global update_score
global player_move_up
global player_move_down
global player_move_left
global player_move_right
global is_player_at
global score

LIVES_X equ 20


SECTION .data

px dq 21                           ; position x
py dq 23                           ; position y
vx dq 0                            ; velocity x
vy dq 0                            ; velocity y
tx dq 0                            ; temp velocity x
ty dq 0                            ; temp velocity y

lives dq 3

score dq 0                         ; current score
score_str db "00000000"            ; current score as string
score_str_len equ $ - score_str

sprite_n dq 0                      ; current sprite index in sprite sheet
did_loop dq 0                      ; used during pos update to check if player looped


SECTION .rodata

sprites db 'Cc'                    ; sprite sheet
score_txt db "Score: ", 0          ; Score text
score_txt_len equ $ - score_txt


SECTION .text
;----------------------------------------------------------------------------
; void reset_player()
;----------------------------------------------------------------------------
reset_player:
  mov qword [px], 21
  mov qword [py], 23
  mov qword [vx], 0
  mov qword [vy], 0
  mov qword [tx], 0
  mov qword [ty], 0
  ret

;----------------------------------------------------------------------------
; void print_player()
;----------------------------------------------------------------------------
print_player:
  mov r8, [px]                             ; r8 = px
  inc r8                                   ; r8++
  mov r9, [py]                             ; r9 = y
  add r9, 2                                ; r9 += 2
  screen_pos r8, r9                        ; move cursor to [px], [py + 1]

  mov r9, sprites                          ; copy sprites address
  add r9, [sprite_n]                       ; offset by sprite_n (0 or 1)

  call color_yellow
  print STDOUT, r9, 1                      ; print sprite
  call color_reset
  ret

;----------------------------------------------------------------------------
; void print_score()
;----------------------------------------------------------------------------
print_score:
.print_label:
  screen_pos 1, 1                          ; move cursor to (1,1)
  print STDOUT, score_txt, score_txt_len   ; print score label
.reset_score_str:
  mov byte [score_str],   '0'              ; score_str[0] = 0
  mov byte [score_str+1], '0'              ; score_str[1] = 0
  mov byte [score_str+2], '0'              ; score_str[2] = 0
  mov byte [score_str+3], '0'              ; score_str[3] = 0
  mov byte [score_str+4], '0'              ; score_str[4] = 0
  mov byte [score_str+5], '0'              ; score_str[5] = 0
  mov byte [score_str+6], '0'              ; score_str[6] = 0
  mov byte [score_str+7], '0'              ; score_str[7] = 0
.score_to_str:
  push qword score_str_len                 ; push score_str_len
  push qword score_str                     ; push score_str
  push qword [score]                       ; push score
  call num_to_str                          ; num_to_str(score, &score_str, score_str_len)
  add rsp, 24                              ; pop args
.print_score_str:
  screen_pos 8, 1                          ; move cursor to (score_txt_len, 1)
  print STDOUT, score_str, score_str_len   ; print score_str
  ret

;----------------------------------------------------------------------------
; void print_lives()
;----------------------------------------------------------------------------
print_lives:
  call color_yellow
  mov rax, [lives]                          ; num of lives left to print
  dec rax                                   ; draw 1 less life (one is playing)
  mov rdx, LIVES_X                          ; x-coord to print at
.loop:
  cmp rax, 0                                ; if zero lives left
  jle .done                                 ;   goto .done
  push rax                                  ; save rax
  push rdx                                  ; save rdx
  screen_pos rdx, 1                         ; move to (rdx,1)
  print STDOUT, sprites, 1                  ; print sprite for 1 life
  pop rdx                                   ; restore rax
  pop rax                                   ; restore rdx
  dec rax                                   ; decrement num lives
  add rdx, 2                                ; increment x-coord
  jmp .loop
.done:
  call color_reset
  ret

;----------------------------------------------------------------------------
; void update_player()
;   Updates the player.
;----------------------------------------------------------------------------
update_player:
  call update_player_vel
  call update_player_pos
  call update_score
  ret

;----------------------------------------------------------------------------
; void update_player_pos()
;   Updates the player's position using the current velocity.
;----------------------------------------------------------------------------
update_player_pos:
.get_new_x:
  mov r8, [px]                             ; r8 = px
  add r8, [vx]                             ; r8 += rax
.get_new_y:
  mov r9, [py]                             ; r9 = py
  add r9, [vy]                             ; r9 += rax
  mov qword [did_loop], 0                  ; did_loop = false

.check_loop_x:
  cmp r8, 0                                ; if px < 0
  jl .loop_to_right                        ;    goto .loop_to_right
  cmp r8, LVL_MAX_X                        ; if px > LVL_MAX_X
  jge .loop_to_left                        ;    goto .loop_to_left
  jmp .check_loop_y                        ; else goto .check_loop_y
.loop_to_right:
  mov r8, LVL_MAX_X - 1                    ; r8 = LVL_MAX_X - 1
  mov qword [did_loop], 1                  ; did_loop = true
  jmp .check_if_wall                       ; goto .check_if_wall
.loop_to_left:
  xor r8, r8                               ; r8 = 0
  mov qword [did_loop], 1                  ; did_loop = true
  jmp .check_if_wall                       ; goto .check_if_wall

.check_loop_y:
  cmp r9, 0                                ; if py < 0
  jl .loop_to_bottom                       ;   goto .loop_to_bottom
  cmp r9, LVL_MAX_Y                        ; if py > LVL_MAX_Y
  jge .loop_to_top                         ;   goto .loop_to_top
  jmp .check_if_wall                       ; else goto .check_if_wall
.loop_to_bottom:
  mov r9, LVL_MAX_Y - 1                    ; r9 = LVL_MAX_Y - 1
  mov qword [did_loop], 1                  ; did_loop = true
  jmp .check_if_wall                       ; goto .check_if_wall
.loop_to_top:
  xor r9, r9                               ; r9 = 0
  mov qword [did_loop], 1                  ; did_loop = true
  jmp .check_if_wall                       ; goto .check_if_wall

.check_if_wall:
  mov rdx, [did_loop]                      ; rdx = did_loop
  cmp rdx, 1                               ; if rdx == 1
  je .move                                 ;   goto .move
  push r9                                  ; push y
  push r8                                  ; push x
  call lvl_is_wall                         ; lvl_is_wall(x, y)
  add rsp, 16                              ; pop args
  cmp rax, 1                               ; if rax == 1
  je .dont_move                            ;   goto .dont_move
.move:
  mov [px], r8                             ; px = r8
  mov [py], r9                             ; py = r9
  jmp .update_sprite                       ; goto .update_sprite
.dont_move:
.update_sprite:
  mov rax, [sprite_n]                      ; rax = sprite_n
  xor rax, 1                               ; rax = !rax
  mov [sprite_n], rax                      ; sprite_n = rax
  ret

;----------------------------------------------------------------------------
; void update_score()
;   Updates the score based on what the player has consumed (if anything).
;----------------------------------------------------------------------------
update_score:
  push qword [py]                          ; push y
  push qword [px]                          ; push x
  call lvl_consume                         ; lvl_consume(x, y)
  add rsp, 16                              ; pop args
  mov rdx, [score]                         ; rdx = score
  cmp rax, 1                               ; if rax == 1
  je .consume_dot                          ;   goto .consume_dot
  cmp rax, 2                               ; else if rax == 2
  je .consume_power                        ;   goto .consume_power
  jmp .done                                ; else goto .done
.consume_dot:
  inc rdx                                  ; rdx++
  jmp .done                                ; goto .done
.consume_power:
  add rdx, 10                              ; rdx += 10
  jmp .done                                ; goto .done
.done:
  mov [score], rdx                         ; score = rdx
  ret

;----------------------------------------------------------------------------
; void update_player_vel()
;   Dry-runs collision checks using the temp velocity.
;   If no collisions, the temp velocity becomes the real velocity.
;----------------------------------------------------------------------------
update_player_vel:
.get_new_x:
  mov r8, [px]                             ; r8  = x
  mov rax, [tx]                            ; rax = tx
  add r8, rax                              ; r8  = r8 + rax
.get_new_y:
  mov r9, [py]                             ; r9  = y
  mov rax, [ty]                            ; rax = ty
  add r9, rax                              ; r9 += r9 + rax
.check_if_wall:
  push r9                                  ; push y
  push r8                                  ; push x
  call lvl_is_wall                         ; is_wall(r8, r9)
  add rsp, 16                              ; pop args
  cmp rax, 1                               ; if is wall
  je .done                                 ;   goto .done
.update:
  mov rax, [tx]                            ; rax = tx
  mov [vx], rax                            ; vx  = rax
  mov rax, [ty]                            ; rax = ty
  mov [vy], rax                            ; vy  = rax
.done:
  ret

;----------------------------------------------------------------------------
; void player_move_up()
;   Sets the temp velocity to (0, -1)
;----------------------------------------------------------------------------
player_move_up:
  mov qword [tx], 0
  mov qword [ty], -1
  ret

;----------------------------------------------------------------------------
; void player_move_down()
;   Sets the temp velocity to (0, 1)
;----------------------------------------------------------------------------
player_move_down:
  mov qword [tx], 0
  mov qword [ty], 1
  ret

;----------------------------------------------------------------------------
; void player_move_left()
;   Sets the temp velocity to (-1, 0)
;----------------------------------------------------------------------------
player_move_left:
  mov qword [tx], -1
  mov qword [ty], 0
  ret

;----------------------------------------------------------------------------
; void player_move_right()
;   Sets the temp velocity to (1, 0)
;----------------------------------------------------------------------------
player_move_right:
  mov qword [tx], 1
  mov qword [ty], 0
  ret

;----------------------------------------------------------------------------
; bool is_player_at(u64 x, u64 y)
;   Checks if the player is at specific coords.
;----------------------------------------------------------------------------
is_player_at:
  mov r8, [rsp + 8]
  mov r9, [rsp + 16]
  mov rax, [px]
  cmp rax, r8
  jne .ret_false
  mov rax, [py]
  cmp rax, r9
  jne .ret_false
.ret_true:
  mov qword rax, 1
  ret
.ret_false:
  mov qword rax, 0
  ret

;----------------------------------------------------------------------------
; void lose_life()
;   Remove a life from the player and reset position.
;----------------------------------------------------------------------------
lose_life:
  mov rax, lives
  dec rax
  mov qword [lives], rax
  ret
