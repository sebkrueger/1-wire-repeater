;*******************************************************************************
;*                        1-wire-repeater                                      *
;* Slow down 1-wire signal from DHT22 and send it to raspberry pi host         *
;* The slow down factor is experimental. Now 20x                               *
;* PIC will drive at 4 Mhz = 1 uS per Cycle                                    *
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
;RA0 --> DHT22 (intern pull-up)
;RA1 --> N/C
;RA2 --> Rasp-Pi (intern pull-up)
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
TRISA           EQU H'08c'          ; Bank 1
PIE1            EQU H'091'          ; Bank 1
PIE2            EQU H'092'          ; Bank 1
OPTION_REG      EQU H'095'          ; Bank 1
OSCCON          EQU H'099'          ; Bank 1
LATA            EQU H'10C'          ; Bank 2
ANSELA          EQU H'18c'          ; Bank 3
WPUA            EQU H'20c'          ; Bank 4

;----- Register Function Bits --------------------------------------------------
WPUEN           EQU D'7'            ; Weak-Pull-up enable
WPUEA0          EQU D'0'            ; Weak-Pull-up bit RA2
WPUEA2          EQU D'2'            ; Weak-Pull-up bit RA2
INTEDG          EQU D'6'            ; Interrupt edge select
INTF            EQU D'1'            ; External Interrupt flag

;----- PORTA Bits --------------------------------------------------------------
RA0             EQU D'0'
RA2             EQU D'2'

;===============================================================================
;       Variable Definitions (common ram)
;===============================================================================

I               EQU H'0070'          ; loop var in common ram

RH_INT          EQU H'0075'          ; Integer value of Rel. Humidity (8 Bit)
RH_DECIMAL      EQU H'0076'          ; Decimal value of Rel. Humidity (8 Bit)
T_INT           EQU H'0077'          ; Integer value of Temperature (8 Bit)
T_DECIMAL       EQU H'0078'          ; Decimal value of Temperature (8 Bit)
CHC_RH_T        EQU H'0089'          ; 8 Bit Checksum add of H75-H78

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
            clrf LATA                   ; Clear Port latch
            movlb 3                     ; Select BANK 3
            clrf ANSELA                 ; all digital I/O
            movlb 1                     ; Select BANK 1
            movlw B'00111110'           ; Set RA<5:1> as inputs
            movwf TRISA                 ; and set RA0 as output
            bcf OPTION_REG, WPUEN       ; Enable individual weak pull-ups
            movlb 4                     ; Select BANK 4
            bsf WPUEN, WPUEA2           ; Enable weak pull-up on RA2
            bsf WPUEN, WPUEA0           ; Enable weak pull-up on RA0

initTimer1


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

; Bit GIE of INTCON is cleared in HW
ir_main     ;lots of code has to write here

            ; Clear interrupt source for next run
end_ir      bcf INTCON, INTF            ; Clear external interrupt flag
            retfie                      ; Sets bit GIE of INTCON too

;XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
                                END