;*******************************************************************************
;*                        01 Blink LED Example                                 *
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

W               EQU  H'0000'
PORTA           EQU  H'000C'                ; Bank 0 
TRISA           EQU  H'008c'                ; Bank 1
LATA            EQU  H'010C'                ; Bank 2
ANSELA          EQU  H'018c'                ; Bank 3	    
	   
;----- PORTA Bits -----------------------------------------------------
RA2             EQU  H'0002'

;===============================================================================
;       Variable Definitions
;===============================================================================

;===============================================================================
;       Configuration
;===============================================================================

			org 00

;-------------------------------------------------------------------------------
;       Init
;-------------------------------------------------------------------------------
	
initportA   movlb 0             ; Select BANK 0 
			clrf PORTA		    ; Init PORTA
			movlb 2             ; Select BANK 2 
			clrf LATA 
			movlb 3             ; Select BANK 3 
			clrf ANSELA		    ; all digital I/O
			movlb 1             ; Select BANK 1
			movlw B'00111011'	; Set RA<5:3> and RA<1:0> s inputs
			movwf TRISA		    ; and set RA2 as output		
			movlb 0             ; Select BANK 0 
			bsf PORTA, RA2      ; Set Output high 
			
;-------------------------------------------------------------------------------
;       Main Loop
;-------------------------------------------------------------------------------
		
; Main loop do nothing than loop around
main 		nop
			nop
			nop
			call ledswitch
			goto main
			
;-------------------------------------------------------------------------------
;       LED Switch subroutine
ledswitch	movlb 0                     ; Select BANK 0 
			btfsc PORTA, RA2            ; skip if port clear
			goto ledsetlow
			bsf PORTA, RA2              ; set output high
			return
ledsetlow	bcf PORTA, RA2              ; Set Output low
			return
       		
			

;XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
                              END

