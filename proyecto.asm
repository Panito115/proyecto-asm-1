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

FILA_ARCHIVO    equ 0               ; limites de las tres zonas de la pantalla
FILA_MIN        equ 1
FILA_MAX        equ 23
FILA_ESTADO     equ 24
COL_MIN         equ 0
COL_MAX         equ 79
COLOR_ESTADO    equ 70h             ; barra de estado: fondo gris, letras negras
ASCII_BACK      equ 08h             ; codigo ASCII de la tecla Backspace

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
fila_cur        db FILA_MIN             ; fila donde esta el cursor de edicion
col_cur         db COL_MIN              ; columna donde esta el cursor de edicion
texto_archivo   db 'Archivo: SIN NOMBRE$'
texto_fila      db 'Fila:$'
texto_columna   db 'Col:$'
texto_atajo     db 'Alt+H = ayuda$'


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

; dibuja la pantalla de edicion y atiende las teclas hasta que se pida volver al menu
pantalla_edicion proc
    ; coloca el cursor al inicio del area de edicion y dibuja la pantalla
    mov fila_cur, FILA_MIN
    mov col_cur, COL_MIN
    call dibujar_edicion

ciclo_edicion:
    ; refresca la barra de estado, coloca el cursor y espera una tecla
    call dibujar_estado
    mov dh, fila_cur
    mov dl, col_cur
    call poner_cursor
    call leer_tecla

    ; las flechas y los atajos con Alt llegan con AL igual a cero
    cmp al, 0
    je tecla_especial

    ; Backspace borra y los demas caracteres se filtran antes de escribirlos
    cmp al, ASCII_BACK
    je tecla_borrar
    call es_valido
    cmp bh, 1
    je tecla_normal
    jmp ciclo_edicion

tecla_normal:
    call escribir_en_buffer
    call avanzar_cursor
    jmp ciclo_edicion

tecla_borrar:
    call borrar_char
    jmp ciclo_edicion

tecla_especial:
    ; Alt+Z regresa al menu principal y las flechas mueven el cursor
    cmp ah, ALT_Z
    je fin_edicion
    cmp ah, FLECHA_ARRIBA
    je subir_fila
    cmp ah, FLECHA_ABAJO
    je bajar_fila
    cmp ah, FLECHA_IZQUIERDA
    je mover_izquierda
    cmp ah, FLECHA_DERECHA
    je mover_derecha
    jmp ciclo_edicion

subir_fila:
    ; cada flecha se detiene en el borde del area de edicion
    cmp fila_cur, FILA_MIN
    jbe fin_subir
    dec fila_cur
fin_subir:
    jmp ciclo_edicion

bajar_fila:
    cmp fila_cur, FILA_MAX
    jae fin_bajar
    inc fila_cur
fin_bajar:
    jmp ciclo_edicion

mover_izquierda:
    cmp col_cur, COL_MIN
    jbe fin_izquierda
    dec col_cur
fin_izquierda:
    jmp ciclo_edicion

mover_derecha:
    cmp col_cur, COL_MAX
    jae fin_derecha
    inc col_cur
fin_derecha:
    jmp ciclo_edicion

fin_edicion:
    ret
pantalla_edicion endp

; dibuja el nombre del archivo, el documento y la barra de estado
dibujar_edicion proc
    push bx
    push dx
    push si

    ; limpia la pantalla y pinta el contenido del documento
    mov bl, COLOR_FONDO
    call limpiar_pantalla
    call pintar_buffer

    ; escribe el nombre del archivo en la fila reservada de arriba
    mov dh, FILA_ARCHIVO
    mov dl, 1
    mov bl, COLOR_MARCO
    lea si, texto_archivo
    call escribir_texto
    call dibujar_estado

    pop si
    pop dx
    pop bx
    ret
dibujar_edicion endp

; pinta la barra de estado con la fila y la columna donde esta el cursor
dibujar_estado proc
    push ax
    push bx
    push cx
    push dx
    push si

    ; pinta las 80 columnas de la ultima fila con el color de la barra
    mov cx, 80
    mov dh, FILA_ESTADO
    mov dl, COL_MIN
    mov al, ' '
    mov bl, COLOR_ESTADO

estado_ciclo:
    call escribir_char
    inc dl
    loop estado_ciclo

    ; escribe la fila actual del cursor
    mov dl, 1
    lea si, texto_fila
    call escribir_texto
    mov dl, 7
    mov al, fila_cur
    call mostrar_numero

    ; escribe la columna actual del cursor
    mov dl, 11
    lea si, texto_columna
    call escribir_texto
    mov dl, 16
    mov al, col_cur
    call mostrar_numero

    ; recuerda el atajo de la ayuda
    mov dl, 60
    lea si, texto_atajo
    call escribir_texto

    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret
dibujar_estado endp

; escribe el numero de AL en dos digitos, en la fila DH y la columna DL con el color BL
mostrar_numero proc
    push ax
    push bx
    push dx

    ; separa las decenas de las unidades y las vuelve caracteres
    mov ah, 0
    mov bh, 10
    div bh
    add al, '0'
    add ah, '0'

    ; dibuja primero las decenas y luego las unidades
    call escribir_char
    inc dl
    mov al, ah
    call escribir_char

    pop dx
    pop bx
    pop ax
    ret
mostrar_numero endp

; revisa el caracter de AL y devuelve BH en 1 cuando se puede escribir
es_valido proc
    ; los cuatro signos permitidos se revisan uno por uno
    mov bh, 1
    cmp al, ' '
    je valido_fin
    cmp al, ','
    je valido_fin
    cmp al, '.'
    je valido_fin
    cmp al, ':'
    je valido_fin

    ; los numeros y las letras se revisan por rangos
    cmp al, '0'
    jb valido_no
    cmp al, '9'
    jbe valido_fin
    cmp al, 'A'
    jb valido_no
    cmp al, 'Z'
    jbe valido_fin
    cmp al, 'a'
    jb valido_no
    cmp al, 'z'
    jbe valido_fin

valido_no:
    mov bh, 0

valido_fin:
    ret
es_valido endp

; guarda el caracter de AL en la posicion del cursor y lo dibuja en la pantalla
escribir_en_buffer proc
    push ax
    push bx
    push dx

    ; calcula la posicion dentro del buffer: fila * 80 + columna
    push ax
    mov al, fila_cur
    mov bl, 80
    mul bl
    mov bx, 0
    mov bl, col_cur
    add bx, ax
    pop ax

    ; guarda el caracter con su color y lo dibuja en la pantalla
    mov buf_texto[bx], al
    mov buf_color[bx], COLOR_DEF
    mov dh, fila_cur
    mov dl, col_cur
    mov bl, COLOR_DEF
    call escribir_char

    pop dx
    pop bx
    pop ax
    ret
escribir_en_buffer endp

; mueve el cursor una columna a la derecha y baja de fila al pasar la ultima columna
avanzar_cursor proc
    ; mientras no sea la ultima columna solo avanza a la derecha
    cmp col_cur, COL_MAX
    jb avanzar_columna

    ; al pasar la ultima columna regresa al inicio de la fila de abajo
    mov col_cur, COL_MIN
    cmp fila_cur, FILA_MAX
    jae avanzar_fin
    inc fila_cur
    jmp avanzar_fin

avanzar_columna:
    inc col_cur

avanzar_fin:
    ret
avanzar_cursor endp

; borra el caracter que esta antes del cursor y deja el cursor en ese lugar
borrar_char proc
    push ax

    ; retrocede una columna, o sube al final de la fila anterior
    cmp col_cur, COL_MIN
    ja borrar_izquierda
    cmp fila_cur, FILA_MIN
    jbe borrar_fin
    dec fila_cur
    mov col_cur, COL_MAX
    jmp borrar_espacio

borrar_izquierda:
    dec col_cur

borrar_espacio:
    ; deja un espacio en el buffer y en la pantalla
    mov al, ' '
    call escribir_en_buffer

borrar_fin:
    pop ax
    ret
borrar_char endp

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