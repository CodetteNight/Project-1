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
	
	mov		a, Line1
	lcall	LCD_command
	mov		dptr, #GLOBAL
	lcall	SendString
	mov		R1, OvenTemp+1
	mov		R0, OvenTemp+0	
	setb	c
    lcall	time_temp
    mov		a, Right1
	lcall	LCD_command
	mov		R1, #00H
	mov		R0, #00H
	clr		c
	lcall	time_temp
    
	mov		a, Line2
	lcall	LCD_command
	mov		dptr, #SRAMP
	lcall	SendString
	mov		R1, R2S_Temp+1
	mov		R0, R2S_Temp+0
	setb	c
	lcall	time_temp
	mov		a, Right1
	lcall	LCD_command
	mov		R1, #00H
	mov		R0, #00H
	clr		c
    lcall	time_temp
	ret
	
S_set:
	lcall	clear_flags
	setb	S
	
	mov		a, Line2
	lcall	LCD_command
	mov		dptr, #SOAK
	lcall	SendString
	mov		R1, S_Time+1
	mov		R0, S_Time+0
	clr	c
	lcall	time_temp
	mov		a, Right1
	lcall	LCD_command
	mov		R1, #00H
	mov		R0, #00H	
	clr		c
    lcall	time_temp
	ret
	
R2P_set:
	lcall	clear_flags
	setb	R2P
	
	mov		a, Line2
	lcall	LCD_command
	mov		dptr, #PRAMP
	lcall	SendString
	mov		R1, R2P_Temp+1
	mov		R0, R2P_Temp+0
	setb	c
	lcall	time_temp
	mov		a, Right1
	lcall	LCD_command
	mov		R1, #00H
	mov		R0, #00H	
	clr		c
    lcall	time_temp
	ret
	
R_set:
	lcall	clear_flags
	setb	R
	
	mov		a, Line2
	lcall	LCD_command
	mov		dptr, #REFLOW
	lcall	SendString
	mov		R1, R_Time+1
	mov		R0, R_Time+0
	clr	c
	lcall	time_temp
	mov		a, Right1
	lcall	LCD_command
	mov		R1, #00H
	mov		R0, #00H	
	clr		c
    lcall	time_temp
	ret
	
CL_set:
	lcall	clear_flags
	setb	CL	
	
	mov		a, Line2
	lcall	LCD_command
	mov		dptr, #COOL
	lcall	SendString
	mov		R1, #00H
	mov		R0, #60H
	setb	c
	lcall	time_temp
	mov		a, Right1
	lcall	LCD_command
	mov		R1, #00H
	mov		R0, #00H	
	clr		c
    lcall	time_temp
	ret	
	
params_set:
	jnb		KEY.2, $
	lcall	clear_LCD
	mov		a, Line1
	lcall	LCD_command
	mov		dptr, #SOAK
	lcall	SendString
	mov		R1, R2S_Temp+1
	mov		R0, R2S_Temp+0
	setb	c
	lcall	time_temp
	mov		a, Right1
	lcall	LCD_command
	mov		R1, S_Time+1
	mov		R0, S_Time+0	
	clr		c
    lcall	time_temp
	
	mov		a, Line2
	lcall	LCD_command
	mov		dptr, #REFLOW
	lcall	SendString
	mov		R1, R2P_Temp+1
	mov		R0, R2P_Temp+0
	setb	c
	lcall	time_temp
	mov		a, Right1
	lcall	LCD_command
	mov		R1, R_Time+1
	mov		R0, R_Time+0	
	clr		c
    lcall	time_temp
    
toggle_params:
	mov		last_param, param
	mov		a, param
	jz		Toggle0
	mov		a, param
	cjne	a, #11B, Toggle2
	mov		a, Line2
	lcall	LCD_command
	mov		R0, #11
	mov		a, Right1
	lcall	loop_command
	mov		a, #' '
	lcall	LCD_put
	mov		a, Line1
	ljmp	done_toggle2
Toggle2:
	cjne	a, #10B, Toggle1
	dec		param
	mov		a, Line1
	ljmp	Tmove_star

Toggle1:
	mov		a, Line1
	lcall	LCD_command
	mov		R0, #11
	mov		a, Right1
	lcall	loop_command
	mov		a, #' '
	lcall	LCD_put
	mov		a, Line2
done_toggle2:
	lcall	LCD_command
	mov		R0, #6
	dec		param
	ljmp	done_toggle
	
Toggle0:
	mov		param, #11B
	mov		a, Line2

Tmove_star:
	lcall	LCD_command
	mov		R0, #6
	mov		a, Right1
	lcall	loop_command
	mov		a, #' '
	lcall	LCD_put
	mov		R0, #4
done_toggle:
	mov		a, Right1
	lcall	loop_command
	mov		a, #'*'
	lcall	LCD_put
	ret
	
toggle_update:
	jnb		svBit, done_update
	mov		a, last_param
	cjne	a, #11B, Update2
	mov		a, Line1
	lcall	LCD_command
	mov		R0, #7
	mov		a, Right1
	lcall	loop_command
	mov		R1, R2S_Temp+1
	mov		R0, R2S_Temp+0
	setb	c
	lcall	time_temp
	ljmp	done_update
Update2:
	cjne	a, #10B, Update1
	mov		a, Line1
	lcall	LCD_command
	mov		R0, #12
	mov		a, Right1
	lcall	loop_command
	mov		R1, R2S_Temp+1
	mov		R0, R2S_Temp+0
	clr		c
	lcall	time_temp
	ljmp	done_update
Update1:
	cjne	a, #01B, Update0
	mov		a, Line2
	lcall	LCD_command
	mov		R0, #7
	mov		a, Right1
	lcall	loop_command
	mov		R1, R2S_Temp+1
	mov		R0, R2S_Temp+0
	setb	c
	lcall	time_temp
	ljmp	done_update	
Update0:
	mov		a, Line2
	lcall	LCD_command
	mov		R0, #12
	mov		a, Right1
	lcall	loop_command
	mov		R1, R2S_Temp+1
	mov		R0, R2S_Temp+0
	clr		c
	lcall	time_temp
	
done_update:
	ret	
	
Set_save:
	jnb		svBit, done_save
	mov		a, last_param
	cjne	a, #11B, Save2
	mov		R2S_Temp+1, change+1
	mov		R2S_Temp+0, change+0
	ljmp	done_save
Save2:
	cjne	a, #10B, Save1
	mov		S_Time+1, change+1
	mov		S_Time+0, change+0
	ljmp	done_save
Save1:
	cjne	a, #01B, Save0
	mov		R2P_Temp+1, change+1
	mov		R2P_Temp+0, change+0
	ljmp	done_save	
Save0:
	mov		R_Time+1, change+1
	mov		R_Time+0, change+0
done_save:
	ret
	
MyProgram:
	mov 	sp, #07FH
	clr 	a
	mov 	LEDG,  a
	mov 	LEDRA, a
	mov 	LEDRB, a
	mov 	LEDRC, a
	
	mov		last_param, #11B
	mov		param, #11B
	
	; Default Values
	mov		roomTemp, #23H
	mov		ovenTemp+1, #01H
	mov		ovenTemp+0, #00H
	mov		R2S_Temp+1, #01H
	mov		R2S_Temp+0, #50H
	mov		S_Time+1, #00H
	mov		S_Time+0, #60H
	mov		R2P_Temp+1, #02H
	mov		R2P_Temp+0, #20H
	mov		R_Time+1, #00H
	mov		R_Time+0, #45H
	
    lcall 	LCD_Init
    lcall	I_set
    ljmp	Main_loop
Set_toggle:
	jnb		KEY.3, $
	lcall	set_save
	lcall	toggle_update
	lcall	toggle_params
	ljmp	Set_loop
Set_Mode:
	jnb		KEY.2, $
	lcall	params_set
Set_loop:
	jnb		KEY.3, Set_toggle
	
	mov		dptr, #myLUT
	mov		a, SWB
	anl		a, #0FH
	mov		change+1, a
	lcall	check_bound
	movc	a, @a+dptr
	mov		HEX2, a
	
	mov		a, SWA
	mov		change+0, a
	swap	a
	anl		a, #0FH
	lcall	check_bound
	movc	a, @a+dptr
	mov		HEX1, a
	
	mov		a, SWA
	anl		a, #0FH
	lcall	check_bound
	movc	a, @a+dptr
	mov		HEX0, a
	
	mov		a, SWC
	rrc		a
	rrc		a
	mov		svBit, c
	
	jb		KEY.2, Set_loop
	jnb		KEY.2, $
	lcall	Set_save
	mov		param, last_param
	lcall   clear_LEDs
	lcall	I_set
Main_loop:
	jnb		KEY.2, Set_Mode
	jb 		KEY.3, Main_loop
	jnb		KEY.3, $
	lcall	R2S_set
Main_R2S:
	jnb		KEY.1, Main_reset
	; do stuff
	jb 		KEY.3, Main_R2S
	jnb		KEY.3, $
	lcall	S_set
Main_Soak:
	jnb		KEY.1, Main_reset
	; do stuff
	jb 		KEY.3, Main_Soak
	jnb		KEY.3, $
	lcall	R2P_set
Main_R2P:
	jnb		KEY.1, Main_reset
	; do stuff
	jb 		KEY.3, Main_R2P
	jnb		KEY.3, $
	lcall	R_set
Main_Reflow:
	jnb		KEY.1, Main_reset
	; do stuff
	jb 		KEY.3, Main_Reflow
	jnb		KEY.3, $
	lcall	CL_set
Main_cool:
	jnb		KEY.1, Main_reset
	; do stuff
	jb 		KEY.3, Main_cool
	jnb		KEY.3, $
	ljmp	Main_done
Main_reset:
	jnb		KEY.1, $
Main_done:
	lcall	I_set
	ljmp Main_loop
END    