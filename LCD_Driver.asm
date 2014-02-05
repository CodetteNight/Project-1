$MODDE2
org 0000H
   ljmp MyProgram

Wait40us:
	mov R0, #149
Wait40us_L0: 
	nop
	nop
	nop
	nop
	nop
	nop
	djnz R0, Wait40us_L0 ; 9 machine cycles-> 9*30ns*149=40us
    ret

LCD_put:
	mov	LCD_DATA, A
	setb LCD_RS
	ljmp LCD_finish

LCD_command:
	mov	LCD_DATA, A
	clr	LCD_RS
LCD_finish:
	nop
	nop
	setb LCD_EN ; Enable pulse should be at least 230 ns
	nop
	nop
	nop
	nop
	nop
	nop
	clr	LCD_EN
	ljmp Wait40us

; Send a constant-zero-terminated string through the serial port
SendString:
    CLR 	A
    MOVC 	A, @A+DPTR
    JZ 		SSDone
    LCALL 	LCD_put
    INC 	DPTR
    SJMP 	SendString
SSDone:
	ret
	    
IDLE_1:
    DB  'IDLE KEY3 TO RUN',0
IDLE_2:
	DB	'C KEY2 TO SET', 0

LCD_Init:
    ; Turn LCD on, and wait a bit.
    setb LCD_ON
    clr LCD_EN  ; Default state of enable must be zero
    lcall Wait40us
    
    mov LCD_MOD, #0xff ; Use LCD_DATA as output port
    clr LCD_RW ;  Only writing to the LCD in this code.
	
	mov a, #0ch ; Display on command
	lcall LCD_command
	mov a, #38H ; 8-bits interface, 2 lines, 5x7 characters
	lcall LCD_command
	mov a, #01H ; Clear screen (Warning, very slow command!)
	lcall LCD_command
    
    ; Delay loop needed for 'clear screen' command above (1.6ms at least!)
    mov R1, #40
Clr_loop:
	lcall Wait40us
	djnz R1, Clr_loop
	ret
    
MyProgram:
	mov 	sp, #07FH
	clr 	a
	mov 	LEDG,  a
	mov 	LEDRA, a
	mov 	LEDRB, a
	mov 	LEDRC, a
	
    lcall 	LCD_Init
    mov		a, #80H
    lcall	LCD_command
    mov		dptr, #IDLE_1
	lcall 	SendString
	
    mov 	a, #0C0H
	lcall 	LCD_command
	mov		dptr, #IDLE_2
	lcall 	SendString
	
	END0
	