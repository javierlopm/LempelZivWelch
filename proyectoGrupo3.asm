################################
#   Proyecto 2 Compresion LZW  
#
# Integrantes:
#	Javier Lopez  11-10552
#	Daniela Socas 11-10979
#
# Ultima modificacion: 
#	6/11/2014
#	
###############################

.data
auxLista:    .word 0	 #Auxiliar para crear ListasEnlazadas en la tabla de hash
diccionario: .word 0     #Direccion de la lista enlazada
numEntradasDic: .word 25 #Indice del ultimo valor del diccionario

dirEntrada: .word 0	#Direccion del String a comprimir
tamEntrada: .word 0	#Su longitud

mensajeInit: .asciiz "Este programa realiza compresion LWZ sobre una cadena de caracteres \n"

mensajeTam: .asciiz "Introduzca la longitud del String a comprimir: \n"
mensajeStr: .asciiz "Introduzca un String a comprimir \n"
espacio   : .asciiz " "

.text
main:	
	#Inicializacion del diccionario
	jal init
	sw $v0,diccionario
	
	#Lectura de un String
	la $a0,mensajeInit
	li $v0,4
	syscall
	
	la $a0,mensajeTam	# Lectura del entero longitud
	syscall
	li $v0,5	
	syscall
	addi $v0,$v0,1
	sw $v0,tamEntrada
	
	
	lw $a0, tamEntrada 	#Reserva de espacio
	li $v0,9
	syscall
	sw $v0,dirEntrada
	
	la $a0,mensajeStr       #Mensaje de introducccion de datos
	li $v0,4
	syscall
	
	lw $a0,dirEntrada	#Lectura de String
	lw $a1,tamEntrada
	li $v0,8		
	syscall
	
	lw $a0, diccionario	#Inicio de la compresion
	lw $a1, dirEntrada
	lw $a2, tamEntrada
	addi $a2,$a2,-1
	jal comprimir

	li $v0,10		#Fin del programa
	syscall



# Funciones y Procedimientos
#
#  Strings:
#  -concatString
#  -compararString
#  -desplazarString
#
#  Listas Enlazadas:
#  -crearLista
#  -agregarAlfinal
#  -buscarString
#  
#
#  Tabla de Hash:
#  -init
#  -funcionHash
#  -comprimir
#
############################################


########################################################	
# concatena el contenido de ambos en un nuevo String   #
# almacenado en una direccion $v0                      #
# 					               #
# $a0	Direccion de String1   			       #
# $a1   Direccion de String2 			       #
# $a2          Longitud de String1		       #
# $v0(entrada) Longitud de String2                     #
#						       #
# $v0(salida) Direccion del nuevo String	       #
# $v1	      Longitud del mismo		       #
########################################################
concatStrings:
	move $t4, $a0 		#Guarda en $t4 la direccion del String 1 	
	add  $a0, $v0, $a2	#Guarda en $a0 la longitud del total 
	move $v1,$a0
	li   $v0, 9		#Reserva el espacio total
	syscall 	
	
	move $t3, $v0 		#Direccion del String total en $t3
	li $t7, 1		#Contador de longitud
	
concatena1:
	lb   $t6, 0($t4)	#Carga en $t6 el byte a agregar 
	sb   $t6, 0($t3)	#Guarda en memoria en byte cargado
	addi $t3, $t3, 1	#Aumenta uno a la direccion de memoria
	addi $t7, $t7, 1 	#Aumenta uno al contador
	addi $t4, $t4, 1	#Aumenta uno el string 1 
	bne  $t7, $a2, concatena1	#Hace el ciclo hasta que las longitudes sean iguales

concatena2:
	lb   $t6, 0($a1)	#Carga en $t6 el byte a agregar 
	sb   $t6, 0($t3)	#Guarda en memoria en byte cargado
	addi $a1, $a1, 1	#Aumenta uno el string 2
	addi $t3, $t3, 1	#Aumenta uno a la direccion de memoria
	addi $t7, $t7, 1 	#Aumenta uno al contador
	#Hace el ciclo hasta que las longitudes sean iguales y termina.
	bne  $t7, $a0, concatena2	
	
	jr $ra 

##################################################
#  Funcion que indica si dos Strings de igual    #
#  tamano son iguales				 #
#				    	    	 #
#  $a0 Dir del primer String                     #
#  $a1 Dir del segundo String			 #
#  $a2 Longitud del String			 #
#  						 #
#  $v0 1 si son iguales, 0 si no		 #
##################################################
compararStrings:
	li $t0,0  #Contador de avance
	
contComparacion:
	#Construccion de las direcciones de las secciones a comparar
	#sll $t1,$t0,2
	add $t2,$a0,$t0	#Dir base + Desp
	add $t3,$a1,$t0
	
	#Carga de valores
	lw $t2,0($t2)
	lw $t3,0($t3)
	
	li $t6,4  #Contador del ciclo interno
continuarSec:			
	#Aplicacion de Mascara y comparacion del char
	andi $t4,$t2,0xFF
	andi $t5,$t3,0xFF
	bne $t4,$t5,falseC
	#Desplazamiento de los ya comparados
	srl $t2,$t2,8
	srl $t3,$t3,8
	#Act. del contador
	addi $t6,$t6,-1
	bnez $t6,continuarSec
	#Fin del ciclo interno
	
	addi,$t0,$t0,4
	sub $t7,$a2,$t0
	bgtz $t7,contComparacion #Mientras en el contador sea positivo se compara

trueC:   li $v0,1
	b salirComp
falseC:  li $v0,0
	
salirComp: 
	jr $ra

#################################################
# Procedimiento que desplaza el contenido de un #
# String, manteniendo su formato                #
#                                               #
# $a0   Direccion de String a mover             #
# $a1   Longitud de String                      #
#################################################
desplazarString:
	move $t3,$zero
	#Mascara para el caracter menos significativo
	ori $t3,0x00FF 
	
moverChar: #Realiza movimiento de tres caracteres
	lw $t0,0($a0)	#Se carga en $t0 el contenido
	srl $t0,$t0,8	#los valores son desplazados un caracter
	addi $a1,$a1,-3
	sw $t0,0($a0)	#Se guardan los cambios
	bltz $a1,finDesp
	
continuarDesp: #Realiza movimiento de un caracter
	lw $t1,4($a0)	#Se extrae el primer caracter del siguiente bloque
	and $t1,$t1,$t3	
	sll $t1,$t1,24  #Se coloca en $t1 como ultimo caracter
	
	or $t0,$t0,$t1	#Se agrega al bloque anterior
	sw $t0,0($a0)
	
	addi $a1,$a1,-1 
	addi $a0,$a0,4
	bltz $a1,finDesp #Ambos ciclos finalizan cuando todos los
	b moverChar	 #caracteres han sido desplazados

finDesp:
	jr $ra

##################################################
#  Funcion que crea una lista enlazada 		 #
#  						 #
#  $v0 contiene la direccion de la lista creada  #
##################################################
crearLista: 
	li $a0,16	#Reserva de espacio
	li $v0,9
	syscall  
	
	sw $zero,0($v0)   #identificador
	sw $zero,4($v0)   #cantidad de elementos enlazados
	sw $zero,8($v0)   #apuntador a la primera caja
	sw $zero,12($v0)  #apuntador a la ultima caja
	jr $ra

###################################################
#  Funcion que agrega un elemento al final de una #
#  lista enlazada				  #
#						  #
#  $a0  direccion de la lista	`		  #
#  $a1  indice de la clave			  #
#  $a2  longitud  del String			  #
#  $a3  direccion del String     	          #
###################################################
agregarAlFinal:
	move $t0,$a0
	
	li $a0,16	#Reserva de espacio y creacion del nuevo elemento
	li $v0,9
	syscall
	
	move $a0,$v0
	
	lw $t2,4($t0)	#Aumento del numero de elementos de la lista
	addi $t1,$t2,1  
	sw $t1,4($t0)
	
	#Asignacion de los valores de la caja
	sw $a1,0($v0)	     #indice
	sw $a2,4($v0)        #longitud
	sw $a3,8($v0)  	     #direccion del string
	sw $zero,12($v0)     #espacio reservado para siguiente caja 
	
	beqz $t2,vacia	
	lw $t3,12($t0)	
	sw $v0,12($t3)  #Conexion de la caja creada al ultimo elemento de la lista
	sw $v0,12($t0)  #Conexion al encabezado
	b seguir
vacia:	sw $v0,8($t0)	#Conexion al encabezado como primer y ultimo elemento
	sw $v0,12($t0)
	
seguir:	jr $ra

###################################################
#  Funcion que busca en una lista enlazada, si un #
#  string se encuentra en esta y entrega 1 si lo  #
#  encuentra, y su identificador asociado         #
#						  #
#  $a0  direcion del String	`		  #
#  $a1  direccion de la lista			  #
#  $a2  longitud  del String			  #
#						  #
#  $v0  1 si se encuentra,0 si no    	          #
#  $v1  contiene el indice del String buscado     #
###################################################
buscarString: 	
	addi $sp,$sp,-16  #Responsabilidad de llamado
	sw $s0,0($sp)	  
	sw $s1,4($sp)
	sw $s2,8($sp)
	sw $ra,12($sp)
	
	lw $s0,8($a1)	#Primer elemento, auxiliar de recorrido
	move $s1,$a2
	move $s2,$a0	
	
iterBusqueda:
	lw $t0,4($s0)	
	bne $s1,$t0,avanzarB  #Compara si las long son iguales
	
	lw $a0,8($s0)		#Direccion String 1
	move $a1,$s2		#Direccion String 2
	move $a2,$s1		#Longitud
	jal compararStrings
	lw $v1,0($s0)		#Salida del indice
	bnez $v0,finB 		#Si es true, dejar este valor y finaliza la funcion
	beqz $s0,falseB
avanzarB:
	lw $s0,12($s0)
	bnez $s0,iterBusqueda

falseB:	li $v0,0	#Resultado de recorrer todas las cajas
finB:		
	lw $s0,0($sp)	#Recuperacion de registros modificados
	lw $s1,4($sp)
	lw $s2,8($sp)
	lw $ra,12($sp)
	addi $sp,$sp,16
	jr $ra 

##################################################
#  Procedimiento que crea un diccionario	 #
#  como tabla de hash 				 #
#						 #
#  $v0  contiene la direccion de la tabla        #
##################################################
init:	li $a0,104	  #Reserva de espacio para 26 
	li $v0,9	  #listas enlazadas (una por letra)
	syscall
	
	addi $sp,$sp,-16  #Almacenamiento de registros usando  
	sw $ra,0($sp)	  #responsabilidades compartidas
	sw $a0,4($sp)	  
	sw $s0,8($sp)	
	sw $v0,12($sp)    #Direccion del arreglo
	li $s0,0          #Contador de elementos recorridos
	
loopinit:			
	jal crearLista #En v0 esta la direccion de la nueva lista
		       #Se agrega en la posicion correspondiente del arreglo
	
	#Calculo de la direccion del espacio correcto en el arreglo
	lw $a0,12($sp)	
	sll $t0,$s0,2 	
	add $a0,$a0,$t0 # $a0 = Dir de arreglo + 4 * contador
	
	sw $v0,0($a0) 
	move $t0,$v0
	
	#Se agrega una caja con el contenido correspondiente a la lista creada
	li $a0,1 	#Creacion del char de init de cada caja
	li $v0,9
	syscall
	
	addi $t1,$s0,65 #Calculo del caracter a guardar = contador + 65
	sw $t1,0($v0)
	
	move $a0,$t0	     #Direccion de la lista
	move $a1,$s0         #Identificador
	addi $a2,$zero,1     #Longitud 1 del String (caracter)
	move $a3,$v0	     #Direccion del String
	
	jal agregarAlFinal
	
	addi $s0,$s0,1
	addi $t2,$s0,-26
	bnez $t2,loopinit
	
	lw $ra,0($sp)	#Recuperacion de los registros responsabilidad del llamado
	lw $s0,8($sp)
	lw $v0,12($sp)
	addi $sp,$sp,16
	
	jr $ra

####################################################
#  Funcion que recibe un String o caracter e 	   #
#  indica en que posicion de la tabla de hash      #
#  se deberia encontrar			           #
#						   #
#  $a0 Direccion de la tabla de hash               #
#  $a1 Direccion de la cadena de caracteres        #
#						   #
#  $v0  Direccion donde debe econtrarse la entrada # 
####################################################
funcionHash:
	lw   $v0,0($a1)     #Carga del inicio del String
	andi $v0,$v0,0xff   #Mascara para el primer caracter
	addi $v0,$v0,-65    #Valor en el arreglo
	sll  $v0,$v0,2	    #Desplazamiento indice * 4
	add  $v0,$v0,$a0
	
	lw $v0,0($v0) #Se carga el contenido del espacio calculado
	
	jr $ra

####################################################
#  Procedimiento que comprime un String e imprime  # 
#  los valores resultantes de la misma		   #
#                                     		   #
#  $a0 direccion de la tabla de hash               #
#  $a1 direccion del String                        #
#  $a2 longitud del String                         #
####################################################
comprimir:
	addi $sp,$sp,-32	
	sw $s0,0($sp)	#Responsabilidades del llamado
	sw $s1,4($sp)
	sw $s2,8($sp)
	sw $s3,12($sp)
	sw $s4,16($sp)
	sw $s5,20($sp)
	sw $s6,24($sp)
	sw $ra,28($sp)  #Responsabilidad del llamador
	
	move $s0,$a0 	#S0 tabla de hash
	move $s1,$a1	#Dir de String
	move $s2,$a2	#Longitud del String de entrada
	
	li $s3,0  #Longitud del String de Lectura
		  #$s4 contendra la direccion del String nuevo
	
cicloCompress:
	#Leer primer caracter, colocar en un nuevo String, actualiza Tamanos
	lw $t0,0($s1)
	andi $t0,$t0,0xff
	addi $s3,$s3,1
	
	li $a0,1	#Almacenamiento del caracter
	li $v0,9
	syscall
	
	sw $t0,0($v0)
	
	addi $t2,$zero,1
	beq $s3,$t2,noConcat	#Si el String de lectura es de tam 1
				#Se procede a buscar su entrada
	move $a0,$s4		#En caso contrario, se concatena con el contenido
	move $a1,$v0		#anterior
	move $a2,$s3
	li $v0,1
	jal concatStrings #Ahora v0 contiene la concatenacion de Strings
	
noConcat:
	move $s4,$v0

	#Se procede a buscar la entrada en el diccionario
	move $a0,$s0
	move $a1,$s4
	jal funcionHash #Busqueda de la lista enlazada adecuada
	move $s6,$v0
	
	move $a0,$s4
	move $a1,$s6	#Contiene la lista enlaza en donde deberia encontrarse
	move $a2,$s3
	
	jal buscarString
	
	#Salto si la entrada no estaba presente
	beqz $v0,noEsta
	move $s5,$v1	#S5 contine el indice del ultimo String encontrado
	
	move $a0,$s1	#Si se encontro, el String es desplazado, para realiza
	move $a1,$s2	#una nueva concatenacion
	jal desplazarString
	
	addi $s2,$s2,-1 #Actualizacion de String despues de desplazamiento
	
	b cicloCompress
	
noEsta:			#S6 contiene la ultima lista guardada de elem no encontrado
	move $a0,$s5	#Impresion del index del ultimo String encontrado
	li $v0,1
	syscall
	
	la $a0,espacio	#Impresion de un espacio para delimitar los codigos a imprimir
	li $v0,4
	syscall
	
	move $a0,$s6		#Se agrega en la ultima lista una nueva caja
	lw $a1, numEntradasDic	#Ultima entrada +1
	addiu $a1,$a1,1		#Suma sin signo, ya que no hay entradas negativas
	sw $a1, numEntradasDic
	move $a2,$s3		#Longitud s3
	li $s3,0		#Se reinicia en 0 la longitud del String de lectura
	move $a3,$s4		#Direccion del ultimo String
	jal agregarAlFinal	
	
	bnez $s2,cicloCompress	#Mientras el String no este vacio, se comprime
			
	lw $s0,0($sp)	#Recuperacion de los registros responsabilidad
	lw $s1,4($sp)	#del llamado
	lw $s2,8($sp)
	lw $s3,12($sp)
	lw $s4,16($sp)
	lw $s5,20($sp)
	lw $s6,24($sp)
	lw $ra,28($sp)  
	addi $sp,$sp,32
	jr $ra
