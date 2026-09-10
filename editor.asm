.model small
.stack 100h

SEG_VIDEO   equ 0B800h              ; segmento de la memoria de video en modo texto
COLOR_DEF   equ 07h                 ; color por defecto: gris sobre negro
COLOR_FONDO     equ 07h    ; negro, letras grises
COLOR_MARCO     equ 0Bh    ; negro, letras celestes
COLOR_OPCION    equ 07h    ; opción normal
COLOR_SELECCION equ 70h    ; fondo gris, letras negras

FLECHA_ARRIBA   equ 48h             ; scancodes para navegar y usar los atajos
FLECHA_ABAJO    equ 50h
FLECHA_IZQUIERDA equ 4Bh
FLECHA_DERECHA  equ 4Dh
TECLA_ENTER     equ 1Ch
TECLA_ESCAPE    equ 01h
TECLA_BACKSPACE equ 0Eh
ALT_X           equ 2Dh
ALT_Z           equ 2Ch
ALT_C           equ 2Eh
ALT_U           equ 16h
ALT_D           equ 20h
ALT_S           equ 1Fh
ALT_M           equ 32h
ALT_N           equ 31h
ALT_I           equ 17h
ALT_J           equ 24h
ALT_B           equ 30h
ALT_H           equ 23h

.data

buf_texto   db 2000 dup(' ')        ; un caracter del documento por cada celda
buf_color   db 2000 dup(COLOR_DEF)  ; un atributo de color por cada celda

opcion_menu     db 0                    ; guarda la opcion actual del menu
linea_superior  db '+------------------------------------------+$'
linea_titulo    db '|          EDITOR DE TEXTO x8086          |$'
texto_opcion1   db '  1. Crear archivo nuevo  $'
texto_opcion2   db '  2. Abrir archivo existente$'
texto_opcion3   db '  3. Salir                $'
texto_ayuda     db 'Use flechas y Enter. Alt+X para salir.$'
texto_edicion   db 'Pantalla de edicion pendiente.$'
texto_regresar  db 'Presione una tecla para regresar al menu.$'


.code

inicio:
    ; conecta DS con el segmento de datos del programa
    mov ax, @data
    mov ds, ax

    ; muestra el menu hasta que el usuario seleccione salir
    call menu_principal

    ; salida limpia a DOS
    mov ax, 4C00h
    int 21h

; lee una tecla y devuelve ASCII en AL y su scancode en AH
leer_tecla proc
    mov ah, 00h
    int 16h
    ret
leer_tecla endp

; pinta el marco, titulo y las opciones del menu principal
dibujar_menu proc
    push bx
    push dx
    push si

    ; limpia la pantalla antes de escribir los elementos del menu
    mov bl, COLOR_FONDO
    call limpiar_pantalla

    ; dibuja el marco sencillo y el titulo del programa
    mov dh, 4
    mov dl, 18
    mov bl, COLOR_MARCO
    lea si, linea_superior
    call escribir_texto

    mov dh, 5
    mov dl, 18
    lea si, linea_titulo
    call escribir_texto

    mov dh, 6
    mov dl, 18
    lea si, linea_superior
    call escribir_texto

    ; dibuja las opciones y deja visible la forma de navegar
    call dibujar_opciones
    mov dh, 15
    mov dl, 20
    mov bl, COLOR_MARCO
    lea si, texto_ayuda
    call escribir_texto

    pop si
    pop dx
    pop bx
    ret
dibujar_menu endp

; escribe las tres opciones y resalta la que esta guardada en opcion_menu
dibujar_opciones proc
    push bx
    push dx
    push si

    ; selecciona el color de la primera opcion
    mov bl, COLOR_OPCION
    cmp opcion_menu, 0
    jne revisar_opcion2
    mov bl, COLOR_SELECCION

revisar_opcion2:
    mov dh, 8
    mov dl, 26
    lea si, texto_opcion1
    call escribir_texto

    ; selecciona el color de la segunda opcion
    mov bl, COLOR_OPCION
    cmp opcion_menu, 1
    jne revisar_opcion3
    mov bl, COLOR_SELECCION

revisar_opcion3:
    mov dh, 10
    mov dl, 26
    lea si, texto_opcion2
    call escribir_texto

    ; selecciona el color de la tercera opcion
    mov bl, COLOR_OPCION
    cmp opcion_menu, 2
    jne fin_opciones
    mov bl, COLOR_SELECCION

fin_opciones:
    mov dh, 12
    mov dl, 26
    lea si, texto_opcion3
    call escribir_texto

    pop si
    pop dx
    pop bx
    ret
dibujar_opciones endp

; espera flechas o Enter y ejecuta la opcion elegida del menu
menu_principal proc
    mov opcion_menu, 0
    call dibujar_menu

esperar_menu:
    call leer_tecla

    ; las teclas con Alt y las flechas llegan con AL igual a cero
    cmp al, 0
    jne revisar_enter

    cmp ah, ALT_X
    je salir_menu

    cmp ah, FLECHA_ARRIBA
    je mover_arriba

    cmp ah, FLECHA_ABAJO
    je mover_abajo

    jmp esperar_menu

revisar_enter:
    cmp al, 0Dh
    jne esperar_menu

    ; las primeras dos opciones solo muestran la pantalla temporal de edicion
    cmp opcion_menu, 2
    je salir_menu

    call pantalla_edicion
    call dibujar_menu
    jmp esperar_menu

mover_arriba:
    cmp opcion_menu, 0
    je esperar_menu
    dec opcion_menu
    call dibujar_opciones
    jmp esperar_menu

mover_abajo:
    cmp opcion_menu, 2
    je esperar_menu
    inc opcion_menu
    call dibujar_opciones
    jmp esperar_menu

salir_menu:
    ret
menu_principal endp

; limpia la pantalla y espera una tecla antes de regresar al menu
pantalla_edicion proc
    push bx
    push dx
    push si

    ; muestra una pantalla temporal hasta implementar la edicion real
    mov bl, COLOR_FONDO
    call limpiar_pantalla
    mov dh, 10
    mov dl, 25
    mov bl, COLOR_MARCO
    lea si, texto_edicion
    call escribir_texto

    mov dh, 12
    mov dl, 18
    lea si, texto_regresar
    call escribir_texto
    call leer_tecla

    pop si
    pop dx
    pop bx
    ret
pantalla_edicion endp

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