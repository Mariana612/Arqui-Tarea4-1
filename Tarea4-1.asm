section .bss 
    buffer resb 1024

section .data
    filename db 'input.txt', 0
    filemode db 'r', 0
    success_message db 'File opened successfully!', 0xa  ; Añadido 0xa para nueva línea
    error_message db 'Failed to open file.', 0xa

section .text
    global _start

_start:
    ; Abrir el archivo
    mov eax, 5              ; syscall para abrir un archivo
    mov ebx, filename       ; dirección del nombre del archivo
    mov ecx, 0              ; flags (0 para solo lectura)
    int 80h                 ; llama al kernel

    cmp eax, -1             ; Comprobar si hay error al abrir el archivo
    je error_occurred       ; Si eax es -1, se produjo un error

    mov esi, eax            ; Guardar el descriptor del archivo en esi

    ; Mostrar mensaje de éxito si el archivo se abrió correctamente
    mov eax, 4              ; syscall para escribir en la consola
    mov ebx, 1              ; descriptor de archivo de salida estándar
    mov ecx, success_message; dirección del mensaje de éxito
    mov edx, 24             ; longitud del mensaje de éxito
    int 80h                 ; llama al kernel

    ; Leer el contenido del archivo
    mov eax, 3              ; syscall para leer desde un archivo
    mov ebx, esi            ; descriptor de archivo de entrada
    mov ecx, buffer         ; dirección del buffer de lectura
    mov edx, 1024           ; número máximo de bytes a leer
    int 80h                 ; llama al kernel

    ; Imprimir el contenido del archivo leído
    mov eax, 4              ; syscall para escribir en la consola
    mov ebx, 1              ; descriptor de archivo de salida estándar
    mov ecx, buffer         ; buffer que contiene el texto leído
    mov edx, 1024            ; longitud del mensaje leído
    int 80h                 ; llama al kernel

    ; Cerrar el archivo
    mov eax, 6              ; syscall para cerrar un archivo
    mov ebx, esi            ; descriptor del archivo
    int 80h                 ; llama al kernel

    ; Salir del programa
    mov eax, 1              ; syscall para terminar el programa
    xor ebx, ebx            ; status 0
    int 80h                 ; llama al kernel

error_occurred:
    ; Mostrar mensaje de error
    mov eax, 4              ; syscall para escribir en la consola
    mov ebx, 1              ; descriptor de archivo de salida estándar
    mov ecx, error_message  ; dirección del mensaje de error
    mov edx, 21             ; longitud del mensaje de error
    int 80h                 ; llama al kernel

    ; Salir del programa con error
    mov eax, 1              ; syscall para terminar el programa
    mov ebx, 1              ; status 1
    int 80h                 ; llama al kernel