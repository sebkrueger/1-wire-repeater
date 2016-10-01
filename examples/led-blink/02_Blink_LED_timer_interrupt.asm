;*******************************************************************************
;*                           Blink LED Example                                 *
;*                                 v1.00                                       *
;*******************************************************************************
;*           Hardware: PIC12F1840                                              *
;*           Internal osc and power 3,3 V                                      *
;*******************************************************************************

;===============================================================================
;       Hardware Check
;===============================================================================

IFNDEF __12LF1840
   MESSG "Processor-header file mismatch.  Verify selected processor."
ENDIF

;-------------------------------------------------------------------------------
;Pin connection
;----------------------------------------
;RA0 --> N/C
;RA1 --> N/C
;RA2 --> LED
;RA3 --> N/C
;RA4 --> N/C
;RA5 --> N/C
;-------------------------------------------------------------------------------


;===============================================================================
;       Register Definitions
;===============================================================================

W                EQU  H'0000'
F                EQU  H'0001'

;-----Bank0------------------
INDF0            EQU  H'0000'
INDF1            EQU  H'0001'
PCL              EQU  H'0002'
STATUS           EQU  H'0003'
FSR0             EQU  H'0004'
FSR0L            EQU  H'0004'
FSR0H            EQU  H'0005'
FSR1             EQU  H'0006'
FSR1L            EQU  H'0006'
FSR1H            EQU  H'0007'
BSR              EQU  H'0008'
WREG             EQU  H'0009'
PCLATH           EQU  H'000A'
INTCON           EQU  H'000B'
PORTA            EQU  H'000C'
PIR1             EQU  H'0011'
PIR2             EQU  H'0012'
TMR0             EQU  H'0015'
TMR1             EQU  H'0016'
TMR1L            EQU  H'0016'
TMR1H            EQU  H'0017'
T1CON            EQU  H'0018'
T1GCON           EQU  H'0019'
TMR2             EQU  H'001A'
PR2              EQU  H'001B'
T2CON            EQU  H'001C'
CPSCON0          EQU  H'001E'
CPSCON1          EQU  H'001F'

;----- PORTA Bits -----------------------------------------------------
RA2              EQU  H'0002'

;----- PIE1 Bits -----------------------------------------------------
TMR2IE           EQU  H'0001'  

;===============================================================================
;       Variable Definitions
;===============================================================================

;===============================================================================
;       Configuration
;===============================================================================

      	     __CONFIG        _CONFIG1, B'00000110000100'                        ; int. oscillator and no code protection
             __CONFIG        _CONFIG2, B'01100011111111'                        ;


;-------------------------------------------------------------------------------
;                             Timer Setup
;-------------------------------------------------------------------------------

; Timer setup
timer_init  movlw B'01111011'     			; Prescaler 1:64 / Postscaler 1:16
			movwf T2CON
			clrf TMR2
			movlw D'255'
			movwf PR2                     	; Overflow after 255 timer pulses

; Interrupt setup
			banksel PIE1
			clrf PIE1
			clrf PIE2
			bsf PIE1, TMR2IE              	; Enable timer 2 interrupt
			clrf BSR                      	; select BANK0
			movlw B'11000000'
			movwf INTCON                  	; set global irq on

; Start Timer
			bsf T2CON, D'002'             ; Set TMR2ON bit
			return

;-------------------------------------------------------------------------------
;                             Main Loop
;-------------------------------------------------------------------------------

; Main loop do nothing and wait for timer irq
main 		nop
			goto main
			
;-------------------------------------------------------------------------------
;                             Timer Interrupt
;-------------------------------------------------------------------------------

timer_ir	clrf BSR

;XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
                              END
