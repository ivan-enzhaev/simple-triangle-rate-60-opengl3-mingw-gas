.intel_syntax noprefix

#define WS_OVERLAPPEDWINDOW 0x00CF0000
#define WS_VISIBLE          0x10000000
#define WS_CLIPSIBLINGS     0x04000000
#define WS_CLIPCHILDREN     0x02000000
#define WM_DESTROY          0x0002
#define WM_SIZE             0x0005
#define WM_PAINT            0x000F
#define WM_KEYDOWN          0x0100
#define WM_TIMER            0x0113
#define VK_ESCAPE           0x1B

#define GL_COLOR_BUFFER_BIT 0x4000
#define GL_TRIANGLES        4
#define GL_FLOAT            0x1406
#define GL_ARRAY_BUFFER     0x8892
#define GL_STATIC_DRAW      0x88E4
#define GL_FRAGMENT_SHADER  0x8B30
#define GL_VERTEX_SHADER    0x8B31

.section .data
width:  .long 800
height: .long 600

bg_rgba:
    .float 0.1, 0.1, 0.15, 1.0

// 3 vertices: (x, y, z, r, g, b) = 24 bytes/vertex, 72 bytes total
vertices:
    .float -0.6, -0.6, 0.0,   1.0, 0.0, 0.0
    .float  0.6, -0.6, 0.0,   0.0, 1.0, 0.0
    .float  0.0,  0.6, 0.0,   0.0, 0.4, 1.0

ctx_attribs:
    .long 0x2091, 3         // WGL_CONTEXT_MAJOR_VERSION_ARB = 3
    .long 0x2092, 3         // WGL_CONTEXT_MINOR_VERSION_ARB = 3
    .long 0x9126, 1         // WGL_CONTEXT_PROFILE_MASK_ARB = CORE
    .long 0

vs_src:
    .asciz "#version 330 core\nlayout(location=0) in vec3 p;\nlayout(location=1) in vec3 c;\nout vec3 vc;\nvoid main(){ gl_Position=vec4(p,1.0); vc=c; }\n"
fs_src:
    .asciz "#version 330 core\nin vec3 vc;\nout vec4 fc;\nvoid main(){ fc=vec4(vc,1.0); }\n"

vs_ptr: .quad vs_src
fs_ptr: .quad fs_src

WndClassName: .asciz "GL33CLS"
WindowTitle:  .asciz "OpenGL 3.3 Core Triangle (GAS)"

s_wglCreateContextAttribsARB: .asciz "wglCreateContextAttribsARB"
s_glGenVertexArrays:          .asciz "glGenVertexArrays"
s_glBindVertexArray:          .asciz "glBindVertexArray"
s_glGenBuffers:               .asciz "glGenBuffers"
s_glBindBuffer:               .asciz "glBindBuffer"
s_glBufferData:               .asciz "glBufferData"
s_glCreateShader:             .asciz "glCreateShader"
s_glShaderSource:             .asciz "glShaderSource"
s_glCompileShader:            .asciz "glCompileShader"
s_glCreateProgram:            .asciz "glCreateProgram"
s_glAttachShader:             .asciz "glAttachShader"
s_glLinkProgram:              .asciz "glLinkProgram"
s_glUseProgram:               .asciz "glUseProgram"
s_glVertexAttribPointer:      .asciz "glVertexAttribPointer"
s_glEnableVertexAttribArray:  .asciz "glEnableVertexAttribArray"

.balign 8
gl_table:
    .quad s_glGenVertexArrays,         p_glGenVertexArrays
    .quad s_glBindVertexArray,         p_glBindVertexArray
    .quad s_glGenBuffers,              p_glGenBuffers
    .quad s_glBindBuffer,              p_glBindBuffer
    .quad s_glBufferData,              p_glBufferData
    .quad s_glCreateShader,            p_glCreateShader
    .quad s_glShaderSource,            p_glShaderSource
    .quad s_glCompileShader,           p_glCompileShader
    .quad s_glCreateProgram,           p_glCreateProgram
    .quad s_glAttachShader,            p_glAttachShader
    .quad s_glLinkProgram,             p_glLinkProgram
    .quad s_glUseProgram,              p_glUseProgram
    .quad s_glVertexAttribPointer,     p_glVertexAttribPointer
    .quad s_glEnableVertexAttribArray, p_glEnableVertexAttribArray
    .quad 0, 0

.balign 8
WC:
    .long 0x0023            // CS_VREDRAW | CS_HREDRAW | CS_OWNDC
    .long 0
    .quad WndProc
    .long 0, 0
WC_hInstance:
    .quad 0, 0
WC_hCursor:
    .quad 0, 1, 0, WndClassName

PIXELFORMATDESCRIPTOR:
    .word 0x28, 1
    .long 0x25              // PFD_DRAW_TO_WINDOW | PFD_SUPPORT_OPENGL | PFD_DOUBLEBUFFER
    .byte 0, 32
    .zero 13
    .byte 24
    .zero 16

.section .bss
.balign 8
hWnd: .skip 8
hDC:  .skip 8
hRC:  .skip 8
msg:  .skip 48
ps:   .skip 80              // PAINTSTRUCT (72 bytes on x64)
vao:  .skip 4
vbo:  .skip 4

.balign 8
p_wglCreateContextAttribsARB: .skip 8
p_glGenVertexArrays:          .skip 8
p_glBindVertexArray:          .skip 8
p_glGenBuffers:               .skip 8
p_glBindBuffer:               .skip 8
p_glBufferData:               .skip 8
p_glCreateShader:             .skip 8
p_glShaderSource:             .skip 8
p_glCompileShader:            .skip 8
p_glCreateProgram:            .skip 8
p_glAttachShader:             .skip 8
p_glLinkProgram:              .skip 8
p_glUseProgram:               .skip 8
p_glVertexAttribPointer:      .skip 8
p_glEnableVertexAttribArray:  .skip 8

.section .text
.globl main

main:
    push rbx
    push r12
    push r13
    sub rsp, 96             // 32B shadow space + 64B stack args (16-byte aligned)

    xor ecx, ecx
    call GetModuleHandleA
    mov qword ptr [rip + WC_hInstance], rax

    xor ecx, ecx
    mov edx, 0x7F00         // IDC_ARROW
    call LoadCursorA
    mov qword ptr [rip + WC_hCursor], rax

    lea rcx, [rip + WC]
    call RegisterClassA

    xor ecx, ecx
    movzx edx, ax
    lea r8, [rip + WindowTitle]
    mov r9d, (WS_CLIPSIBLINGS | WS_CLIPCHILDREN | WS_VISIBLE | WS_OVERLAPPEDWINDOW)
    mov dword ptr [rsp + 32], 100
    mov dword ptr [rsp + 40], 100
    mov eax, dword ptr [rip + width]
    mov dword ptr [rsp + 48], eax
    mov eax, dword ptr [rip + height]
    mov dword ptr [rsp + 56], eax
    mov qword ptr [rsp + 64], 0
    mov qword ptr [rsp + 72], 0
    mov rax, qword ptr [rip + WC_hInstance]
    mov qword ptr [rsp + 80], rax
    mov qword ptr [rsp + 88], 0
    call CreateWindowExA
    mov qword ptr [rip + hWnd], rax

    mov rcx, rax
    call GetDC
    mov qword ptr [rip + hDC], rax

    mov rcx, rax
    lea rdx, [rip + PIXELFORMATDESCRIPTOR]
    call ChoosePixelFormat

    mov rcx, qword ptr [rip + hDC]
    mov edx, eax
    lea r8, [rip + PIXELFORMATDESCRIPTOR]
    call SetPixelFormat

    // Temporary legacy context to fetch wglCreateContextAttribsARB
    mov rcx, qword ptr [rip + hDC]
    call wglCreateContext
    mov rbx, rax
    mov rcx, qword ptr [rip + hDC]
    mov rdx, rbx
    call wglMakeCurrent

    lea rcx, [rip + s_wglCreateContextAttribsARB]
    call wglGetProcAddress
    mov qword ptr [rip + p_wglCreateContextAttribsARB], rax

    xor ecx, ecx
    xor edx, edx
    call wglMakeCurrent
    mov rcx, rbx
    call wglDeleteContext

    // Real OpenGL 3.3 Core context
    mov rcx, qword ptr [rip + hDC]
    xor edx, edx
    lea r8, [rip + ctx_attribs]
    call qword ptr [rip + p_wglCreateContextAttribsARB]
    mov qword ptr [rip + hRC], rax

    mov rcx, qword ptr [rip + hDC]
    mov rdx, rax
    call wglMakeCurrent

    // Load all GL 3.3 function pointers
    lea rbx, [rip + gl_table]
.Lload_gl:
    mov rcx, qword ptr [rbx]
    test rcx, rcx
    jz .Lload_done
    call wglGetProcAddress
    mov rdx, qword ptr [rbx + 8]
    mov qword ptr [rdx], rax
    add rbx, 16
    jmp .Lload_gl
.Lload_done:

    // Compile vertex + fragment shaders and link program
    mov ecx, GL_VERTEX_SHADER
    call qword ptr [rip + p_glCreateShader]
    mov r12d, eax
    mov ecx, r12d
    mov edx, 1
    lea r8, [rip + vs_ptr]
    xor r9d, r9d
    call qword ptr [rip + p_glShaderSource]
    mov ecx, r12d
    call qword ptr [rip + p_glCompileShader]

    mov ecx, GL_FRAGMENT_SHADER
    call qword ptr [rip + p_glCreateShader]
    mov r13d, eax
    mov ecx, r13d
    mov edx, 1
    lea r8, [rip + fs_ptr]
    xor r9d, r9d
    call qword ptr [rip + p_glShaderSource]
    mov ecx, r13d
    call qword ptr [rip + p_glCompileShader]

    call qword ptr [rip + p_glCreateProgram]
    mov ebx, eax
    mov ecx, ebx
    mov edx, r12d
    call qword ptr [rip + p_glAttachShader]
    mov ecx, ebx
    mov edx, r13d
    call qword ptr [rip + p_glAttachShader]
    mov ecx, ebx
    call qword ptr [rip + p_glLinkProgram]
    mov ecx, ebx
    call qword ptr [rip + p_glUseProgram]

    // Setup VAO + VBO
    mov ecx, 1
    lea rdx, [rip + vao]
    call qword ptr [rip + p_glGenVertexArrays]
    mov ecx, dword ptr [rip + vao]
    call qword ptr [rip + p_glBindVertexArray]

    mov ecx, 1
    lea rdx, [rip + vbo]
    call qword ptr [rip + p_glGenBuffers]
    mov ecx, GL_ARRAY_BUFFER
    mov edx, dword ptr [rip + vbo]
    call qword ptr [rip + p_glBindBuffer]

    mov ecx, GL_ARRAY_BUFFER
    mov edx, 72
    lea r8, [rip + vertices]
    mov r9d, GL_STATIC_DRAW
    call qword ptr [rip + p_glBufferData]

    // Attribute 0: position (3 floats, stride 24, offset 0)
    xor ecx, ecx
    mov edx, 3
    mov r8d, GL_FLOAT
    xor r9d, r9d
    mov dword ptr [rsp + 32], 24
    mov qword ptr [rsp + 40], 0
    call qword ptr [rip + p_glVertexAttribPointer]
    xor ecx, ecx
    call qword ptr [rip + p_glEnableVertexAttribArray]

    // Attribute 1: color (3 floats, stride 24, offset 12)
    mov ecx, 1
    mov edx, 3
    mov r8d, GL_FLOAT
    xor r9d, r9d
    mov dword ptr [rsp + 32], 24
    mov qword ptr [rsp + 40], 12
    call qword ptr [rip + p_glVertexAttribPointer]
    mov ecx, 1
    call qword ptr [rip + p_glEnableVertexAttribArray]

    xor ecx, ecx
    xor edx, edx
    mov r8d, dword ptr [rip + width]
    mov r9d, dword ptr [rip + height]
    call glViewport

    // Trigger initial paint and start ~60 Hz frame timer
    mov rcx, qword ptr [rip + hWnd]
    xor edx, edx
    xor r8d, r8d
    call InvalidateRect

    mov rcx, qword ptr [rip + hWnd]
    mov edx, 1              // timer ID = 1
    mov r8d, 16             // 16 ms (~60 Hz)
    xor r9d, r9d            // NULL -> post WM_TIMER
    call SetTimer

.Lmsg_loop:
    lea rcx, [rip + msg]
    xor edx, edx
    xor r8d, r8d
    xor r9d, r9d
    call GetMessageA        // sleeps until WM_TIMER or input/paint arrives
    test eax, eax
    jle .Lstop              // 0 = WM_QUIT, -1 = error

    cmp dword ptr [rip + msg + 8], WM_KEYDOWN
    jne .Ldispatch
    cmp qword ptr [rip + msg + 16], VK_ESCAPE
    je .Lstop

.Ldispatch:
    lea rcx, [rip + msg]
    call DispatchMessageA
    jmp .Lmsg_loop

.Lstop:
    xor ecx, ecx
    call ExitProcess

WndProc:
    push rbx
    sub rsp, 32             // 8B (push) + 32B = 40B -> 16-byte aligned
    mov rbx, rcx            // save hwnd

    cmp edx, WM_PAINT
    je .Lpaint
    cmp edx, WM_TIMER
    je .Ltimer
    cmp edx, WM_DESTROY
    je .Ldestroy
    cmp edx, WM_SIZE
    je .Lsize

.Ldef:
    call DefWindowProcA
    add rsp, 32
    pop rbx
    ret

.Lpaint:
    cmp qword ptr [rip + hRC], 0
    je .Ldef

    mov rcx, rbx
    lea rdx, [rip + ps]
    call BeginPaint

    movss xmm0, dword ptr [rip + bg_rgba]
    movss xmm1, dword ptr [rip + bg_rgba + 4]
    movss xmm2, dword ptr [rip + bg_rgba + 8]
    movss xmm3, dword ptr [rip + bg_rgba + 12]
    call glClearColor

    mov ecx, GL_COLOR_BUFFER_BIT
    call glClear

    mov ecx, GL_TRIANGLES
    xor edx, edx
    mov r8d, 3
    call glDrawArrays

    mov rcx, qword ptr [rip + hDC]
    call SwapBuffers

    mov rcx, rbx
    lea rdx, [rip + ps]
    call EndPaint

    xor eax, eax
    add rsp, 32
    pop rbx
    ret

.Ltimer:
    mov rcx, rbx
    xor edx, edx
    xor r8d, r8d
    call InvalidateRect
    xor eax, eax
    add rsp, 32
    pop rbx
    ret

.Ldestroy:
    xor ecx, ecx
    call PostQuitMessage
    xor eax, eax
    add rsp, 32
    pop rbx
    ret

.Lsize:
    movzx r8d, r9w
    shr r9d, 16
    mov dword ptr [rip + width], r8d
    mov dword ptr [rip + height], r9d
    xor ecx, ecx
    xor edx, edx
    call glViewport
    xor eax, eax
    add rsp, 32
    pop rbx
    ret
