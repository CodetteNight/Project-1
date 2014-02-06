$NOLIST
;----------------------------------------------------
; helper.asm: 
;
;----------------------------------------------------

Line1 	EQU #80H		; Move to the beginning of the first row
Line2 	EQU #0C0H		; Move to the beginning of the second row
Right1 	EQU #14H		; Move the cursor one space to the right

org 0000H
   ljmp MyProgram
   
DSEG at 30H
roomTemp:	ds	1
ovenTemp:	ds	2
R2S_Temp:	ds	2
S_Time:		ds	2
R2P_Temp:	ds	2
R_Time:		ds	2

BSEG
I:		dbit	1	;Idle state flag
R2S:	dbit	1	;Ramp-2-Soak state flag
S:		dbit	1	;Soak state flag
R2P:	dbit	1	;Ramp-2-Peak state flag	
R:		dbit	1	;Reflow state flag
CL:		dbit	1	;Cooling state flag

CSEG

IDLE_1:
    DB  'IDLE KEY3 TO RUN',0
IDLE_2:
	DB	'C KEY2 TO SET', 0 
SRAMP:
	DB	'SRAMP',0
SOAK:
	DB	'SOAK',0
PRAMP:
	DB	'PRAMP',0
REFLOW:
	DB	'REFLOW',0
COOL:
	DB	'COOL',0
GLOBAL:
	DB	'GBL',0
;---------------------------------------------------
; Clear the LCD Screen
;---------------------------------------------------
clear_LCD:
	push 	acc
	push 	psw
	push 	AR0
	push 	AR1
	push 	AR2
	
	mov 	a, #01H
	lcall 	LCD_command
    mov 	R1, #40
clear_loop:
	lcall 	hide_Wait40us
	djnz 	R1, clear_loop

	pop 	AR2
	pop 	AR1
	pop 	AR0
	pop 	psw
	pop 	acc
	ret
	
;---------------------------------------------------
; PUT a character on the screen 
;        or 
; execute a COMMAND
;---------------------------------------------------
LCD_put:
	push 	acc
	push 	psw
	push 	AR0
	push 	AR1
	push 	AR2
	
	mov		LCD_DATA, A
	setb 	LCD_RS
	sjmp	LCD_put_done
LCD_command:
	push 	acc
	push 	psw
	push 	AR0
	push 	AR1
	push 	AR2
	
	mov		LCD_DATA, A
	clr		LCD_RS
LCD_put_done:
	nop
	nop
	setb 	LCD_EN
	nop
	nop
	nop
	nop
	nop
	nop
	clr		LCD_EN
	lcall 	hide_Wait40us
	
	pop 	AR2
	pop 	AR1
	pop 	AR0
	pop 	psw
	pop 	acc
	ret

;---------------------------------------------------
; 40us Delay
;---------------------------------------------------	
Wait40us:	
	push 	acc
	push 	psw
	push 	AR0
	push 	AR1
	push 	AR2
	
	mov 	R0, #149
Wait40us_loop: 
	nop
	nop
	nop
	nop
	nop
	nop
	djnz 	R0, Wait40us_loop
	
	pop 	AR2
	pop 	AR1
	pop 	AR0
	pop 	psw
	pop 	acc
    ret
	
;---------------------------------------------------
; Internal call, not used in main program
;---------------------------------------------------	
hide_Wait40us:	
	mov 	R0, #149
hide_Wait40us_loop: 
	nop
	nop
	nop
	nop
	nop
	nop
	djnz 	R0, hide_Wait40us_loop
    ret
    
$LIST