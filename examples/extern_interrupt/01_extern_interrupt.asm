;*******************************************************************************
;*                        01 Extern Interrupt                                  *
;* This example work with extern interrupt on button click to                  *
;* switch LED Status. PIC will drive at 4 Mhz = 1 uS per Cycle                 *
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
;RA0 --> LED
;RA1 --> N/C
;RA2 --> Button (intern pull-up)
;RA3 --> N/C
;RA4 --> N/C
;RA5 --> N/C
;-------------------------------------------------------------------------------

;===============================================================================
;       Register Definitions
;===============================================================================
INTCON      EQU H'00b'                  ; Bank 0
PORTA       EQU H'00C'                  ; Bank 0
PIR1        EQU H'011'                  ; Bank 0
TRISA       EQU H'08c'                  ; Bank 1
PIE1        EQU H'091'                  ; Bank 1
PIE2        EQU H'092'                  ; Bank 1
OPTION_REG  EQU H'095'                  ; Bank 1
OSCCON      EQU H'099'                  ; Bank 1
LATA        EQU H'10C'                  ; Bank 2
ANSELA      EQU H'18c'                  ; Bank 3
WPUA        EQU H'20c'                  ; Bank 4

;----- Register Function Bits --------------------------------------------------
WPUEN       EQU D'7'                    ; Weak-Pull-up enable
WPUEA2      EQU D'2'                    ; Weak-Pull-up bit RA2
INTEDG      EQU D'6'                    ; Interrupt edge select
INTF        EQU D'1'                    ; External Interrupt flag


;----- PORTA Bits --------------------------------------------------------------
RA0         EQU D'0'
RA2         EQU D'2'

;===============================================================================
;       Variable Definitions
;===============================================================================

I           EQU  H'0070'                ; loop var in common ram

;===============================================================================
;       Configuration
;===============================================================================

            org 000H                    ; After reset start here
            goto setIntOsc              ; Startover to init
            org 004H                    ; an interrupt redirects this adress
            goto ir_main

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
            movlw B'00111110'           ; Set RA<5:1> as inputs
            movwf TRISA                 ; and set RA0 as output
            bcf OPTION_REG, WPUEN       ; Enable individual weak pull-ups
            movlb 4                     ; Select BANK 4
            bsf WPUEN, WPUEA2           ; Enable weak pull-up on RA2

initIRQ     movlb 1                     ; Select BANK 1
            clrf PIE1                   ; Disable all interrupt sources
            clrf PIE2
            bcf OPTION_REG, INTEDG      ; Interrupt on falling edge
            movlb 0                     ; Select BANK 0
            movlw B'10010000'           ; Enable interrupt global (GIE)
            movwf INTCON                ; and INTE


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
            btfsc PORTA, RA0            ; Skip if port clear
            goto ledsetlow
            bsf PORTA, RA0              ; Set output high
            goto debounce
ledsetlow   bcf PORTA, RA0              ; Set Output low

            ; Wait to debounce button first
debounce    movlw D'251'                ; 250 us
            movwf I
loopi       decfsz I, 1                 ; --J and result back to J
            goto delay                  ; make some more delay
            goto buttondown             ; loop end go to button-up check
delay       nop                         ; with this nop's
            nop                         ; inner loop make 2,5 ms delay
            nop
            nop
            nop
            nop
            nop
            goto loopi                  ; go back to loop start after delay

            ; Wait until button is raised an RA2 go high
buttondown  btfss PORTA, RA2
            goto buttondown

            ; Clear interrupt source for next run
end_ir      bcf INTCON, INTF            ; Clear external interrupt flag
            retfie                      ; Sets bit GIE of INTCON too

;XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
                                END