$MODDE2

$include (helper.asm)

LCD_Init:
    ; Turn LCD on, and wait a bit.
    setb LCD_ON
    clr LCD_EN  ; Default state of enable must be zero
    lcall Wait40us
    
    mov LCD_MOD, #0xff ; Use LCD_DATA as output port
    clr 	LCD_RW ;  Only writing to the LCD in this code.
	
	mov 	a, #0ch ; Display on command
	lcall 	LCD_command
	mov 	a, #38H ; 8-bits interface, 2 lines, 5x7 characters
	lcall 	LCD_command
	lcall	clear_LCD
	ret 
	
I_set:
	lcall	clear_LCD
	lcall	clear_flags
	setb	I
I_state:
    mov		a, Line1
    lcall	LCD_command
    
    mov		dptr, #IDLE_1
	lcall 	SendString
	
    mov 	a, Line2
	lcall 	LCD_command
	
	mov 	a, Right1
	lcall 	LCD_command
	
	mov		a, roomTemp
	swap	a
	anl		a, #0FH
	orl		a, #30H
	lcall	LCD_put
	
	mov		a, roomTemp
	anl		a, #0FH
	orl		a, #30H
	lcall	LCD_put
	
	mov		dptr, #IDLE_2
	lcall 	SendString
	ret
	
R2S_set:
	lcall	clear_LCD
	lcall	clear_flags
	setb	R2S
R2S_state:
    mov		a, Line1
    lcall	LCD_command
    
    mov		dptr, #GLOBAL
	lcall 	SendString
	
	mov 	a, Right1
	lcall 	LCD_command
	
	mov		a, ovenTemp+1
	anl		a, #0FH
	orl		a, #30H
	lcall	LCD_put
	
	mov		a, ovenTemp+0
	swap	a
	anl		a, #0FH
	orl		a, #30H
	lcall	LCD_put
	
	mov		a, ovenTemp+0
	anl		a, #0FH
	orl		a, #30H
	lcall	LCD_put
	
	mov		a, #'C'
	lcall	LCD_put
	
	mov		a, Right1
	lcall	LCD_command
	
	mov		dptr, #TIME
	lcall	SendString
	
	mov 	a, Line2
	lcall 	LCD_command
	
	mov		dptr, #SRAMP
	lcall 	SendString
	
	mov		a, R2S_Temp+1
	anl		a, #0FH
	orl		a, #30H
	lcall	LCD_put
	
	mov		a, R2S_Temp+0
	swap	a
	anl		a, #0FH
	orl		a, #30H
	lcall	LCD_put
	
	mov		a, R2S_Temp+0
	anl		a, #0FH
	orl		a, #30H
	lcall	LCD_put
	
	mov		a, #'C'
	lcall	LCD_put
	
	mov		a, Right1
	lcall	LCD_command
	
	mov		dptr, #TIME
	lcall	SendString
	
	ret
	
S_set:
	lcall	clear_LCD
	lcall	clear_flags
	setb	S
S_state:
    mov		a, Line1
    lcall	LCD_command
    
    mov		dptr, #GLOBAL
	lcall 	SendString
	
	mov 	a, Right1
	lcall 	LCD_command
	
	mov		a, ovenTemp+1
	anl		a, #0FH
	orl		a, #30H
	lcall	LCD_put
	
	mov		a, ovenTemp+0
	swap	a
	anl		a, #0FH
	orl		a, #30H
	lcall	LCD_put
	
	mov		a, ovenTemp+0
	anl		a, #0FH
	orl		a, #30H
	lcall	LCD_put
	
	mov		a, #'C'
	lcall	LCD_put
	
	mov		a, Right1
	lcall	LCD_command
	
	mov		dptr, #TIME
	lcall	SendString
	
	mov 	a, Line2
	lcall 	LCD_command
	
	mov		dptr, #SRAMP
	lcall 	SendString
	
	mov		a, R2S_Temp+1
	anl		a, #0FH
	orl		a, #30H
	lcall	LCD_put
	
	mov		a, R2S_Temp+0
	swap	a
	anl		a, #0FH
	orl		a, #30H
	lcall	LCD_put
	
	mov		a, R2S_Temp+0
	anl		a, #0FH
	orl		a, #30H
	lcall	LCD_put
	
	mov		a, #'C'
	lcall	LCD_put
	
	mov		a, Right1
	lcall	LCD_command
	
	mov		dptr, #TIME
	lcall	SendString
	ret
	
R2P_set:
	lcall	clear_LCD
	lcall	clear_flags
	setb	R2P
	ret
	
R_set:
	lcall	clear_LCD
	lcall	clear_flags
	setb	R
	ret
	
CL_set:
	lcall	clear_LCD
	lcall	clear_flags
	setb	CL
	ret	
	
MyProgram:
	mov 	sp, #07FH
	clr 	a
	mov 	LEDG,  a
	mov 	LEDRA, a
	mov 	LEDRB, a
	mov 	LEDRC, a
	
	mov		roomTemp, #23H
	mov		ovenTemp+1, #01H
	mov		ovenTemp+0, #00H
	mov		R2S_Temp+1, #01H
	mov		R2S_Temp+0, #50H
	
    lcall 	LCD_Init
    lcall	I_set
Main_loop:
	;lcall state_idle_check
	jb 		KEY.3, Main_loop
	jnb		KEY.3, $
	lcall	R2S_set
	;lcall state_R2S_set
Main_R2S:
	;lcall state_R2S_check
	jnb		KEY.1, Main_reset
	jb 		KEY.3, Main_R2S
	jnb		KEY.1, $
	;jnb go, M_st_R2S
	;lcall state_soak_set
M_st_soak:
	;lcall state_soak_check
	;jb reset, M_done
	;jnb go, M_st_soak
	;lcall state_R2P_set
M_st_R2P:
	;lcall state_R2P_check
	;jb reset, M_done
	;jnb go, M_st_R2P
	;lcall state_reflow_set
M_st_reflow:
	;lcall state_reflow_check
	;jb reset, M_done
	;jnb go, M_st_cool
	;lcall state_cool_set
M_st_cool:
	;lcall state_cool_check
	;jnb go, M_st_cool
	;lcall lcd_open_door
Main_reset:
	jnb		KEY.1, $
	lcall	I_set
	;lcall reset_all_value
	ljmp Main_loop
END    