section .data
    filename db 'input.txt', 0
    error_message db 'Failed to open file.', 0xa, 0
    tamano_invalido db 'El archivo contiene más de 2048 caracteres', 0xa, 0
    digitos db '0123456789ABCDEF'  
    printCont dq 0
    newline_message db 0xa, 0 ; Mensaje de nueva línea
    word_message db 0xa, 'Word count: ', 0xa
    espacio db 10

section .bss 
    buffer resb 2050
    nuevo_buffer resb 2050

section .text
    global _start

_start:
    call _openFile		; Abre el archivo a leer

    cmp rax, -2         	; Comprobar si hay error al abrir el archivo
    je error_occurred   	; Si eax es -1, se produjo un error

    mov rsi, rax        	; Guardar el descriptor del archivo en esi
    call _readFile
              
    
    call count_chars ;Contar chars   

    mov rax, buffer ;Imprimir el texto
    call _genericprint
    
    ;Imprimir un espacio
    mov rax, 1          
    mov rdi, 1          
    mov rsi, espacio    
    mov rdx, 1          
    syscall
	
    mov rsi, buffer
	mov rdi, nuevo_buffer
	call convert_upper_to_lower
	
	mov rax, nuevo_buffer
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
    mov rax, 3             
    mov rdi, rsi        
    syscall                 

    ; Salir del programa
    jmp _finishCode                

error_occurred:           
	mov rax, error_message
	call _genericprint
	jmp _finishCode
    	              
                 
_openFile:
    mov rax, 2          	; Para abrir el documento
    mov rdi, filename      	; Documento a leer
	mov rsi, 0              ; read only
	mov rdx, 0
    syscall                 
	ret

_readFile:
	mov rax, 0              ; Para leer el documento
	mov rdi, rsi             
	mov rsi, buffer         ; Pointer a buffer
	mov rdx, 2050           ; Tamano
	syscall
	ret

;Contar cantidad de caracteres y que no sean más de 2048
count_chars:
	mov rax, buffer
	mov rcx, 0 ;Inicializar el contador de caracteres
	mov rdi, 0 ;Inicializar el contador de la posición del buffer
	
countLoop:
	cmp rcx, 2047 ;Compara si se llegó a 2048 bytes
	je char_final ;Si se llegó al caracter 2048, ver casos de último char

continue_loop:
    cmp byte [rax + rdi], 0 ;Verifica si se llegó al char null
    je endCount ;Terminar loop
    
    inc rdi ;Seguir al siguiente char
    inc rcx ;Incrementar contador
    jmp countLoop ;Seguir en el loop
     
char_final: ;Se llegó al último char
	cmp byte [rax + rdi + 1], 10 ;Verifica si el siguiente caracter es salto de linea
	je enter_char_especial
	jne error_tamano
	
enter_char_especial: ;Verificar si después del salto de línea ya se llegó al final del buffer
	cmp byte [rax + rdi + 2], 0 ;Verifica si el siguiente caracter es null
    je enter_final
    jne error_tamano

enter_char: ;Es un char de salto de línea
	cmp byte [rax + rdi + 1], 0 ;Verifica si el siguiente caracter es null
    je enter_final ;Hay 2048 caracteres
    jne error_tamano ;Hay más de 2048 caracteres 

enter_final:
	inc rdi ;Seguir al siguiente char
	inc rdi
    jmp continue_loop  ;Se llegó al char 2048
    
endCount:
	ret
	
error_tamano:
	; Mostrar mensaje de error
    mov rax, tamano_invalido
    call _genericprint                 

    ; Salir del programa con error
    jmp _finishCode

convert_upper_to_lower:
	movzx rax, byte [rsi]  ; carga la respuesta para ser convertida
			
	cmp al, 0              ; compara si esta vacia        
	je _conversionFinalizada
	
	cmp al, 'A'          
	jl _seguir_loop
	cmp al, 'Z'         
	jg _seguir_loop
	add al, 32
	jmp _guardaConversion

_seguir_loop:
	mov [rdi], al
	inc rsi
	inc rdi
	jmp convert_upper_to_lower

_guardaConversion:
	mov [rdi], al
	inc rsi
	inc rdi
	jmp convert_upper_to_lower

_conversionFinalizada:						   
	mov byte [rdi], 0      ; Cambia a null y termina
	ret

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
    
    cmp rcx, '-'            
    je .check_word
    
    cmp rcx, '?'            ; Comprobar si el byte es un signo de pregunta  
    je .check_word      
    
    cmp rcx, '!'            ; Comprobar si el byte es un signo de exclamacion  
    je .check_word  
    
    cmp rcx, 0xC2         
    je .check_second_byte

    ; Activar la bandera de palabra si el byte actual no es un espacio, salto de línea o signo de puntuación
    mov rbx, 1              ; Activar la bandera de palabra
    jmp .next_byte          ; Saltar al siguiente byte

.check_second_byte:
	mov r8, 1
    movzx rcx, byte [rdi + r8]  
    cmp rcx, 0xA1              
    je .check_word_signo
    cmp rcx, 0xBF              
    je .check_word_signo            
    
    jmp .not_word                   

.not_word:
	xor rbx, rbx
    jmp .next_byte             
            
.check_word_signo:
    cmp rbx, 0              ; Comprobar si la bandera de palabra está activada
    je .next_byte_signo           

    ; Incrementar el contador de palabras, desactivar la bandera de palabra
    inc rax                 ; Incrementar el contador de palabras
    xor rbx, rbx            ; Desactivar la bandera de palabra
    
.next_byte_signo:
    inc rdi                 ; Avanzar al siguiente byte en el buffer
    inc rdi
    movzx rcx, byte [rdi]   ; Cargar el siguiente byte del buffer en rcx
    jmp .loop               
    
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

