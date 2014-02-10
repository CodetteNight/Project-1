$NOLIST

$include (helper.asm)
$include (math32.asm)

putchar:
    JNB 	TI, putchar
    CLR 	TI
    MOV 	SBUF, a
    RET

sendTemp:
	jnb		sendBit, doneSendTemp
	mov		a, ovenTemp+1
	anl		a, #0FH
	orl		a, #30H
	lcall	putchar
	mov		a, ovenTemp+0
	swap	a
	anl		a, #0FH
	orl		a, #30H
	lcall	putchar
	mov		a, ovenTemp+0
	anl		a, #0FH
	orl		a, #30H
	lcall	putchar
	mov		a, #'\n'
	lcall	putchar
	mov		a, #'\r'
	lcall	putchar
	clr		sendBit
doneSendTemp:
	ret

delay:
	; delay 50ms
	mov R2, #38
delay_L3:	mov R1, #170
delay_L2:	mov R0, #255
delay_L1:	djnz R0, delay_L1
	djnz R1, delay_L2
	djnz R2, delay_L3
	ret

DO_SPI:
	clr SCLK ; clear clock
	mov R1, #0
	mov R2, #8
DO_SPI_LOOP:
	mov a, R0 ; R0 set as the bit we want to send
	rlc a
	mov R0, a
	mov MOSI, c ; set to enable slave input if bit set
	setb SCLK ; send
	mov c, MISO ; set the bit set from master input
	mov a, R1
	rlc a
	mov R1, a ; rotate the result in R1 with the new bit saved in carry bit
	clr SCLK
	djnz R2, DO_SPI_LOOP ; loop 8 times
	ret

INIT_SPI:
	orl P0MOD, #00101110b ; Set MOSI, SCK, SS, BUZZ as output
	anl P0MOD, #11111110b ; Set MISO as input
	clr SCLK
	ret

convert_room:
	; R1 = bits 0~7
	; R7 = bits 8,9
	
	; reset data
	mov x+0, #0
	mov x+1, #0
	mov x+2, #0
	mov x+3, #0
	mov y+0, #0
	mov y+1, #0
	mov y+2, #0
	mov y+3, #0
	mov bcd+0, #0
	mov bcd+1, #0
	mov bcd+2, #0
	mov bcd+3, #0
	
	mov a, R1
	mov x+0, a
	mov a, R7
	mov x+1, a
	
	
	load_y(500)	
	lcall mul32
	load_y(1024)
	lcall div32
	load_y(273)
	
	lcall sub32
	ret

convert_tc:
	; R1 = bits 0~7
	; R7 = bits 8,9
	
	; reset data
	mov x+0, #0
	mov x+1, #0
	mov x+2, #0
	mov x+3, #0
	mov y+0, #0
	mov y+1, #0
	mov y+2, #0
	mov y+3, #0
	mov bcd+0, #0
	mov bcd+1, #0
	mov bcd+2, #0
	mov bcd+3, #0
	
	mov a, R1
	mov x+0, a
	mov a, R7
	mov x+1, a
	
	
	load_y(15625)	
	lcall mul32
	load_y(61664)
	lcall div32
	ret

getOtemp:
	lcall	getRtemp
	
	load_x(roomTemp)
	lcall	bcd2hex
	mov		roomTemp, x+0
	lcall	getTCtemp
	mov		y+3, #00H
	mov		y+2, #00H
	mov		y+1, #00H
	mov		y+0, roomTemp
	lcall	add32
	lcall	hex2bcd
	mov		ovenTemp+1, bcd+1
	mov		ovenTemp+0, bcd+0
	ret

dispOtemp:
	mov		a, Line1
	lcall	LCD_command
	mov		R0, #7
	mov		a, Right1
	lcall	loop_command
	mov		R1, OvenTemp+1
	mov		R0, OvenTemp+0	
	setb	c
    lcall	time_temp
	ret

getRtemp:	; Result will be in BCD in roomTemp
	clr 	SS
	
	mov 	R1, #0
	mov 	R7, #0
	
	mov 	R0, SPI_START
	lcall 	do_SPI
	mov 	R0, CH0_room
	lcall 	do_SPI
	mov 	a, R1
	anl 	a, #3
	mov 	R7, a ; R7 = bit 8, 9
	lcall 	do_SPI ; R1 = bit 0 ~ 7
	setb 	SS
	lcall 	convert_room
	lcall	hex2bcd
	mov		roomTemp, bcd+0	
	lcall 	delay
	
	ret

getTCtemp:	; Result will be in x
	clr 	SS
	
	mov 	R1, #0
	mov 	R7, #0
	
	mov 	R0, SPI_START
	lcall 	do_SPI
	mov 	R0, CH1_tc
	lcall 	do_SPI
	mov 	a, R1
	anl 	a, #3
	mov 	R7, a ; R7 = bit 8, 9
	lcall 	do_SPI ; R1 = bit 0 ~ 7
	setb 	SS
	lcall 	convert_tc
	lcall 	delay
	
	ret

$LIST