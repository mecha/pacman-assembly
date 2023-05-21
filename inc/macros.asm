%macro print 3
  mov rax, 1
  mov rdi, %1
  mov rsi, %2
  mov rdx, %3
  syscall
%endmacro

%macro read 3
  mov rax, 0
  mov rdi, %1
  mov rsi, %2
  mov rdx, %3
  syscall
%endmacro

%macro open 3
  mov rax, 2
  mov rdi, %1
  mov rsi, %2
  mov rdx, %3
  syscall
%endmacro

%macro close 1
  mov rax, 3
  mov rdi, %1
  syscall
%endmacro

%macro exit 1
  mov rax, 60
  mov rdi, %1
  syscall
%endmacro

%macro screen_pos 2
  push qword %2
  push qword %1
  call goto_pos
  add rsp, 16
%endmacro
