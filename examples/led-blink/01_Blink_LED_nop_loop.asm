;*******************************************************************************
;*                        01 Blink LED Example                                 *
;* This example work with loop that create the delay and a subroutine for      *
;* LED Status switch. PIC will drive at 4 Mhz = 1 uS per Cycle                 *
;*                                                                             *
;*                                 v1.00                                       *
;*******************************************************************************
;*           Hardware: PIC12F1840                                              *
;*           Internal osc and power 3,3 V                                      *
;*******************************************************************************

;===============================================================================
;       Hardware Check
;===============================================================================

IFNDEF __12F1840
   MESSG "Processor-header file mismatch.  Verify selected processor."
ENDIF

; CONFIG1
; __CONFIG _CONFIG1, _FOSC_INTOSC & _WDTE_OFF & _PWRTE_OFF & _MCLRE_OFF
;      & _CP_OFF & _CPD_OFF & _BOREN_ON & _CLKOUTEN_OFF & _IESO_ON & _FCMEN_ON
__CONFIG 0x8007, B'1111111110100100'

; CONFIG2
; __CONFIG _CONFIG2, _WRT_OFF & _PLLEN_ON & _STVREN_ON & _BORV_LO & _LVP_ON
__CONFIG 0x8008, B'1111111111111111'

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


PORTA           EQU H'00c'              ; Bank 0
TRISA           EQU H'08c'              ; Bank 1
OSCCON          EQU H'099'              ; Bank 1
LATA            EQU H'10c'              ; Bank 2
ANSELA          EQU H'18c'              ; Bank 3

;----- PORTA Bits -----------------------------------------------------
RA2             EQU D'2'

;===============================================================================
;       Variable Definitions
;===============================================================================

I               EQU H'070'              ; loop var in common ram
J               EQU H'071'              ; loop var in common ram

;===============================================================================
;       Configuration
;===============================================================================

            org 00

;-------------------------------------------------------------------------------
;       Init
;-------------------------------------------------------------------------------

setIntOsc   movlb 1                     ; Select BANK 1
            movlw B'11101000'           ; Set intern Osc to 4Mhz
            movwf OSCCON                ; Store in OSCCON Register

initportA   movlb 0                     ; Select BANK 0
            clrf PORTA                  ; Init PORTA
            movlb 2                     ; Select BANK 2
            clrf LATA
            movlb 3                     ; Select BANK 3
            clrf ANSELA                 ; all digital I/O
            movlb 1                     ; Select BANK 1
            movlw B'00111011'           ; Set RA<5:3> and RA<1:0> s inputs
            movwf TRISA                 ; and set RA2 as output
            movlb 0                     ; Select BANK 0
            bsf PORTA, RA2              ; Set Output high

;-------------------------------------------------------------------------------
;       Main Loop
;-------------------------------------------------------------------------------

; Main loop do nothing than loop around
main        movlw D'250'                ; init counter var I
            movwf I
loopi       decfsz I, 1                 ; --I and result back to I
            goto innerloop              ; until i==0 do inner J loop
            goto switchled              ; outer loop end switch led

innerloop   movlw D'250'                ; init counter var J
            movwf J
loopj       decfsz J, 1                 ; --J and result back to J
            goto delay                  ; make some more delay
            goto loopi                  ; inner loop end go to outer loop
delay       nop                         ; with this nop's
            nop                         ; inner loop make 2,5 ms delay
            nop
            nop
            nop
            nop
            nop
            goto loopj                  ; go back to inner loop after delay

switchled   call ledswitch
            goto main

;-------------------------------------------------------------------------------
;       LED Switch subroutine
ledswitch   movlb 0                     ; Select BANK 0
            btfsc PORTA, RA2            ; skip if port clear
            goto ledsetlow
            bsf PORTA, RA2              ; set output high
            return
ledsetlow   bcf PORTA, RA2              ; Set Output low
            return

;XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
                                END
