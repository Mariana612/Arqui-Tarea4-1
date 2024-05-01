section .data
    filename db 'input.txt', 0
    error_message db 'Failed to open file.', 0xa, 0
    tamano_invalido db 'El archivo contiene más de 2048 caracteres', 0xa, 0
    digitos db '0123456789ABCDEF'  
    printCont dq 0
    newline_message db 0xa, 0 ; Mensaje de nueva línea
    word_message db 0xa, 'Word count: ', 0xa
    espacio db 10
	array_len equ 2050
	space db ' ', 0
	array_size equ 2050          ; Tamaño máximo del array
    array_times times array_size db 0


    

section .bss 
    buffer resb 2050
    nuevo_buffer resb 2050
    palabra1 resb 2050
    palabra2 resb 2050
    

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
    
	mov esi, nuevo_buffer
    mov edi, array_times
    call extract_words

    ;mov rdi, array_times
    ;call print_array
    
    ;Imprimir un espacio
    mov rax, 1          
    mov rdi, 1          
    mov rsi, espacio    
    mov rdx, 1          
    syscall
    
    dec r13
    call sort_words
    
    ;mov rax, palabra1	; Mostrar el recuento de palabras	
    ;call _genericprint
    
    ;mov rax, palabra2	; Mostrar el recuento de palabras	
    ;call _genericprint
    
    ;mov rdi, array_times
    ;call print_array
    
    
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


;Contador de palabras
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
	mov r13, rax
    ret                     ; Terminar la función
     
     
extract_words:
    ;   ESI: Puntero al buffer de entrada
    ;   EDI: Puntero al array de salida

    xor ecx, ecx  ; Contador de palabras
    xor eax, eax  ; Registro para mantener temporalmente caracteres
    .loop:
        mov al, byte [esi]  ; Lee el siguiente byte del buffer

        test al, al
        jz .done

        ; Verifica si el carácter es un espacio o un terminador de palabra
        cmp al, ' '
        je .next_word
        
        cmp al, '.'
        je .next_word
        
        cmp al, ','
        je .next_word
     
        cmp al, 10
        je .next_word

		cmp al, '?'
        je .next_word
        
        cmp al, '!'
        je .next_word
        
        cmp al, 0xC2
        je .check_unicode

        ; Guarda el carácter en el array de salida y avanza el puntero
        mov [edi], al
        inc edi
		
        jmp .continue
	
	.check_unicode:
        mov al, byte [esi + 1]
        cmp al, 0xBF ; Comprueba si es un carácter ¿
        je .skip_unicode
        
        cmp al, 0xA1 ; Comprueba si es un carácter ¡
        je .skip_unicode
        
        ; No es un carácter especial, avanza un byte
        inc esi
        jmp .next_word
        
     .skip_unicode:
        ; Es un carácter especial, avanza dos bytes
        inc esi
        jmp .next_word

    .next_word:
		mov byte [edi], " "  ; Agrega un carácter nulo al final de la palabra
        inc edi            ; Avanza el puntero al siguiente espacio en el array para la próxima palabra
        
        ; Verifica si ya hemos guardado una palabra
        cmp ecx, 2050 ; Cantidad max de palabras a extraer
        jge .done

		
        inc ecx            ; Incrementa el contador de palabras

    .continue:
        inc esi 
        jmp .loop

    .done:
        ret



print_array:
    mov rdx, array_size         ; Configura rdx como la longitud máxima del array
    mov rsi, array_times        ; Configura rsi como el puntero al array

print_loop:
    cmp byte [rsi], 0
    je exit_print_loop         ; Si es así, salta a la etiqueta exit_print_loop

    movzx eax, byte [rsi]      
    mov edi, 1
    mov edx, 1              
    mov eax, 1             
    syscall                  
    

    inc rsi                    ; Avanza al siguiente byte en el array
    jmp print_loop             ; Repite hasta que se haya impreso todo el contenido del array

exit_print_loop:
    ret                        

;Ordenar palabras alfabéticamente
sort_words:
    mov rdx, r13 ;Contador de comparaciones que se deben hacer

    mov rsi, array_times     ;Colocar rsi al inicio del array
    mov rdi, array_times     ;Colocar rdi al inicio del array
    mov r8, 4 ;Cantidad de espacios para seguir con la siguiente palabra
    mov r9, 0
    
_inner_loop:
	mov r12, r9
	mov r15, r8
	call guardar_palabras
    ; Comparar la primera letra de la primera palabra con la primera letra de la segunda palabra
    mov al, [rsi + r9]      ;Load la primera letra de la palabra actual a un registro
    mov bl, [rdi + r8]  ;Load la primera letra de la siguiente palabra a un registro
    xor rax, rax
    call compare_words         ; Comparar las letras
    cmp rax, 2
    je _not_swap       ; Jump si no se necesita hacer un swap
    cmp rax, 1
    je _continue_swap
    ;Swap las palabras
    ;call swap_palabras
    
    mov r9, r8
    
    inc r8
    inc r8
    inc r8
    
    ret
    jmp _continue_swap
    
_not_swap:
    mov r9, r8
    inc r8
    inc r8
    inc r8
    
_continue_swap:
    dec rdx
    jnz _inner_loop
    ret

;-------------------------------------Compare--------------------------

compare_words:
	
    mov rdi, test1    ; Load address of first word into rdi
    mov rsi, test2    ; Load address of second word into rsi
    
    call compare_loop     ; Call the comparison function
    

compare_loop:

    mov al, byte [rdi]  
    mov bl, byte [rsi]

    
    cmp al, bl          
    jne compare_result   
    
    
    inc rdi              
    inc rsi          
 
    
    cmp al, " "
    jne compare_loop
    je equal
    
compare_result:
    cmp al, bl          
    jb first_word_comes 
     
    mov rax, 1  

       
    ret

first_word_comes:
    mov rax, 2  
    
      
    ret
 
    
equal:
	cmp bl, " "
	je equals2
	mov rax, 1
	
	
	ret
equals2:
    mov rax, 3  
        
    ret



;----------------------------------------------------------------------

guardar_palabras:
	mov rcx, palabra1
    mov r11, palabra2
	mov r10, 0
	call limpiar_palabra2
	call limpiar_palabra1
	
cont_guardar:
	mov bl, [rdi + r15]
	mov [r11 + r10], bl
	inc r15
	inc r10
	
	cmp byte [rdi + r15], 10
	je agregar_siguiente_palabra
	
	jmp cont_guardar
	
agregar_siguiente_palabra:
	mov r10, 0
	
loop_siguiente_palabra:
	mov al, [rsi + r12]
	mov [rcx + r10], al
	inc r12
	inc r10
	
	cmp byte [rsi + r12], 10
	je fin_palabras
	
	jmp loop_siguiente_palabra

fin_palabras:
	ret

;Limpiar palabra 1
limpiar_palabra1:
	push rdi
	push rcx
	push rax
	mov rdi, palabra1   ; Set the destination index to palabra1
    mov rcx, 2050      ; Set the loop counter to the size of palabra1
    xor al, al         ; Set AL to zero
    rep stosb          ; Store zero bytes in palabra1
    pop rax
    pop rcx
    pop rdi
    
	ret

;Limpiar palabra 2	
limpiar_palabra2:
	push rdi
	push rcx
	push rax
	mov rdi, palabra2   ; Set the destination index to palabra1
    mov rcx, 2050      ; Set the loop counter to the size of palabra1
    xor al, al         ; Set AL to zero
    rep stosb          ; Store zero bytes in palabra1
    pop rax
    pop rcx
    pop rdi
    
	ret

swap_palabras:
	mov r10, r9

get_word_length:


;ITOA  
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

