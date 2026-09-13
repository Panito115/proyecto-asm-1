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
MAX_NOMBRE      equ 8               ; cantidad maxima de letras para un archivo
MAX_IMAGENES    equ 20              ; cantidad maxima de imagenes en la tabla

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
texto_archivo   db 'Archivo: $'
texto_sin_nombre db 'SIN NOMBRE$'
texto_fila      db 'Fila:$'
texto_columna   db 'Col:$'
texto_atajo     db 'Alt+H = ayuda$'
texto_color     db 'Color:$'

colores_letra   db 0Fh, 0Ah, 0Eh ; blanco, verde y amarillo
colores_fondo   db 00h, 10h, 40h  ; negro, azul y rojo
indice_letra    db 0 ; color de letra seleccionado
indice_fondo    db 0  ; color de fondo seleccionado
color_activo    db 0Fh ; atributo para los caracteres nuevos

linea_ayuda     db '+------------------------------------------------------------------------------+$'
titulo_ayuda    db '|                             AYUDA DEL EDITOR                              |$'
ayuda_flechas   db 'Flechas: mueven el cursor.$'
ayuda_borrar    db 'Backspace: borra el caracter anterior.$'
ayuda_centrar   db 'Alt+C: centra el cursor en la linea actual.$'
ayuda_arriba    db 'Alt+U: mueve el cursor a la primera fila.$'
ayuda_abajo     db 'Alt+D: mueve el cursor a la ultima fila.$'
ayuda_letra     db 'Alt+M: cambia el color de letra nuevo.$'
ayuda_fondo     db 'Alt+N: cambia el color de fondo nuevo.$'
ayuda_ayuda     db 'Alt+H: muestra esta pantalla de ayuda.$'
ayuda_volver    db 'Alt+Z: regresa al menu.$'
ayuda_salir     db 'Presione cualquier tecla para volver.$'

nombre_archivo  db 8 dup(0) ; nombre sin extension para mostrar
nombre_dos      db 13 dup(0) ; nombre con .TXE y cero final
largo_nombre    db 0  ; caracteres escritos para el nombre

linea_crear     db '+----------------------------------------------+$'
titulo_crear    db '|                CREAR ARCHIVO                |$'
texto_nombre    db 'Nombre (maximo 8): $'
texto_extension db 'Extension: .TXE$'
texto_crear_ayuda db 'Enter confirma. Alt+Z regresa.$'
texto_error     db 'No se pudo crear el archivo.$'
texto_txe       db '.TXE$'
titulo_abrir    db '|                ABRIR ARCHIVO                 |$'
texto_error_abrir db 'No se pudo abrir el archivo.$'
texto_error_guardar db 'No se pudo guardar.$'
tabla_imagenes  db 60 dup(0) ; 20 imagenes de 3 bytes: numero, fila y columna
imagen_carita   db 00h, 0Eh, 0Eh, 0Eh, 00h ; imagen 1 de 5x5: amarillo 0Eh y negro 00h
                db 0Eh, 00h, 0Eh, 00h, 0Eh
                db 0Eh, 0Eh, 0Eh, 0Eh, 0Eh
                db 0Eh, 00h, 00h, 00h, 0Eh
                db 00h, 0Eh, 0Eh, 0Eh, 00h
imagen_corazon  db 00h, 0Ch, 00h, 0Ch, 00h ; imagen 2 de 5x5: rojo 0Ch y negro 00h
                db 0Ch, 0Ch, 0Ch, 0Ch, 0Ch
                db 0Ch, 0Ch, 0Ch, 0Ch, 0Ch
                db 00h, 0Ch, 0Ch, 0Ch, 00h
                db 00h, 00h, 0Ch, 00h, 00h


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

    ; salir termina, y crear o abrir piden un nombre antes de entrar al editor
    cmp opcion_menu, 2
    je salir_menu

    cmp opcion_menu, 0
    je crear_nuevo

    call abrir_archivo
    call dibujar_menu
    jmp esperar_menu

crear_nuevo:
    call crear_archivo
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
    ; repinta las imagenes encima del texto, refresca la barra de estado y espera una tecla
    call pintar_imagenes
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
    ; Alt+Z, Alt+S, Alt+I y Alt+J usan jne con jmp porque sus destinos quedan lejos para un salto condicional
    cmp ah, ALT_Z
    jne revisar_guardar
    jmp fin_edicion

revisar_guardar:
    cmp ah, ALT_S
    jne revisar_imagen1
    jmp guardar_salir

revisar_imagen1:
    cmp ah, ALT_I
    jne revisar_imagen2
    jmp poner_imagen1

revisar_imagen2:
    cmp ah, ALT_J
    jne revisar_arriba
    jmp poner_imagen2

revisar_arriba:
    ; las flechas mueven el cursor y los demas atajos llaman a su rutina
    cmp ah, FLECHA_ARRIBA
    je subir_fila
    cmp ah, FLECHA_ABAJO
    je bajar_fila
    cmp ah, FLECHA_IZQUIERDA
    je mover_izquierda
    cmp ah, FLECHA_DERECHA
    je mover_derecha
    cmp ah, ALT_C
    je centrar_linea
    cmp ah, ALT_U
    je ir_arriba
    cmp ah, ALT_D
    je ir_abajo
    cmp ah, ALT_M
    je cambiar_letra
    cmp ah, ALT_N
    je cambiar_fondo
    cmp ah, ALT_H
    je mostrar_ayuda
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

centrar_linea:
    call centrar_cursor
    jmp ciclo_edicion

ir_arriba:
    mov fila_cur, FILA_MIN
    jmp ciclo_edicion

ir_abajo:
    mov fila_cur, FILA_MAX
    jmp ciclo_edicion

cambiar_letra:
    inc indice_letra
    cmp indice_letra, 3
    jb letra_lista
    mov indice_letra, 0
letra_lista:
    call actualizar_color
    jmp ciclo_edicion

cambiar_fondo:
    inc indice_fondo
    cmp indice_fondo, 3
    jb fondo_lista
    mov indice_fondo, 0
fondo_lista:
    call actualizar_color
    jmp ciclo_edicion

mostrar_ayuda:
    call pantalla_ayuda
    jmp ciclo_edicion

guardar_salir:
    ; guarda el documento y termina el programa si no hubo error
    call guardar_en_disco
    jc error_guardar
    mov ax, 4C00h
    int 21h

error_guardar:
    ; avisa en la barra de estado y sigue en la edicion
    mov dh, FILA_ESTADO
    mov dl, 32
    mov bl, COLOR_ESTADO
    lea si, texto_error_guardar
    call escribir_texto
    call leer_tecla
    jmp ciclo_edicion

poner_imagen1:
    ; anota la carita en la tabla; el ciclo la dibuja al volver
    mov al, 1
    call insertar_imagen
    jmp ciclo_edicion

poner_imagen2:
    ; anota el corazon en la tabla; el ciclo lo dibuja al volver
    mov al, 2
    call insertar_imagen
    jmp ciclo_edicion

fin_edicion:
    ret
pantalla_edicion endp

; dibuja el nombre del archivo, el documento y la barra de estado
dibujar_edicion proc
    push bx
    push dx
    push si

    ; limpia la pantalla y pinta el documento con las imagenes encima
    mov bl, COLOR_FONDO
    call limpiar_pantalla
    call pintar_buffer
    call pintar_imagenes

    ; escribe el nombre del archivo en la fila reservada de arriba
    mov dh, FILA_ARCHIVO
    mov dl, 1
    mov bl, COLOR_MARCO
    lea si, texto_archivo
    call escribir_texto
    mov dl, 10
    cmp largo_nombre, 0
    jne mostrar_nombre_archivo
    lea si, texto_sin_nombre
    call escribir_texto
    jmp archivo_listo

mostrar_nombre_archivo:
    call escribir_nombre
    lea si, texto_txe
    call escribir_texto

archivo_listo:
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

    ; muestra una letra de ejemplo con el color de letra y fondo que se usara al escribir
    mov dl, 21
    lea si, texto_color
    call escribir_texto
    mov dl, 28
    mov al, 'A'
    mov bl, color_activo
    call escribir_char

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
    mov bl, color_activo
    mov buf_color[bx], bl
    mov dh, fila_cur
    mov dl, col_cur
    mov bl, color_activo
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

; combina el color de letra y fondo que estan seleccionados
actualizar_color proc
    push ax
    push bx

    ; el fondo ya usa la parte alta y la letra la parte baja del atributo
    mov bl, indice_letra
    mov bh, 0
    mov al, colores_letra[bx]
    mov bl, indice_fondo
    mov bh, 0
    add al, colores_fondo[bx]
    mov color_activo, al

    pop bx
    pop ax
    ret
actualizar_color endp

; busca el final del texto de la fila y mueve el cursor a su mitad
centrar_cursor proc
    push ax
    push bx
    push cx
    push si
    push di

    ; calcula la primera posicion del buffer para la fila actual
    mov al, fila_cur
    mov bl, 80
    mul bl
    mov si, ax
    mov cx, 80
    mov di, 0
    mov bx, 0FFFFh

buscar_texto:
    mov al, buf_texto[si]
    cmp al, ' '
    je seguir_texto
    mov bx, di

seguir_texto:
    inc si
    inc di
    loop buscar_texto

    ; si toda la fila tiene espacios, deja el cursor en la columna 40
    cmp bx, 0FFFFh
    jne texto_encontrado
    mov col_cur, 40
    jmp centrar_fin

texto_encontrado:
    ; la mitad se calcula desde la columna cero hasta el ultimo caracter
    mov ax, bx
    inc ax
    mov cl, 2
    div cl
    mov col_cur, al

centrar_fin:
    pop di
    pop si
    pop cx
    pop bx
    pop ax
    ret
centrar_cursor endp

; muestra los atajos y redibuja el documento al regresar
pantalla_ayuda proc
    push bx
    push dx
    push si

    ; limpia la pantalla y dibuja un marco sencillo para la ayuda
    mov bl, COLOR_FONDO
    call limpiar_pantalla
    mov dh, 2
    mov dl, 0
    mov bl, COLOR_MARCO
    lea si, linea_ayuda
    call escribir_texto
    mov dh, 3
    lea si, titulo_ayuda
    call escribir_texto
    mov dh, 4
    lea si, linea_ayuda
    call escribir_texto

    ; escribe cada atajo en una fila distinta
    mov dh, 6
    mov dl, 5
    mov bl, COLOR_DEF
    lea si, ayuda_flechas
    call escribir_texto
    mov dh, 7
    lea si, ayuda_borrar
    call escribir_texto
    mov dh, 8
    lea si, ayuda_centrar
    call escribir_texto
    mov dh, 9
    lea si, ayuda_arriba
    call escribir_texto
    mov dh, 10
    lea si, ayuda_abajo
    call escribir_texto
    mov dh, 11
    lea si, ayuda_letra
    call escribir_texto
    mov dh, 12
    lea si, ayuda_fondo
    call escribir_texto
    mov dh, 13
    lea si, ayuda_ayuda
    call escribir_texto
    mov dh, 14
    lea si, ayuda_volver
    call escribir_texto
    mov dh, 16
    mov dl, 20
    mov bl, COLOR_MARCO
    lea si, ayuda_salir
    call escribir_texto

    ; espera una tecla y recupera el documento con sus atributos guardados
    call leer_tecla
    call dibujar_edicion

    pop si
    pop dx
    pop bx
    ret
pantalla_ayuda endp

; pide un nombre, crea el archivo y entra al editor vacio
crear_archivo proc
pedir_nombre:
    mov largo_nombre, 0
    call dibujar_crear
    call leer_nombre
    cmp al, 0
    je crear_fin

    call armar_nombre_dos
    call crear_en_disco
    jc error_crear
    call vaciar_buffer
    call pantalla_edicion

crear_fin:
    ret

error_crear:
    call mostrar_error
    jmp pedir_nombre
crear_archivo endp

; dibuja la pantalla donde se pide el nombre del archivo
dibujar_crear proc
    push bx
    push dx
    push si

    mov bl, COLOR_FONDO
    call limpiar_pantalla
    mov dh, 5
    mov dl, 16
    mov bl, COLOR_MARCO
    lea si, linea_crear
    call escribir_texto
    mov dh, 6
    lea si, titulo_crear
    call escribir_texto
    mov dh, 7
    lea si, linea_crear
    call escribir_texto

    mov dh, 10
    mov dl, 20
    mov bl, COLOR_DEF
    lea si, texto_nombre
    call escribir_texto
    mov dh, 12
    lea si, texto_extension
    call escribir_texto
    mov dh, 15
    mov dl, 20
    mov bl, COLOR_MARCO
    lea si, texto_crear_ayuda
    call escribir_texto

    pop si
    pop dx
    pop bx
    ret
dibujar_crear endp

; lee hasta ocho letras o numeros para el nombre del archivo
leer_nombre proc
    push bx
    push dx

leer_nombre_ciclo:
    call leer_tecla
    cmp al, 0
    jne revisar_nombre_normal
    cmp ah, ALT_Z
    jne leer_nombre_ciclo
    mov al, 0
    jmp leer_nombre_fin

revisar_nombre_normal:
    cmp al, 0Dh
    je confirmar_nombre
    cmp al, ASCII_BACK
    je borrar_nombre
    call es_nombre_valido
    cmp bh, 1
    jne leer_nombre_ciclo
    cmp largo_nombre, MAX_NOMBRE
    jae leer_nombre_ciclo

    call convertir_mayuscula
    mov bl, largo_nombre
    mov bh, 0
    mov nombre_archivo[bx], al
    mov dh, 10
    mov dl, 39
    add dl, largo_nombre
    mov bl, COLOR_DEF
    call escribir_char
    inc largo_nombre
    jmp leer_nombre_ciclo

confirmar_nombre:
    cmp largo_nombre, 0
    je leer_nombre_ciclo
    mov al, 1
    jmp leer_nombre_fin

borrar_nombre:
    cmp largo_nombre, 0
    je leer_nombre_ciclo
    dec largo_nombre
    mov bl, largo_nombre
    mov bh, 0
    mov nombre_archivo[bx], 0
    mov dh, 10
    mov dl, 39
    add dl, largo_nombre
    mov al, ' '
    mov bl, COLOR_DEF
    call escribir_char
    jmp leer_nombre_ciclo

leer_nombre_fin:
    pop dx
    pop bx
    ret
leer_nombre endp

; acepta solo letras y numeros y devuelve BH en uno cuando son validos
es_nombre_valido proc
    mov bh, 1
    cmp al, '0'
    jb nombre_no_valido
    cmp al, '9'
    jbe nombre_valido_fin
    cmp al, 'A'
    jb nombre_no_valido
    cmp al, 'Z'
    jbe nombre_valido_fin
    cmp al, 'a'
    jb nombre_no_valido
    cmp al, 'z'
    jbe nombre_valido_fin

nombre_no_valido:
    mov bh, 0

nombre_valido_fin:
    ret
es_nombre_valido endp

; convierte a mayuscula una letra minuscula que viene en AL
convertir_mayuscula proc
    cmp al, 'a'
    jb mayuscula_fin
    cmp al, 'z'
    ja mayuscula_fin
    sub al, 20h

mayuscula_fin:
    ret
convertir_mayuscula endp

; arma el nombre para DOS agregando la extension y el cero final
armar_nombre_dos proc
    push ax
    push bx
    push cx

    mov bx, 0
    mov cl, largo_nombre
    mov ch, 0

copiar_nombre:
    cmp cx, 0
    je agregar_extension
    mov al, nombre_archivo[bx]
    mov nombre_dos[bx], al
    inc bx
    loop copiar_nombre

agregar_extension:
    mov byte ptr nombre_dos[bx], '.'
    inc bx
    mov byte ptr nombre_dos[bx], 'T'
    inc bx
    mov byte ptr nombre_dos[bx], 'X'
    inc bx
    mov byte ptr nombre_dos[bx], 'E'
    inc bx
    mov byte ptr nombre_dos[bx], 0

    pop cx
    pop bx
    pop ax
    ret
armar_nombre_dos endp

; crea el archivo en disco y lo cierra de inmediato
crear_en_disco proc
    mov cx, 0
    lea dx, nombre_dos
    mov ah, 3Ch
    int 21h
    jc crear_disco_fin

    mov bx, ax
    mov ah, 3Eh
    int 21h

crear_disco_fin:
    ret
crear_en_disco endp

; deja vacios los buffers de texto y color y la tabla de imagenes para el archivo nuevo
vaciar_buffer proc
    push ax
    push cx
    push si

    mov si, 0
    mov cx, 2000
    mov al, ' '
    mov ah, COLOR_DEF

vaciar_ciclo:
    mov buf_texto[si], al
    mov buf_color[si], ah
    inc si
    loop vaciar_ciclo

    ; borra tambien las imagenes colocadas, los 60 bytes de la tabla
    mov si, 0
    mov cx, 60

vaciar_tabla:
    mov tabla_imagenes[si], 0
    inc si
    loop vaciar_tabla

    pop si
    pop cx
    pop ax
    ret
vaciar_buffer endp

; muestra el error de DOS y espera una tecla antes de pedir otro nombre
mostrar_error proc
    push bx
    push dx
    push si

    mov dh, 17
    mov dl, 20
    mov bl, COLOR_SELECCION
    lea si, texto_error
    call escribir_texto
    call leer_tecla

    pop si
    pop dx
    pop bx
    ret
mostrar_error endp

; escribe el nombre actual con el color BL desde la columna DL y deja DL al final del nombre
escribir_nombre proc
    push ax
    push cx
    push si

    mov si, 0
    mov cl, largo_nombre
    mov ch, 0

nombre_ciclo:
    cmp cx, 0
    je nombre_fin
    mov al, nombre_archivo[si]
    call escribir_char
    inc si
    inc dl
    loop nombre_ciclo

nombre_fin:
    pop si
    pop cx
    pop ax
    ret
escribir_nombre endp

; Formato del archivo .TXE, 4060 bytes en total:
;   bytes    0 a 1999: buffer de caracteres, uno por cada celda de la pantalla
;   bytes 2000 a 3999: buffer de atributos de color, uno por cada celda
;   bytes 4000 a 4059: tabla de imagenes, 20 registros de 3 bytes (numero, fila y columna)
; abre el archivo en modo escritura, escribe las tres partes y lo cierra; CF en 1 si hubo error
guardar_en_disco proc
    push ax
    push bx
    push cx
    push dx

    ; abre el archivo que ya existe en modo escritura
    mov ah, 3Dh
    mov al, 1
    lea dx, nombre_dos
    int 21h
    jc guardar_disco_fin
    mov bx, ax

    ; escribe los caracteres, los colores y la tabla de imagenes en ese orden
    mov ah, 40h
    mov cx, 2000
    lea dx, buf_texto
    int 21h
    mov ah, 40h
    mov cx, 2000
    lea dx, buf_color
    int 21h
    mov ah, 40h
    mov cx, 60
    lea dx, tabla_imagenes
    int 21h

    ; cierra el archivo para que DOS termine de escribirlo
    mov ah, 3Eh
    int 21h

guardar_disco_fin:
    pop dx
    pop cx
    pop bx
    pop ax
    ret
guardar_en_disco endp

; pide un nombre, abre el archivo y entra al editor con su contenido
abrir_archivo proc
pedir_abrir:
    ; pide el nombre y regresa al menu si el usuario presiona Alt+Z
    mov largo_nombre, 0
    call dibujar_abrir
    call leer_nombre
    cmp al, 0
    je abrir_fin

    ; arma el nombre para DOS, lee el archivo y entra al editor
    call armar_nombre_dos
    call leer_de_disco
    jc error_abrir
    call pantalla_edicion

abrir_fin:
    ret

error_abrir:
    ; avisa que no se pudo abrir y vuelve a pedir otro nombre
    mov dh, 17
    mov dl, 20
    mov bl, COLOR_SELECCION
    lea si, texto_error_abrir
    call escribir_texto
    call leer_tecla
    jmp pedir_abrir
abrir_archivo endp

; dibuja la pantalla donde se pide el nombre del archivo que se va a abrir
dibujar_abrir proc
    push bx
    push dx
    push si

    ; limpia la pantalla y dibuja el marco con el titulo
    mov bl, COLOR_FONDO
    call limpiar_pantalla
    mov dh, 5
    mov dl, 16
    mov bl, COLOR_MARCO
    lea si, linea_crear
    call escribir_texto
    mov dh, 6
    lea si, titulo_abrir
    call escribir_texto
    mov dh, 7
    lea si, linea_crear
    call escribir_texto

    ; escribe el mensaje, la extension y las teclas que se pueden usar
    mov dh, 10
    mov dl, 20
    mov bl, COLOR_DEF
    lea si, texto_nombre
    call escribir_texto
    mov dh, 12
    lea si, texto_extension
    call escribir_texto
    mov dh, 15
    mov dl, 20
    mov bl, COLOR_MARCO
    lea si, texto_crear_ayuda
    call escribir_texto

    pop si
    pop dx
    pop bx
    ret
dibujar_abrir endp

; abre el archivo en modo lectura y copia su contenido a los buffers; CF en 1 si no se pudo abrir
leer_de_disco proc
    push ax
    push bx
    push cx
    push dx

    ; abre el archivo existente en modo lectura
    mov ah, 3Dh
    mov al, 0
    lea dx, nombre_dos
    int 21h
    jc leer_disco_fin
    mov bx, ax

    ; vacia los buffers por si el archivo se creo pero nunca se guardo
    call vaciar_buffer

    ; lee los caracteres, los colores y la tabla de imagenes en el mismo orden en que se guardaron
    mov ah, 3Fh
    mov cx, 2000
    lea dx, buf_texto
    int 21h
    mov ah, 3Fh
    mov cx, 2000
    lea dx, buf_color
    int 21h
    mov ah, 3Fh
    mov cx, 60
    lea dx, tabla_imagenes
    int 21h

    ; cierra el archivo
    mov ah, 3Eh
    int 21h

leer_disco_fin:
    pop dx
    pop cx
    pop bx
    pop ax
    ret
leer_de_disco endp

; anota la imagen AL en la posicion del cursor si cabe en pantalla y queda lugar en la tabla
insertar_imagen proc
    push bx
    push cx
    push si

    ; ignora el atajo si la imagen de 5x5 se sale por la derecha o por abajo
    cmp fila_cur, FILA_MAX - 4
    ja insertar_fin
    cmp col_cur, COL_MAX - 4
    ja insertar_fin

    ; busca el primer registro libre, que es el que tiene numero de imagen 0
    mov si, 0
    mov cx, MAX_IMAGENES

buscar_libre:
    cmp tabla_imagenes[si], 0
    je anotar_imagen
    add si, 3
    loop buscar_libre
    jmp insertar_fin

anotar_imagen:
    ; guarda numero de imagen, fila y columna en los 3 bytes del registro
    mov tabla_imagenes[si], al
    mov bl, fila_cur
    mov tabla_imagenes[si+1], bl
    mov bl, col_cur
    mov tabla_imagenes[si+2], bl

insertar_fin:
    pop si
    pop cx
    pop bx
    ret
insertar_imagen endp

; recorre la tabla de imagenes y dibuja cada imagen colocada encima de lo que haya en pantalla
pintar_imagenes proc
    push ax
    push cx
    push dx
    push si

    mov si, 0
    mov cx, MAX_IMAGENES

pintar_img_ciclo:
    ; los registros con numero 0 estan libres y se saltan
    mov al, tabla_imagenes[si]
    cmp al, 0
    je siguiente_img
    mov dh, tabla_imagenes[si+1]
    mov dl, tabla_imagenes[si+2]
    call dibujar_imagen

siguiente_img:
    add si, 3
    loop pintar_img_ciclo

    pop si
    pop dx
    pop cx
    pop ax
    ret
pintar_imagenes endp

; dibuja la imagen AL de 5x5 con bloques de color desde la fila DH y la columna DL
dibujar_imagen proc
    push ax
    push bx
    push cx
    push dx
    push si

    ; elige la tabla de colores de la imagen pedida
    lea si, imagen_carita
    cmp al, 1
    je imagen_elegida
    lea si, imagen_corazon

imagen_elegida:
    ; CH cuenta las 5 filas y CL las 5 columnas de cada fila
    mov ch, 5

img_fila:
    push dx
    mov cl, 5

img_columna:
    ; dibuja un bloque 219 con el color de la celda y pasa a la siguiente
    mov al, 219
    mov bl, [si]
    call escribir_char
    inc si
    inc dl
    dec cl
    jnz img_columna

    ; regresa a la columna inicial y baja una fila
    pop dx
    inc dh
    dec ch
    jnz img_fila

    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret
dibujar_imagen endp

end inicio
