section .data
    filename db 'input.txt', 0
    filemode db 'r', 0
    success_message db 'File opened successfully!', 0xa, 0 ; Añadido 0xa para nueva línea
    error_message db 'Failed to open file.', 0xa, 0
    tamano_invalido db 'El archivo contiene más de 1024 caracteres', 0xa, 0
    digitos db '0123456789ABCDEF'  
    printCont dq 0
    newline_message db 0xa, 0 ; Mensaje de nueva línea
    word_message db 0xa, 'Word count: ', 0xa

section .bss 
    buffer resb 1025

section .text
    global _start

_start:
    call _openFile		; Abre el archivo a leer

    cmp eax, -1         	; Comprobar si hay error al abrir el archivo
    je error_occurred   	; Si eax es -1, se produjo un error

    mov esi, eax        	; Guardar el descriptor del archivo en esi
    call _readFile
              
    
    call count_chars     

    mov rax, buffer
    call _genericprint             
    
    mov rax, word_message	; Mostrar el recuento de palabras	
    call _genericprint               


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
	mov rax, error_message
	call _genericprint
	jmp _finishCode
    	              
                 
_openFile:
    	mov rax, 2          	; Para abrir el documento
    	mov rdi, filename      	; Documento a leer
   	mov rsi, 0              ; read only
    	syscall                 
	ret

_readFile:
	mov eax, 0              ; Para leer el documento
	mov edi, esi             
	mov rsi, buffer         ; Pointer a buffer
	mov edx, 1025           ; Tamano
	syscall

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
	cmp byte [rax + rdi + 1], 0 ;Verifica si el caracter es un salto de linea
    je enter_final
    
    inc rdi
    inc rcx
    jmp countLoop
     
enter_final:    
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
    xor rax, rax            
    xor rbx, rbx            
    movzx rcx, byte [rdi]   ; Cargar el primer byte del buffer en rcx

.loop:
    test rcx, rcx           ; Comprobar si hemos llegado al final del buffer
    jz .end_count       

    cmp rcx, ' '            ; Comprobar si el byte es un espacio en blanco
    je .check_word 

    cmp rcx, 10             ; Comprobar si el byte es un salto de línea
    je .check_word    

    cmp rcx, ','            ; Comprobar si el byte es una coma
    je .check_word        

    cmp rcx, '.'            ; Comprobar si el byte es un punto
    je .check_word 
    
    cmp rcx, '?'            ; Comprobar si el byte es un signo de pregunta  
    je .check_word     
    
    cmp rcx, '¿'            ; Comprobar si el byte es un signo de pregunta  
    je .check_word    
    
    cmp rcx, '!'            ; Comprobar si el byte es un signo de exclamacion  
    je .check_word  
    
    cmp rcx, '¡'            ; Comprobar si el byte es un signo de exclamacion  
    je .check_word  

    ; Activar la bandera de palabra si el byte actual no es un espacio, salto de línea o signo de puntuación
    mov rbx, 1              ; Activar la bandera de palabra
    jmp .next_byte          ; Saltar al siguiente byte

.check_word:
    cmp rbx, 0              ; Comprobar si la bandera de palabra está activada
    je .next_byte           

    ; Incrementar el contador de palabras, desactivar la bandera de palabra
    inc rax                 ; Incrementar el contador de palabras
    xor rbx, rbx            ; Desactivar la bandera de palabra

.next_byte:
    inc rdi                 ; Avanzar al siguiente byte en el buffer
    movzx rcx, byte [rdi]   ; Cargar el siguiente byte del buffer en rcx
    jmp .loop               

.end_count:
    cmp rbx, 1              ; Comprobar si estamos dentro de una palabra al final del buffer
    jne .end_count_done     

    inc rax                 ; Incrementar el contador si estamos dentro de una palabra al final
    jmp .end_count_done

.end_count_done:
    ret                     ; Terminar la función
                  

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
    mov rdx, 0                    
    div r10                         
	add rdx, "0"
	mov [rdi +rsi], dl
	inc rsi
	cmp rax, 0
	jg .loop
	
	mov rdx, rdi
	lea rcx, [rdi + rsi -1]
	jmp .reversetest

.reverseloop:
    mov al, [rdx]
    mov ah, [rcx]
    mov [rcx], al
    mov [rdx], ah
    inc rdx
    dec rcx

.reversetest:
    cmp rdx, rcx
    jl .reverseloop

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

