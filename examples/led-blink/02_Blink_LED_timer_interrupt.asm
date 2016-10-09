;*******************************************************************************
;*                        02 Blink LED Example                                 *
;* This example work with timer interrupt to create blink delay                *
;* LED Status switch. PIC will drive at 2 Mhz = 2 uS per Cycle                 *
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
;       Pin connection
;-------------------------------------------------------------------------------
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


INTCON          EQU H'00b'          ; Bank 0
PORTA           EQU H'00C'          ; Bank 0
PIR1            EQU H'011'          ; Bank 0
TMR2            EQU H'01a'          ; Bank 0
PR2             EQU H'01b'          ; Bank 0
T2CON           EQU H'01c'          ; Bank 0
TRISA           EQU H'08c'          ; Bank 1
PIE1            EQU H'091'          ; Bank 1
PIE2            EQU H'092'          ; Bank 1
OSCCON          EQU H'099'          ; Bank 1
LATA            EQU H'10C'          ; Bank 2
ANSELA          EQU H'18c'          ; Bank 3

;----- Register Function Bits --------------------------------------------------
TMR2IE          EQU D'1'            ; Timer2 Interrupt enable
TMR2IF          EQU D'1'            ; Timer2 Interrupt flag
TMR2ON          EQU D'2'            ; Timer2 on/off

;----- PORTA Bits --------------------------------------------------------------
RA2             EQU D'2'


;===============================================================================
;       Configuration
;===============================================================================

            org 000H                    ; After reset start here
            goto setIntOsc              ; Startover to init
            org 004H                        ; an interrupt redirects this adress
            goto ir_main

;-------------------------------------------------------------------------------
;       Init
;-------------------------------------------------------------------------------

setIntOsc   movlb 1                     ; Select BANK 1
            movlw B'11100000'           ; Set intern Osc to 2Mhz
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

initTimer   movlb 0                     ; Select BANK 0
            movlw B'01111011'           ; Postscaler 1:16, Prescaler 1:64, T2 OFF
            movwf T2CON
            clrf TMR2                   ; Start Timer from zero
            movlw D'250'                ; Counter overflow after 250 pulses
            movwf PR2

initIRQ     movlb 1                     ; Select BANK 1
            clrf PIE1                   ; Disable all interrupt sources
            clrf PIE2
            bsf PIE1, TMR2IE            ; Enable Timer 2 IRQ
            movlb 0                     ; Select BANK 0
            movlw B'11000000'           ; Enable interrupt global
            movwf INTCON

            ; Start Timer2
            bsf T2CON, TMR2ON

;-------------------------------------------------------------------------------
;       Main Loop
;-------------------------------------------------------------------------------

; Main loop do nothing than loop around and wait for timer interrupt
main        nop
            goto main                   ; Endless main loooooooop


;-------------------------------------------------------------------------------
;       Interrupt Routines
;-------------------------------------------------------------------------------

; LED Switch interrupt routine
; Bit GIE of INTCON is cleared in HW
ir_main     movlb 0                     ; Select BANK 0
            btfsc PORTA, RA2            ; Skip if port clear
            goto ledsetlow
            bsf PORTA, RA2              ; Set output high
            goto end_ir
ledsetlow   bcf PORTA, RA2              ; Set Output low

            ; Clear interrupt source for next run
end_ir      clrf TMR2                   ; Start timer from zero
            bcf PIR1, TMR2IF            ; Clear timer 2 interrupt flag
            retfie                      ; Sets bit GIE of INTCON too

;XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
                                END
