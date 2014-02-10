$NOLIST
;----------------------------------------------------
; helper.asm: 
;
;----------------------------------------------------

Line1 	EQU #80H		; Move to the beginning of the first row
Line2 	EQU #0C0H		; Move to the beginning of the second row
Right1 	EQU #14H		; Move the cursor one space to the right
Left1	EQU #10H		; Move the cursor one space to the left

BZTIME	EQU	#50

T0LOAD EQU 65536-(CLK/(12*2*FREQ))

CLK EQU 33333333
FREQ EQU 100
T1LOAD EQU 65536-(CLK/(12*FREQ))

BAUD EQU 115200
T2LOAD EQU 65536-(CLK/(32*BAUD))

MISO EQU P0.0
MOSI EQU P0.1
SCLK EQU P0.2
SS   EQU P0.3
BUZZ EQU P0.5

SPI_START	EQU #00000001b ; start bit for the transmission
CH	 		EQU #10000000b ; channel select

org 0000H
   ljmp MyProgram
  
org 000BH
	ljmp ISR_timer0  
  
org 001BH
	ljmp ISR_timer1
   
DSEG at 30H
roomTemp:	ds	1	; Current room temperature
ovenTemp:	ds	2	; Current oven temperature
runTime:	ds	2	; Total running time in seconds
stateTime:	ds	2	; Total running time of the current state
R2S_Temp:	ds	2	; Soak Temperature -- condition from ramp-to-soak --> soak
S_Time:		ds	2	; Soak Time -- condition from soak --> Ramp-to-peak
R2P_Temp:	ds	2	; Reflow Temperature -- condition from Ramp-to-peak --> Reflow
R_Time:		ds	2	; Reflow Time -- condition from Reflow --> cooling
change:		ds	2	; Proposed change
buzz_cnt:	ds	1	; Length of buzz
buzz_loop:	ds	1	; Time to repeat a buzz


	x:   	ds 4
	y:   	ds 4
	bcd: 	ds 5
	term:	ds 4 ; four digits for the terminal access

Cnt_10ms:   ds 1

BSEG
I:		dbit	1	; Idle state flag
R2S:	dbit	1	; Ramp-2-Soak state flag
S:		dbit	1	; Soak state flag
R2P:	dbit	1	; Ramp-2-Peak state flag	
R:		dbit	1	; Reflow state flag
CL:		dbit	1	; Cooling state flag
param:	dbit	2	; Flag used to tracks toggling through params in 'SET' mode
last_param:	dbit 2	; Tracks the previous parameter when toggling
svBit:	dbit	1	; Set bit read from SW17, 1 = save changes, 0 = discard changes
bzBit:	dbit	1
osc:	dbit	1	; Buzz oscillation flag
sendBit:dbit	1	; Flag for sending data/second
pwmBit:	dbit	1	; 0 = 20% 1 = 100%

mf: dbit 1

CSEG

; Look-up table for 7-segment displays
myLUT:
    DB 0C0H, 0F9H, 0A4H, 0B0H, 099H
    DB 092H, 082H, 0F8H, 080H, 090H

IDLE_1:
    DB  'IDLE KEY3 TO RUN',0
IDLE_2:
	DB	' KEY2 TO SET', 0 
SRAMP:
	DB	'SRAMP  ',0
SOAK:
	DB	'SOAK   ',0
PRAMP:
	DB	'PRAMP  ',0
REFLOW:
	DB	'REFLOW ',0
COOL: 
	DB	'COOL   ',0
GLOBAL:
	DB	'GBL    ',0
	
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
	lcall 	Wait40us
	djnz 	R1, clear_loop

	pop 	AR2
	pop 	AR1
	pop 	AR0
	pop 	psw
	pop 	acc
	ret
	
;---------------------------------------------------
; Clear the LEDs
;---------------------------------------------------
Clear_LEDs:
	mov		a, #0FFH
	mov 	HEX7, a
	mov 	HEX6, a
	mov 	HEX5, a
	mov 	HEX4, a
	mov 	HEX3, a
	mov 	HEX2, a
	mov 	HEX1, a
	mov 	HEX0, a
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
	lcall 	Wait40us
	
	pop 	AR2
	pop 	AR1
	pop 	AR0
	pop 	psw
	pop 	acc
	ret
	
;---------------------------------------------------
; Clear all the state flags
;---------------------------------------------------
clear_flags:
	clr		I
	clr		R2S
	clr		S
	clr		R2P
	clr		R
	clr		CL
	clr		osc
	setb	bzBit
	clr		pwmBit
	ret

;---------------------------------------------------
; Put a constant-zero-terminated string on the LCD screen
;---------------------------------------------------
SendString:
    clr 	a
    movc 	a, @a+dptr
    jz 		Send_done
    lcall 	LCD_put
    inc 	dptr
    sjmp 	SendString
Send_done:
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
; Sets a to 0 if > 0x9
;--------------------------------------------------- 
check_bound:
	cjne	a, #0AH, check_c
	sjmp	bound_error
check_c:
	jnc		bound_error
	ret
bound_error:
	clr		a
	clr		svBit
	ret
  
;---------------------------------------------------
; Loops the command in a R0 times
;---------------------------------------------------    
loop_command:
	push 	acc
	push 	psw
	push 	AR0
	push 	AR1
	push 	AR2
	
comm_loop:
	lcall	LCD_command
	djnz	R0, comm_loop
	
	pop 	AR2
	pop 	AR1
	pop 	AR0
	pop 	psw
	pop 	acc
	ret

;---------------------------------------------------
; Display temperature or time stored in R1 and R0 
; on the LCD screen. c = 1, temperature; c = 0, time
;---------------------------------------------------	
time_temp:	
	push 	acc
	push 	psw
	push 	AR0
	push 	AR1
	push 	AR2
	
	mov		a, R1
	anl		a, #0FH
	orl		a, #30H
	lcall	LCD_put
	
	mov		a, R0
	swap	a
	anl		a, #0FH
	orl		a, #30H
	lcall	LCD_put
	
	mov		a, R0
	anl		a, #0FH
	orl		a, #30H
	lcall	LCD_put
	
	jnc		LCD_time
	mov		a, #'C'
	sjmp	LCD_temp
LCD_time:
	mov		a, #'s'
LCD_temp:
	lcall	LCD_put
	
	pop 	AR2
	pop 	AR1
	pop 	AR0
	pop 	psw
	pop 	acc
    ret		
   
$LIST