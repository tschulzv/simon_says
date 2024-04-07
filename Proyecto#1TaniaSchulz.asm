;PROYECTO #1 - Simon Dice 
;ALUMNA: Tania Priscila Schulz Villalba

.model small
.stack 100h  

CR equ 13d
LF equ 10d
tab equ 9d


.data     
    inicio dw CR, LF, 'SIMON DICE', CR, LF, 'REGLAS:', CR, LF, 15,'MODO TEXTO: Apareceran secuencias de letras y numeros, debes memorizarlas',CR,LF, 'y luego escribirlas.',CR, LF,15,'MODO COLOR: Veras bloques de colores(azul, verde, turquesa, rojo, morado)', CR, LF, 'Debes escribir sus nombres, en mayusculas y sin espacios, Ej.: ROJOVERDEAZUL', CR, LF, 15, 'Tras 3 aciertos consecutivos, el nivel subira, la secuencia se hara mas larga y el tiempo para ingresarla mas corto', CR, LF, 15, 'El juego finaliza luego de tres intentos fallidos', CR, LF, '$'
    modo_msg db CR, LF, 'SELECCIONE MODO DE JUEGO:', CR, LF, '1. Texto', CR, LF, '2. Colores',,CR, LF,'Ingrese el numero: $'
    dificultad_msg db CR, LF,'SELECCIONE DIFICULTAD:', CR, LF, '1. Auto',CR, LF, '2. Facil',CR, LF, '3. Normal',CR, LF,'4. Dificil',CR, LF,'Ingrese el numero: $'
    secuencia_msg db CR, LF,'MEMORIZA LA SECUENCIA: $'
    input_msg db 'TU TURNO: $'
    continuar_msg db CR, LF, 'Presione ENTER para continuar, presione s para salir$'
    salir_msg db CR, LF, 'Para salir, presione ESPACIO $'
    incorrecto_msg db CR, LF, 'Respuesta incorrecta :( $'
    correcto_msg db CR, LF, 'Respuesta correcta :D $'
    puntaje_msg db 'Puntaje: $'
    nivel_msg db ' Nivel: $'
    vidas_msg db ' Vidas: $'
    fin_msg   db CR, LF,'FIN DEL JUEGO', CR, LF, '$'
    separador db CR, LF,43 dup (205), CR, LF, '$' 
    caracteres_validos db '0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz' ; para mapear caracteres validos
    modo_color db 0    ; valor booleano  
     
    INPUT db 40 dup (0); arreglo input del usuario
    puntaje db 0       ; puntaje
    nivel db 1         ; nivel
    vidas db 3         ; vidas que le quedan al usuario
    tiempo dw 91       ; tiempo p/ ingresar secuencia, aprox 5 segundos (1 seg = 18.2 ticks)
    tiempo_pausa dw 50 ; tiempo pausa p/ ver secuencia, 5 segundos por defecto
    longitud db 4
    aciertos db 0      ; cantidad de aciertos consecutivos
    seed dw 298d       ; semilla inicial para generar numeros 
    secuencia db 40 dup (0) ; arreglo donde se guarda secuencia generada
    nombres_colores db 'AZUL#VERDE#TURQUESA#ROJO#MORADO#' 

.code

start:    
  mov ax, @data
  mov ds, ax 
  
  mov dx, offset inicio  ; muestra mensaje de inicio
  call puts
  call pausa             ; pausa de 5 segundos aprox 
  mov dx, offset modo_msg
  call puts              ; pide seleccionar modo de juego
  call getc              ; si ingresa 1 = texto (POR DEFECTO)
  cmp al, '2'            ; 2 = colores            
  je colores             
  
  select_dificultad:
  mov dx, offset dificultad_msg  ; pide seleccionar dificultad
  call puts
  call getc              ; recibe el caracter
  cmp al, '1'
  je generar_auto        ; selecciona nivel de dificultad aleatoria
  cmp al, '2'
  je facil               ; cambia a dificultad facil
  cmp al, '3'
  je iniciar_juego       ; dificultad por defecto
  cmp al, '4'
  je dificil             ; cambia a dificultad dificil
  
      facil: 
        mov [tiempo_pausa], 100    ; la secuencia se mostrara 10 seg.
        jmp iniciar_juego          ; se inicia el juego           
      
      dificil: 
        mov [tiempo_pausa], 30     ; la secuencia se mostrara 3 seg.
        jmp iniciar_juego          ; se inicia el juego   
        
      generar_auto: ; genera una dificultad aleatoria (Algoritmo LCG)
        call num_random ; genera un numero                                           
        xor dx, dx      ; limpiar dx para evitar overflow
        mov bx, 3d      ; modulo sera un num 0-2 
        div bx          ; modulo en ax
        cmp ah, 0       ; si modulo = 0, cambia a facil
        je facil        
        cmp ah, 1       ; si modulo = 1, dificultad normal (por defecto)
        je iniciar_juego
        cmp ah, 2       ; si modulo = 2, camnia a dificil 
        je dificil
  
  colores: 
     mov [modo_color], 1    ; se setea como TRUE a modo_color
     jmp select_dificultad  ; luego seleccionar dificultad
  
  iniciar_juego:     
    call preguntar_salir         ; pregunta si desea salir/continuar
     
    call limpiar_pantalla        ; limpia la pantalla
    call barra_superior          ; imprime barra con puntaje, vidas, nivel 
    mov dx, offset secuencia_msg ; anuncia que se mostrara la secuencia
    call puts  
         
    call generar_num             ; genera la secuencia
    call pausa                   ; pausa para memorizar
    call preguntar_salir  
    call limpiar_pantalla        ; la secuencia desaparece
    call barra_superior          ; imprime barra
    mov dx, offset input_msg     ; mensaje para ingresar 
    call puts
    call entrada_usuario         ; gestiona la entrada del usuario
    call verificar_respuesta     ; verifica si la respuesta es correcta 
    
    cmp [vidas], 0               ; verifica si quedan vidas al usuario
    je fin_del_juego             ; si vidas = 0, termina el juego
    jmp iniciar_juego            ; de lo contrario, se inicia otra ronda
  
  fin_del_juego:
    mov dx, offset fin_msg       ; mensaje de fin
    call puts
    mov dx, offset puntaje_msg   ; mensaje de puntaje
    call puts
    call num_dos_digitos         ; muestra puntaje acumulado
    mov dx, offset nivel_msg     ; mensaje de nivel
    call puts
    mov dl, [nivel]
    add dl, 30h                  ; muestra nivel alcanzado
    call putc
    call end_program             ; finaliza, retorna control al S.O.
 
  preguntar_salir: ; pregunta si el usuario desea salir
    mov dx, offset continuar_msg ; imprime pregunta 
    call puts
    call getc                    ; recibe el caracter
    cmp al, 's'                  ; si ingresa s, termina, de lo contrario continua
    je fin_del_juego
    ret 
        
  pausa: ; realiza una pausa en el programa segun numero en cx:dx
    push ax ; resguarda valores de registros
    push bx
    push cx
    push dx 
    mov cx, [tiempo_pausa] ; mueve el valor de la variable a cx - parte alta del tiempo 
    mov ah,86h             ; funcion delay 
    mov dx, 8480h          ; parte baja del tiempo
    int 15h                ; interrupcion
    pop dx  ; recupera valores de los registros
    pop cx
    pop bx
    pop ax
    ret    
        
 
       
  barra_superior: ; imprime la barra con puntaje, nivel y vidas 
    push ax ; resguarda valores de registros
    push bx
    push cx
    push dx
    mov dx, offset puntaje_msg
    call puts 
    call num_dos_digitos
    mov dl, tab
    call putc
    mov dx, offset nivel_msg
    call puts
    mov dl, [nivel] 
    add dl, 30h
    call putc
    mov dl, tab
    call putc
    mov dx, offset vidas_msg
    call puts
    mov cl, 0  ; contador de corazones
    imprimir_vidas: ; imprime los corazones
        cmp cl, [vidas]
        je fin_barra
        mov dl, 3d  ; codigo ascii emoticon de corazon
        call putc
        inc cl
        jmp imprimir_vidas
    fin_barra:
        mov dx, offset separador
        call puts
        pop dx  ; recupera valores de registros
        pop cx
        pop bx
        pop ax       
        ret
         
   num_random: 
   ; Utiliza el algoritmo LCG (Generador Lineal Congruencial)
   ; FORMULA: Xn+1 = (a*Xn + c) mod m  
   
     mov ax, 527d    ; corresponde a 'a' en la formula 
     mov bx, [seed]  ; valor de la semilla - (Xn o Xn+1)
     mul bx          ; se multiplica semilla * 54 
     add ax, 310d    ; corresponde a 'c'  
     xor dx, dx
     mov bx, 17d     ; corresponde a 'm'
     div bx          ; se divide, modulo en ax    
     add [seed], ax  ;sumar a la semilla anterior para generar el prox. num
     ret
        
   generar_num:  ; genera secuencia aleatoria (Algoritmo LCG)     
    push ax
    push bx
    push cx
    push dx   
    mov di, 0 ; inicializar indice de arreglo
    mov ch, [longitud]  ; la longitud de la secuencia es el valor del fin del bucle
    mov cl, 0           ; contador de iteraciones
    generar_loop:
        cmp cl, ch      ; cuando contador = longitud 
        je fin_loop     ; el bucle termina
        call num_random ; genera un numero
        
   ; JUEGO EN MODO COLOR: 
        cmp modo_color, 1  ; si MODO_COLOR = TRUE
        je generar_color   ; genera un color
         
   ; JUEGO EN MODO TEXTO:  
    validar_secuencia: ; asegurar que la secuencia contenga solo caract. alfanumericos
        ; existen 61 caracteres validos, se halla el modulo para generar un num 0-60 
        
        xor dx, dx      ; limpiar dx para evitar overflow
        mov bx, 61d 
        div bx          ; modulo en ax
        mov si, ax      ; indice del arreglo caracteres_validos
        mov al, [caracteres_validos + si] ; copia un caracter valido del arreglo
        mov [secuencia + di], al ; guarda el numero en el arreglo de secuencia
        inc cl  ; incrementa contador 
        inc di  ; incrementa indice del arreglo
        jmp generar_loop 
        
                    
    fin_loop:       
        mov [secuencia + di], '$' ; marca el final de la secuencia
        mov di, 0  ; resetea el indice de arreglo para luego imprimirlo 
        cmp modo_color, 1   ; MODO COLOR: no se necesita imprimir el texto
        je retornar     
        
        mov dx, offset secuencia  ; al contrario, MODO TEXTO: imprimir la secuencia
        call puts
          
        retornar:
            pop dx  ; recupera valores de registros
            pop cx
            pop bx
            pop ax  
            ret     ; retornar control
  
        
  generar_color:
    push cx         ; guardar valor de cx
    xor dx, dx      ; limpiar dx para evitar overflow
    mov bx, 5d      ; dara como modulo un num. 0-4
    div bx          ; modulo en ah
    inc ah          ; incrementar para que el color no sea negro (0)
        
    cmp ah, 1       ; codigo del azul
    je azul
    cmp ah, 2       ; codigo del verde
    je verde
    cmp ah, 3       ; codigo del turquesa
    je turquesa
    cmp ah, 4       ; codigo del rojo
    je rojo
    cmp ah, 5       ; codigo del morado
    je morado 
        
    azul:
        mov si, 0 ; indice AZUL en arreglo de colores
        jmp copiar_nombre
        
    verde: 
        mov si, 5 ; indice VERDE en arreglo de colores
        jmp copiar_nombre  
        
    turquesa:
        mov si, 11 ; indice TURQUESA en arreglo de colores
        jmp copiar_nombre
        
    rojo:
        mov si, 20 ; indice ROJO en arreglo de colores
        jmp copiar_nombre 
        
    morado: 
        mov si,25  ; indice MORADO en arreglo de colores
        jmp copiar_nombre
                
    copiar_nombre: 
        mov bl, [nombres_colores + si]  ; 
        cmp bl, '#'               ; verifica si llego al fin de la palabra
        je fin_copiar  
        mov [secuencia + di], bl  ; copia el caracter al arreglo de secuencia 
        inc si                    ; incrementa indices
        inc di
        jmp copiar_nombre         ; continua el bucle

    fin_copiar: 
        pop cx                    ; recupera el valor de cx
        call colorear             ; colorea un rectangulo del color generado
        inc cl                    ; incrementa contador de colores 
        jmp generar_loop          ; genera otro
            
            
  colorear: ; colorea un rectangulo del color generado
     push cx
     mov bl, ah ; codigo del color
     
     mov bh, 0  ; pagina
     mov dl, cl ; columna -> contador de colores generados
     mov dh, 5  ; fila
     mov ah, 2  ; servicio para pintar un caracter 
     int 10h
              
     mov ah, 9h
     mov al, 219d ; caracter -> rectangulo
     mov bh, 0    ; pagina
     mov cx, 1    ; cantidad de caracteres a imprimir
     int 10h      
     pop cx       ; recupera valor de cx
     ret                                  
     
   ;BASADO EN: https://stackoverflow.com/questions/75604322/timer-for-getting-input-in-tasm-8086      
  entrada_usuario:
    push ax    ; resguarda valores de registros
    push bx
    push cx
    push dx 

    mov  si, 0 ; inicializar indice del arreglo INPUT
    
    iniciar_temporizador: ; cronometra tiempo para ingresar la secuencia
        xor  ah, ah       ; limpia ah
        ; funciona contando los ticks 1 seg = 18.2 
        mov cx, [tiempo]  ; tiempo 
                           
             
    ingresar_loop:
        mov  ah, 01h        ; verifica si tecla es presionada
        int  16h            ; -> AX ZF
        jnz  ingresado      ; si se esta presionando una tecla, ir a Ingresado
    
        ; Comprueba si el temporizador acabo
        dec  cx
        jnz  ingresar_loop  ; Si temporizador != 0, continua esperando
    
        ; Si temporizador = 0, salir 
        jmp  InputDone

    ingresado:
        mov  ah, 00h        ; recupera caracter del buffer
        int  16h            ; guarda -> AX
        mov dl, al          ; mostrar caracter por pantalla
        call putc
        cmp al, CR          ; si usuario ingresa Enter, finaliza
        je InputDone
        mov  [INPUT + si], al  ; determina el indice correspondiente, alli guarda el caracter
        inc  si             ; Incrementa indice del array
        jmp  ingresar_loop  ; Luego, continua esperando entrada del usuario

    InputDone:
        mov [INPUT + si], '$' ; agrega $ al ultimo indice
        pop dx                ; recupera valores de registros
        pop cx
        pop bx
        pop ax
        ret
    
  verificar_respuesta: ; compara si el input y la secuencia son iguales
    push ax            ; resguarda valores de registros
    push bx
    push cx
    push dx
    
    mov si, 0   ; setea contador de indice del usuario
    mov di, 0   ; setea contador de indice de la secuencia
    verific_loop:
        mov bh, INPUT[si]     ; mueve a bh el caracter de determinado indice
        cmp bh, secuencia[di] ; compara ambos arreglos de caracteres
        je continuar          ; si son iguales, continua comparando
        
        incorrecto: ; de lo contrario es incorrecto
            mov dx, offset incorrecto_msg  ; muestra mensaje 
            call puts
            dec [vidas]   ; resta una vida 
            mov [aciertos], 0     ; resetea contador de aciertos
            jmp fin_verificacion  ; sale del bucle
            
        continuar:
            cmp bh, '$' ; comprueba si llego al final de la secuencia
            je correcto
            inc si  ;si no, incrementa el indice de arreglos
            inc di
            jmp verific_loop  ; verifica el sigte caracter
        
        correcto:
        mov dx, offset correcto_msg  ; muestra mensaje
        call puts
        inc [puntaje]         ; incrementa puntaje
        inc [aciertos]        ; incrementa contador de aciertos
        cmp [aciertos], 3     ; con 3 aciertos de seguido, se sube de nivel
        je subir_nivel          
        jmp fin_verificacion  ; sale del bucle
    
    subir_nivel:
        inc [nivel]           ; se incrementa el nivel
        inc [longitud]        ; se incrementa la longitud
        mov ax, [tiempo]
        sub ax, 18            ; decrementa el tiempo de ingreso aprox. 1 s (1 s=18.2 ticks) 
        mov [tiempo], ax
        mov [aciertos], 0     ; se resetea el contador de aciertos
    
    fin_verificacion:
        pop dx  ; recupera valores de registros
        pop cx
        pop bx
        pop ax
        ret     ; retorna el control
                
  limpiar_pantalla: ; subrutina proporcionada por el profesor Nestor Tapia
        push ax ; guardar valores de los registros 
        push bx 
        push cx 
        push dx 
        mov ah, 00h
        mov al,03h     
        int 10h
        pop dx  ; recuperar valores de registros
        pop cx 
        pop bx 
        pop ax  
        ret      
  
  
   num_dos_digitos: ; Usado para imprimir el puntaje de dos digitos. 
    ; Subrutina otorgada por el profesor Nestor Tapia
        push ax ; guardar valores de los registros 
        push bx 
        push cx 
        push dx 
        mov al, [puntaje]
        AAM
        MOV BX, AX ; EL NUMERO SE GUARDA EN BX
        MOV AH, 02h
        MOV DL, BH
        ADD DL, 30h
        INT 21H
        MOV AH, 02h
        MOV DL, BL
        ADD DL, 30H
        INT 21H
        pop dx  ; recuperar valores de registros
        pop cx 
        pop bx 
        pop ax 
        ret

  puts: ; muestra string
        push ax ; guardar valores de los registros 
        push bx 
        push cx 
        push dx 
        mov ah, 9h
        int 21h ; mostrar string
        pop dx  ; recuperar valores de registros
        pop cx 
        pop bx 
        pop ax 
        ret
        
  putc: ; muestra caracter
        push ax ; guardar valores de los registros 
        push bx 
        push cx 
        push dx 
        mov ah, 2h
        int 21h
        pop dx  ; recuperar valores de registros
        pop cx 
        pop bx 
        pop ax 
        ret
        
  getc: ; lee un caracter y lo guarda en al
        push bx ; guardar valores de los registros
        push cx 
        push dx 
        mov ah, 1h
        int 21h ; lee el caracter
        pop dx  ; recuperar valores de registros
        pop cx 
        pop bx 
        ret
        
  end_program:  ; retorna control al S.O.
        mov ax, 4c00h 
        int 21h

end start