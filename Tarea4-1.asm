section .bss 
    buffer resb 1024

section .data
    filename db 'input.txt', 0
    filemode db 'r', 0
    success_message db 'File opened successfully!', 0xa, 0 ; Añadido 0xa para nueva línea
    error_message db 'Failed to open file.', 0xa, 0
    digitos db '0123456789ABCDEF'  
    printCont dq 0
    word_count dq 0  ; Variable para almacenar el recuento de palabras
    newline_message db 0xa, 0 ; Mensaje de nueva línea
    word_message db 'Word count: ', 0xa

section .text
    global _start

_start:
    ; Abrir el archivo
    mov eax, 5              ; syscall para abrir un archivo
    mov ebx, filename       ; dirección del nombre del archivo
    mov ecx, 0              ; flags (0 para solo lectura)
    int 80h

    cmp eax, -1             ; Comprobar si hay error al abrir el archivo
    je error_occurred       ; Si eax es -1, se produjo un error

    mov esi, eax            ; Guardar el descriptor del archivo en esi

    ; Leer el contenido del archivo
    mov eax, 3             
    mov ebx, esi            
    mov ecx, buffer        
    mov edx, 1024         
    int 80h                 
    
    ;imprimir buffer
    mov rax, 4             
    mov rbx, 1             
    mov rcx, buffer      
    mov rdx, 1024          
    int 80h                 
    
    ; Mostrar el recuento de palabras
    mov eax, 4             
    mov ebx, 1             
    mov ecx, word_message 
    mov edx, 13            
    int 80h                 


    ; Asegurar que el puntero al buffer apunte al comienzo del texto
	mov rdi, buffer         ; Puntero al inicio del buffer
	call count_words        ; Llamar a la función count_words

    ; Convertir el recuento de palabras a cadena y mostrarlo
    mov rsi, rax
    call _startItoa         ; Llama a la función de conversión a cadena

    ; Cerrar el archivo
    mov eax, 6             
    mov ebx, esi        
    int 80h                 

    ; Salir del programa
    mov eax, 1             
    xor ebx, ebx            
    int 80h                

error_occurred:
    ; Mostrar mensaje de error
    mov eax, 4              
    mov ebx, 1              
    mov ecx, error_message
    mov edx, 21            
    int 80h                 

    ; Salir del programa con error
    mov eax, 1              
    mov ebx, 1              
    int 80h                 


count_words:
    xor rax, rax            ; Inicializar contador de palabras a 0

.loop:
    movzx rcx, byte [rdi]   ; Cargar el siguiente byte del buffer en rcx
    test rcx, rcx           ; Comprobar si hemos llegado al final del buffer
    jz .end_count           ; Si es así, terminar el conteo

    cmp rcx, ' '            ; Comprobar si el byte es un espacio en blanco
    jne .skip_space         ; Si no es un espacio, saltar al siguiente byte

    inc rax                 ; Incrementar el contador de palabras si se encuentra un espacio

.skip_space:
    inc rdi                 ; Avanzar al siguiente byte en el buffer
    jmp .loop               ; Continuar el bucle

.end_count:
    cmp byte [rdi - 1], ' ' ; Verificar si la última palabra no está seguida por un espacio
    jne .last_word          ; Si no hay espacio después de la última palabra, contarla

.skip_last_word:
    ret                     ; Si todas las palabras han sido contadas, terminar la función

.last_word:
    inc rax                 ; Incrementar el contador de palabras para la última palabra
    jmp .skip_last_word     ; Saltar al final de la función








_startItoa:
    mov rdi, buffer
    mov rsi, rsi 
    mov rbx, 10       ; La base
    call itoa
    mov r8, rax                     ; Almacena la longitud de la cadena
    
    ; Añade un salto de línea
    mov byte [buffer + r8], 10
    inc r8
    
    ; Termina la cadena con null
    mov byte [buffer + r8], 0

    mov rax, buffer
    
    call  _genericprint
    
    ret


; Definición de la función ITOA
itoa:
    mov rax, rsi                    ; Mueve el número a convertir (en rsi) a rax
    mov rsi, 0                      ; Inicializa rsi como 0 (contador de posición en la cadena)
    mov r10, 10                    

.loop:
    xor rdx, rdx                    ; Limpia rdx para la división
    div r10                         ; Divide rax por rbx
    cmp rbx, 10
    jbe .lower_base_digits          ; Salta si la base es menor o igual a 10

    ; Maneja bases mayores que 10
    movzx rdx, dl
    mov dl, byte [digitos + rdx]
    jmp .store_digit

.lower_base_digits:
    ; Maneja bases menores o iguales a 10
    add dl, '0'                     ; Convierte el resto a un carácter ASCII

.store_digit:
    mov [rdi + rsi], dl            ; Almacena el carácter en el buffer
    inc rsi                         ; Se mueve a la siguiente posición en el buffer
    cmp rax, 0                      ; Verifica si el cociente es cero
    jg .loop                        ; Si no es cero, continúa el bucle

    ; Invierte la cadena
    mov rdx, rdi
    lea rcx, [rdi + rsi - 1]
    jmp reversetest

reverseloop:
    mov al, [rdx]
    mov ah, [rcx]
    mov [rcx], al
    mov [rdx], ah
    inc rdx
    dec rcx

reversetest:
    cmp rdx, rcx
    jl reverseloop

    mov rax, rsi                    ; Devuelve la longitud de la cadena
    ret

_genericprint:
    mov qword [printCont], 0        ;coloca rdx en 0 (contador)
    push rax        ;almacenamos lo que esta en rax

_printLoop:
    mov cl, [rax]
    cmp cl, 0
    je _endPrint
    inc qword [printCont]                ;aumenta contador
    inc rax
    jmp _printLoop

_endPrint:
    mov rax, 1
    mov rdi, 1
    mov rdx,[printCont]
    pop rsi            ;texto
    syscall
    ret

