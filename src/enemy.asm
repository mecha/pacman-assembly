BITS 64

%include "macros.asm"

extern STDOUT
extern goto_pos
extern rand
extern lvl_is_wall
extern is_player_at
extern color_reset


global print_enemies
global update_enemies
global did_any_ghost_hit_player


S_IDLE equ 0
S_ACTIVE equ 1
S_RECALL equ 2
S_SPAWNING equ 3

SPAWN_RATE equ 20


SECTION .rodata

  sprite_normal db 27, "[91m☢"
  sprite_normal_len equ $-sprite_normal

  sprite_recall db "👀"
  sprite_recall_len equ $-sprite_recall


SECTION .data

blinky:
  x1 dq 16
  y1 dq 14
  u1 dq 0
  v1 dq 0
  s1 dq S_IDLE
  g1 db 27, "[91m☢"
pinky:
  x2 dq 19
  y2 dq 14
  u2 dq 0
  v2 dq 0
  s2 dq S_IDLE
  g2 db 27, "[95m☢"
inky:
  x3 dq 22
  y3 dq 14
  u3 dq 0
  v3 dq 0
  s3 dq S_IDLE
  g3 db 27, "[96m☢"
clyde:
  x4 dq 25
  y4 dq 14
  u4 dq 0
  v4 dq 0
  s4 dq S_IDLE
  g4 db 27, "[93m☢"


SECTION .text
;----------------------------------------------------------------------------
; void print_enemies()
;   Prints all enemies.
;----------------------------------------------------------------------------
print_enemies:
.blinky:
  push blinky
  call print_enemy
  add rsp, 8
.pinky:
  push pinky
  call print_enemy
  add rsp, 8
.inky:
  push inky
  call print_enemy
  add rsp, 8
.clyde:
  push clyde
  call print_enemy
  add rsp, 8
  ret

;----------------------------------------------------------------------------
; void print_enemy(enemy*)
;   Prints a single enemy.
;----------------------------------------------------------------------------
print_enemy:
  mov rbx, [rsp + 8]                  ; rbx = &enemy
  mov r8, [rbx]                       ; r8 = enemy.x
  inc r8                              ; r8 = r8 + 1
  mov r9, [rbx + 8]                   ; r9 = enemy.y
  add r9, $2                          ; r9 = r9 + 2
  push rbx                            ; save rbx
  screen_pos r8, r9                   ; goto_pos(r8, r9)
  pop rbx                             ; restore rbx
  mov r8, [rbx + 32]                  ; r8 = enemy.state
  cmp r8, S_RECALL                    ; if r8 = S_RECALL
  je .print_recall                    ;   goto .print_recall
.print_normal:                        ; else
  lea r8, [rbx + 40]                  ;   r8 = enemy.graphic
  print STDOUT, r8, sprite_normal_len ;   print r8
  call color_reset                    ; color_reset()
  ret
.print_recall:
  print STDOUT, sprite_recall, sprite_recall_len
  ret

;----------------------------------------------------------------------------
; void update_enemies()
;   Updates all the enemies.
;----------------------------------------------------------------------------
update_enemies:
  push blinky
  call update_enemy
  add rsp, 8
  push pinky
  call update_enemy
  add rsp, 8
  push inky
  call update_enemy
  add rsp, 8
  push clyde
  call update_enemy
  add rsp, 8
  ret

;----------------------------------------------------------------------------
; void update_enemy(ghost*)
;   Updates an enemy.
;----------------------------------------------------------------------------
update_enemy:
  mov rbx, [rsp + 8]               ; rbx = &ghost
  mov rax, [rbx + 32]              ; rax = ghost.sx
  push rbx
  cmp rax, S_IDLE                  ; if rax = S_IDLE
  je .idle                         ;   goto .idle
  cmp rax, S_ACTIVE                ; if rax = S_ACTIVE
  je .active                       ;   goto .active
  cmp rax, S_RECALL                ; else if rax = S_RECALL
  je .recall                       ;   goto .recall
  cmp rax, S_SPAWNING              ; elseif rax = S_SPAWNING
  je .spawning                     ;   goto .spawning
  jmp .done
.idle:
  call update_idle
  jmp .done
.active:
  call update_active
  jmp .done
.recall:
  call update_recall
  jmp .done
.spawning:
  call update_spawning
  jmp .done
.done:
  add rsp, 8
  ret

;----------------------------------------------------------------------------
; void update_idle(ghost*)
;   Updates an idle enemy.
;----------------------------------------------------------------------------
update_idle:
  mov rbx, [rsp + 8]               ; rbx = ghost struct ptr
  push rbx                         ; save rbx
  call rand                        ; rax = rand()
  pop rbx                          ; restore rbx
  xor rdx, rdx                     ; rdx = 0
  mov rcx, SPAWN_RATE              ; rcx = SPAWN_RATE
  div rcx                          ; rax = rax:rdx / SPAWN_RATE
  cmp rdx, 0                       ; if rdx (remainder) = 0
  je .spawn                        ;   goto .spawn
  ret
.spawn:
  mov qword [rbx + 32], S_SPAWNING ; ghost.sx = S_SPAWNING
  ret

;----------------------------------------------------------------------------
; void update_spawning(ghost*)
;   Updates a spawning enemy.
;----------------------------------------------------------------------------
update_spawning:
  mov rbx, [rsp + 8]               ; rbx = ghost struct ptr
.check:
  mov r8, [rbx + 8]                ; r8 = ghost.y
  cmp r8, 11                       ; if r8 <= 13
  jle .active                      ;   goto .active
  dec qword [rbx + 8]              ; ghost.y--
  ret
.active:
  mov qword [rbx + 32], S_ACTIVE   ; ghost.sx = S_ACTIVE
  ret

;----------------------------------------------------------------------------
; void update_recall(ghost*)
;   Updates a recalling enemy.
;----------------------------------------------------------------------------
update_recall:
  ret

;----------------------------------------------------------------------------
; void update_active(ghost*)
;   Updates an active enemy.
;----------------------------------------------------------------------------
update_active:
  mov rbx, [rsp + 8]               ; rbx = ghost struct ptr
.start:
  mov r8, [rbx]                    ; r8  = x
  mov r9, [rbx + 8]                ; r9  = y
  mov r10, [rbx + 16]              ; r10 = u
  mov r11, [rbx + 24]              ; r11 = v
.check_no_vel:
  lea rax, [r10 + r11]             ; rax = u + v
  cmp rax, 0                       ; if rax = 0
  je .turn                         ;   goto .turn
  jmp .lookahead                   ; else goto .lookahead
.lookahead:
  add r8, r10                      ; x += u
  add r9, r11                      ; y += v
  push r9                          ; arg1 = y
  push r8                          ; arg0 = x
  call lvl_is_wall                 ; rax = lvl_is_wall(r8, r9)
  pop r8                           ; pop args
  pop r9
  cmp rax, 0                       ; if rax = 0
  je .move                         ;   goto .move
.turn:
  push r11
  push r10
  push r9
  push r8
  call rand                        ; rax = rand()
  pop r8
  pop r9
  pop r10
  pop r11
  and rax, $3                      ; rax &= 0b11 (mask all but last 3 bits)
  cmp rax, 0                       ; if rax = 0
  je .turn_up                      ;   goto .turn_up
  cmp rax, 1                       ; else if rax = 1
  je .turn_down                    ;   goto .turn_down
  cmp rax, 2                       ; else if rax = 2
  je .turn_left                    ;   goto .turn_left
  jmp .turn_right                  ; else goto .turn_right
.turn_up:
  mov qword [rbx + 16], 0
  mov qword [rbx + 24], -1
  jmp .start
.turn_down:
  mov qword [rbx + 16], 0
  mov qword [rbx + 24], 1
  jmp .start
.turn_left:
  mov qword [rbx + 16], -1
  mov qword [rbx + 24], 0
  jmp .start
.turn_right:
  mov qword [rbx + 16], 1
  mov qword [rbx + 24], 0
  jmp .start
.move:
  mov [rbx], r8
  mov [rbx + 8], r9
  mov [rbx + 16], r10
  mov [rbx + 24], r11
  ret

;----------------------------------------------------------------------------
; bool did_any_ghost_hit_player()
;   Checks if an enemy has hit the player.
;----------------------------------------------------------------------------
did_any_ghost_hit_player:
.check_blinky:
  push blinky
  call did_ghost_hit_player
  add rsp, 8
  cmp rax, 1
  je .ret_true
.check_pinky:
  push pinky
  call did_ghost_hit_player
  add rsp, 8
  cmp rax, 1
  je .ret_true
.check_inky:
  push inky
  call did_ghost_hit_player
  add rsp, 8
  cmp rax, 1
  je .ret_true
.check_clyde:
  push clyde
  call did_ghost_hit_player
  add rsp, 8
  cmp rax, 1
  je .ret_true
.ret_false:
  mov qword rax, 0                 ; return false
  ret
.ret_true:
  mov qword rax, 1                 ; return true
  ret

;----------------------------------------------------------------------------
; bool did_ghost_hit_player(ghost*)
;   Checks if a specific ghost has hit the player.
;----------------------------------------------------------------------------
did_ghost_hit_player:
  xor rax, rax                     ; rax = 0
  mov rbx, [rsp + 8]               ; rbx = *ghost
  mov rdx, [rbx + 32]              ; rdx = ghost.state
  cmp rdx, S_ACTIVE                ; if rdx != S_ACTIVE
  jne .ret                         ;   goto .ret
  mov r8, [rbx]                    ; r8 = ghost.x
  mov r9, [rbx + 8]                ; r9 = ghost.y
  push r9                          ; arg1 = y
  push r8                          ; arg0 = x
  call is_player_at                ; is_player_at(ghost.x, ghost.y)
  add rsp, 16
.ret:
  ret
