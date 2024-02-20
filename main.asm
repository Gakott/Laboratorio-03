//******************************************************************************
//Universidad del Valle de Guatemala
//Programacion de Microcontroladres 
//Laboratorio_3.asm
//Hardware: ATMega328P
//Author : Fernando Gabriel Caballeros
//Creado: 13/02/2024
//******************************************************************************
//Encabezado
//******************************************************************************

.include "M328PDEF.inc"
.cseg					//INICIO DEL CODIGO
.org 0x00				//RESET
	JMP Main
.org 0x0008				// VECTOR ISR : PCINT1
	JMP ISR_PCINT1
.org 0x0020				// VECTOR ISR : TIMER0_OVF
	JMP ISR_TIMER_OVF0
	
Main:
//******************************************************************************
//STACK
//******************************************************************************
LDI R16, LOW(RAMEND)
OUT SPL, R16 
LDI R17, HIGH(RAMEND)
OUT SPH, R17
//******************************************************************************
//CONFIGURACION
//******************************************************************************
Setup:
	LDI R16, (1 << CLKPCE)
	STS CLKPR, R16 			//HABILITAMOS EL PRESCALER
	LDI R16, 0b0000_0001
	STS CLKPR, R16			//DEFINIMOS UNA FRECUENCIA DE 4MGHz

	LDI R16, 0b0000_0101	//CONFIGURAMOS Y HABILITAMOS LOS PULLUPS en PORTC
	OUT PORTC, R16			

	LDI R16, 0b0001_1000
	OUT DDRC, R16			//CONFIGURAMOS Y HABILITAMOS ENTRADAS Y SALIDAD DEL PUERTO C

	LDI R16, 0xFF
	OUT DDRD, R16			//CONFIGURAMOS Y HABILITAMOS ENTRADAS Y SALIDAD DEL PUERTO D

	LDI R16, 0x2F
	OUT DDRB, R16			//CONFIGURAMOS Y HABILITAMOS ENTRADAS Y SALIDAD DEL PUERTO B

	CLR R16
	LDI R16, (1 << PCIE1)
	STS PCICR, R16			//CONFIGURAMOS PCIE1

	CLR R16
	LDI R16, (1 << PCINT12) | (1 << PCINT13)
	STS PCMSK1, R16			

	CLR R16
	LDI R16, (1 << TOIE0)
	STS TIMSK0, R16			
	//TIMER MODO NORMAL
	CLR R16
	OUT TCCR0A, R16			

	CLR R16
	LDI R16, (1 << CS02)
	OUT TCCR0B, R16			//PRESCALAR 256

	LDI R16, 178			//VALOR CALCULADO PARA SABER DONDE EMPEZAR
	OUT TCNT0, R16

	SEI						//INTERRUPCIONES GLOBALES sIE

	TABLA7SEG: .DB 0x40, 0x79, 0x24, 0x30, 0x19, 0x12, 0x02, 0x78, 0x00, 0x10, 0x08, 0x03, 0x46, 0x21, 0x06, 0x0E 
	
	LDI ZH, HIGH(TABLA7SEG << 1)
	LDI ZL, LOW(TABLA7SEG << 1)
	MOV R25, ZL
	MOV R26, ZL
	LPM R19, Z
	SBRS R19, 0
	CBI	PORTD, PD2
	SBRC R19, 0
	SBI PORTD, PD2
	SBRS R19, 1
	CBI	PORTD, PD3
	SBRC R19, 1
	SBI PORTD, PD3
	SBRS R19, 2
	CBI	PORTD, PD4
	SBRC R19, 2
	SBI PORTD, PD4
	SBRS R19, 3
	CBI	PORTD, PD5
	SBRC R19, 3
	SBI PORTD, PD5
	SBRS R19, 4
	CBI	PORTD, PD6
	SBRC R19, 4
	SBI PORTD, PD6
	SBRS R19, 5
	CBI	PORTD, PD7
	SBRC R19, 5
	SBI PORTD, PD7
	SBRS R19, 6
	CBI	PORTB, PB0
	SBRC R19, 6
	SBI PORTB, PB0

	CLR R17
	CLR R18
	CLR R19
	CLR R20
	CLR R21
	CLR R22
	CLR R23
	CLR R24

	SBI PORTC, PC3
	SBI PORTC, PC4
Loop:
	CLI
	MOV R16, R18
	SUBI R16, 3
	BRBC 2, dec_cont_bi
	MOV R16, R23
	SUBI R16, 3
	BRBC 2, inc_cont_bi
	CPI R20, 1
	BREQ inc_disp
	SEI
	RJMP Loop

//******************************************************************************
//SUB-RUTINAS
//******************************************************************************
//CONTADOR BINARIO
inc_cont_bi:
	INC R17
	CPI R17, 0x10
	BREQ inc_cont
	RJMP leds_cont_bi
inc_cont:
	CLR R17
	RJMP leds_cont_bi

dec_cont_bi: 
	DEC R17
	CPI R17, 0xFF
	BREQ dec_cont
	RJMP leds_cont_bi
dec_cont:
	LDI R17, 0x0F
	RJMP leds_cont_bi

leds_cont_bi:
	SBRS R17, 0
	CBI	PORTB, PB1
	SBRC R17, 0
	SBI PORTB, PB1
	SBRS R17, 1
	CBI	PORTB, PB2
	SBRC R17, 1
	SBI PORTB, PB2
	SBRS R17, 2
	CBI	PORTB, PB3
	SBRC R17, 2
	SBI PORTB, PB3
	SBRS R17, 3
	CBI	PORTB, PB4
	SBRC R17, 3
	SBI PORTB, PB4
	CLR R18
	CLR R23
	RJMP Loop

//DISPLAY
inc_disp:
	SBIS PORTC, PC0
	RJMP decenas
	RJMP unidades

unidades:
	CBI PORTC, PC3
	SBI PORTC, PC4
	MOV ZL, R26
	LPM R19, Z
	RJMP inc_u

decenas:
	SBI PORTC, PC3
	CBI PORTC, PC4
	MOV ZL, R25
	LPM R19, Z
	RJMP inc_d

inc_d:
	CPI R24, 1
	BREQ inc_decenas
	CLR R20
	RJMP leds_display7

inc_decenas:
	CLR R24
	CLR R20
	LDI R16, 178 
	OUT TCNT0, R16

	INC R25
	MOV ZL, R25
	LPM R19, Z
	CPI R19, 0x02
	BREQ reset_d
	MOV ZL, R25
	LPM R19, Z
	RJMP leds_display7

reset_d: 
	LDI R25, LOW(TABLA7SEG << 1)
	MOV ZL, R25
	LPM R19, Z
	RJMP leds_display7

inc_u:
	CPI R22, 60
	BREQ inc_unidades
	INC R22
	CLR R20
	RJMP leds_display7

inc_unidades:
	CLR R22
	CLR R20
	LDI R16, 178 .
	OUT TCNT0, R16

	INC R26
	MOV ZL, R26
	LPM R19, Z
	CPI R19, 0x08
	BREQ reset_u
	MOV ZL, R26
	LPM R19, Z
	RJMP leds_display7

reset_u: //Si llega a F lo resetea para que continue en 0
	LDI R26, LOW(TABLA7SEG << 1)
	MOV ZL, R26
	LPM R19, Z
	INC R24
	RJMP leds_display7


leds_display7: //Muestra el valor del contador en el display
	SBRS R19, 0
	CBI	PORTD, PD2
	SBRC R19, 0
	SBI PORTD, PD2
	SBRS R19, 1
	CBI	PORTD, PD3
	SBRC R19, 1
	SBI PORTD, PD3
	SBRS R19, 2
	CBI	PORTD, PD4
	SBRC R19, 2
	SBI PORTD, PD4
	SBRS R19, 3
	CBI	PORTD, PD5
	SBRC R19, 3
	SBI PORTD, PD5
	SBRS R19, 4
	CBI	PORTD, PD6
	SBRC R19, 4
	SBI PORTD, PD6
	SBRS R19, 5
	CBI	PORTD, PD7
	SBRC R19, 5
	SBI PORTD, PD7
	SBRS R19, 6
	CBI	PORTB, PB0
	SBRC R19, 6
	SBI PORTB, PB0
	RJMP Loop

ISR_PCINT1:

	IN R21, PINC
	SBRS R21, PC0	
	INC R18
	SBRS R21, PC2	
	INC R23
	RETI

ISR_TIMER_OVF0:
	LDI R20, 1
	RETI
	