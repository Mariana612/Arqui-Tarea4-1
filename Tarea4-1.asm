section .data
    filename db 'input.txt', 0
    filemode db 'r', 0
    success_message db 'File opened successfully!', 0xa, 0 ; Añadido 0xa para nueva línea
    error_message db 'Failed to open file.', 0xa, 0
    tamano_invalido db 'El archivo contiene más de 1024 caracteres', 0xa, 0
    digitos db '0123456789ABCDEF'  
    printCont dq 0
    newline_message db 0xa, 0 ; Mensaje de nueva línea
    word_message db 'Word count: ', 0xa
    debug_string db "hola", 10, 0 ; Format string for printing character and its ASCII value

section .bss 
    buffer resb 1025

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
    mov edx, 1025         
    int 80h                 
    
    call count_chars
    
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

count_chars:
	mov rax, buffer
	mov rcx, 0 ;Inicializar el contador de caracteres
	mov rdi, 0
	
countLoop:
	cmp rcx, 1024 ;Compara si se llegó a los 1024 bytes
    jg error_tamano

    cmp byte [rax + rdi], 0 ;Verifica si esta en null
    je endCount
    
    cmp byte [rax + rdi], 10 ;Verifica si el caracter es un salto de linea
    je enter_char
    
    inc rdi
    inc rcx
    jmp countLoop

enter_char:
	inc rdi
	dec rcx
    jmp countLoop
    
endCount:
	ret

error_tamano:
	; Mostrar mensaje de error
    mov rax, 1          
    mov rdi, 1          
    mov rsi, tamano_invalido    
    mov rdx, 45          
    syscall                 

    ; Salir del programa con error
    jmp _finishCode


count_words:
    xor rax, rax            ; Inicializar contador de palabras a 0
    movzx rcx, byte [rdi]   ; Cargar el primer byte del buffer en rcx

.loop:
    test rcx, rcx           ; Comprobar si hemos llegado al final del buffer
    jz .end_count           ; Si es así, terminar el conteo

    cmp rcx, ' '            ; Comprobar si el byte es un espacio en blanco
    je .skip_space          ; Si es un espacio, saltar al siguiente byte

    ; Si no es un espacio, incrementar el contador de palabras
    cmp byte [rdi - 1], ' ' ; Comprobar si el byte anterior era un espacio
    jne .skip_space         ; Si no lo era, saltar al siguiente byte
    inc rax                 ; Si era un espacio, incrementar el contador de palabras

.skip_space:
    inc rdi                 ; Avanzar al siguiente byte en el buffer
    movzx rcx, byte [rdi]   ; Cargar el siguiente byte del buffer en rcx
    jmp .loop               ; Continuar el bucle

.end_count:
    ; Verificar si la última palabra no está seguida por un espacio
    cmp byte [rdi - 1], ' ' 
    je .skip_last_word      ; Si hay un espacio, omitir la última palabra

    ; Verificar si el último byte es un espacio en blanco
    cmp byte [rdi - 1], 0   ; Si es el final del archivo
    je .skip_last_word      ; Omitir la última palabra

    inc rax                 ; Si no hay espacio después de la última palabra, contarla

.skip_last_word:
    ret      





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

_finishCode:			;finaliza codigo
	mov rax, 60
	mov rdi, 0
	syscall

