.model small
.stack 100h

SEG_VIDEO   equ 0B800h              ; segmento de la memoria de video en modo texto
COLOR_DEF   equ 07h                 ; color por defecto: gris sobre negro

.data

buf_texto   db 2000 dup(' ')        ; un caracter del documento por cada celda
buf_color   db 2000 dup(COLOR_DEF)  ; un atributo de color por cada celda

msg_hola    db 'Hola$'

.code

inicio:
    ; conecta DS con el segmento de datos del programa
    mov ax, @data
    mov ds, ax

    ; limpia la pantalla con el color por defecto
    mov bl, COLOR_DEF
    call limpiar_pantalla

    ; escribe la palabra Hola en la fila 0 y la columna 0
    mov dh, 0
    mov dl, 0
    mov bl, COLOR_DEF
    lea si, msg_hola
    call escribir_texto

    ; espera a que el usuario presione una tecla
    mov ah, 00h
    int 16h

    ; salida limpia a DOS
    mov ax, 4C00h
    int 21h

; llena las 2000 celdas de la pantalla con espacios y el color que viene en BL
limpiar_pantalla proc
    push ax
    push cx
    push di
    push es

    ; apunta a la memoria de video y arma la celda de espacio con su color
    mov ax, SEG_VIDEO
    mov es, ax
    mov di, 0
    mov cx, 2000
    mov al, ' '
    mov ah, bl

limpiar_ciclo:
    ; escribe la celda y avanza a la siguiente
    mov es:[di], ax
    add di, 2
    loop limpiar_ciclo

    pop es
    pop di
    pop cx
    pop ax
    ret
limpiar_pantalla endp

; mueve el cursor a la fila DH y la columna DL
poner_cursor proc
    push ax
    push bx

    mov ah, 02h
    mov bh, 0
    int 10h

    pop bx
    pop ax
    ret
poner_cursor endp

; escribe el caracter de AL con el color de BL en la fila DH y la columna DL
escribir_char proc
    push ax
    push bx
    push dx
    push di
    push es

    ; arma la palabra caracter mas color y la guarda mientras se calcula la posicion
    mov ah, bl
    push ax

    ; calcula el desplazamiento en video: (fila * 80 + columna) * 2
    mov al, dh
    mov bl, 80
    mul bl
    mov bx, 0
    mov bl, dl
    add ax, bx
    add ax, ax
    mov di, ax

    ; recupera la palabra y la escribe en la celda de video
    pop ax
    mov bx, SEG_VIDEO
    mov es, bx
    mov es:[di], ax

    pop es
    pop di
    pop dx
    pop bx
    pop ax
    ret
escribir_char endp

; imprime la cadena de DS:SI terminada en $ desde la fila DH y la columna DL con el color BL
escribir_texto proc
    push ax
    push dx
    push si

texto_ciclo:
    ; toma el siguiente caracter y termina si encuentra el signo de fin
    mov al, [si]
    cmp al, '$'
    je texto_fin

    ; dibuja el caracter y avanza una columna
    call escribir_char
    inc si
    inc dl
    jmp texto_ciclo

texto_fin:
    pop si
    pop dx
    pop ax
    ret
escribir_texto endp

; recorre los dos buffers y dibuja el documento completo en la pantalla
pintar_buffer proc
    push ax
    push cx
    push si
    push di
    push es

    ; apunta al inicio de los buffers y al inicio de la memoria de video
    mov ax, SEG_VIDEO
    mov es, ax
    mov si, 0
    mov di, 0
    mov cx, 2000

pintar_ciclo:
    ; copia el caracter y su color a la celda de video que le toca
    mov al, buf_texto[si]
    mov ah, buf_color[si]
    mov es:[di], ax
    inc si
    add di, 2
    loop pintar_ciclo

    pop es
    pop di
    pop si
    pop cx
    pop ax
    ret
pintar_buffer endp

end inicio
