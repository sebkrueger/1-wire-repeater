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

STATUS          EQU H'003'          ; Bank 0
INTCON          EQU H'00b'          ; Bank 0
PORTA           EQU H'00C'          ; Bank 0 - Port A
PIR1            EQU H'011'          ; Bank 0
TMR0            EQU H'015'          ; Bank 0 - Timer 0
TMR1L           EQU H'016'          ; Bank 0
TMR1H           EQU H'017'          ; Bank 0
T1CON           EQU H'018'          ; Bank 0
T1GCON          EQU H'019'          ; Bank 0
TRISA           EQU H'08c'          ; Bank 1 - I/O Contol
PIE1            EQU H'091'          ; Bank 1
PIE2            EQU H'092'          ; Bank 1
OPTION_REG      EQU H'095'          ; Bank 1
OSCCON          EQU H'099'          ; Bank 1
LATA            EQU H'10C'          ; Bank 2
ANSELA          EQU H'18c'          ; Bank 3
WPUA            EQU H'20c'          ; Bank 4

;----- Register Function Bits --------------------------------------------------
C               EQU D'0'            ; Carry bit
DC              EQU D'1'            ;
Z               EQU D'2'            ; Zero bit
WPUEN           EQU D'7'            ; Weak-Pull-up enable (in OPTION Reg)
WPUEA0          EQU D'0'            ; Weak-Pull-up bit RA2
WPUEA2          EQU D'2'            ; Weak-Pull-up bit RA2
INTEDG          EQU D'6'            ; Interrupt edge select (in OPTION Reg)
INTF            EQU D'1'            ; External Interrupt flag (in INTCON Reg)
PSA             EQU D'3'            ; Prescaler assignment TMR 0 (in OPTION Reg)
TMR0CS          EQU D'5'            ; Timer 0 Clock Source (in OPTION Reg)
TMR0IF          EQU D'2'            ; Timer 0 overflow (in INTCON Reg)
TMR0IE          EQU D'5'            ; Timer 0 enable (in INTCON Reg)

;----- PORTA Bits --------------------------------------------------------------
RA0             EQU D'0'
RA2             EQU D'2'

;===============================================================================
;       Variable Definitions (common ram)
;===============================================================================

I               EQU H'0070'          ; loop var in common ram

RH_INT          EQU H'0071'          ; Integer value of Rel. Humidity (8 Bit)
RH_DECIMAL      EQU H'0072'          ; Decimal value of Rel. Humidity (8 Bit)
T_INT           EQU H'0073'          ; Integer value of Temperature (8 Bit)
T_DECIMAL       EQU H'0074'          ; Decimal value of Temperature (8 Bit)
CHC_RH_T        EQU H'0075'          ; 8 Bit Checksum add of H75-H78

PISTATE         EQU H'0076'          ; Pi side status
DHTSTATE        EQU H'0077'          ; DHT22 side status
BITCOUNTER_TX   EQU H'0078'          ; Count the number of send bits
BITCOUNTER_RX   EQU H'0079'          ; Count the number of received bits

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

resetstate  clrf PISTATE                ; Reset PI Status
            clrf DHTSTATE               ; Reset DHT22 Status

initTimer0  movlb 1                     ; Select BANK 1
            bcf OPTION_REG, PSA         ; Use the prescaler of Timer 0
            bcf OPTION_REG, TMR0CS      ; Use intern clock source for T0
            bsf OPTION_REG, D'0'        ; Prescaler Timer 0 to  1:64
            bcf OPTION_REG, D'1'        ; that mean 1 bit = 64 uS
            bsf OPTION_REG, D'2'

initTestVal movlw D'70'                 ; Write Test values to RAM
            movwf RH_INT
            movlw D'5'
            movwf RH_DECIMAL
            movlw D'25'
            movwf T_INT
            movlw D'34'
            movwf T_DECIMAL
            movlw D'134'                ; Checksum
            movwf CHC_RH_T

initIRQ     movlb 1                     ; Select BANK 1
            clrf PIE1                   ; Disable all interrupt sources
            clrf PIE2
            bcf OPTION_REG, INTEDG      ; Interrupt on falling edge
            movlb 0                     ; Select BANK 0
            movlw B'10010000'           ; Enable interrupt global (GIE)
            movwf INTCON                ; and INTE, set no IRQ on timers

;-------------------------------------------------------------------------------
;       Main Loop
;-------------------------------------------------------------------------------

; Main loop do nothing than loop around and wait for interrupts
main        nop
            goto main                   ; Endless main loooooooop

;-------------------------------------------------------------------------------
;       Interrupt Routines
;-------------------------------------------------------------------------------

; Bit GIE of INTCON is cleared in HW
ir_main     movlb 0                     ; Select BANK 0
            btfsc INTCON, INTF          ; Test for extern IRQ
            goto ext_ir                 ; Interrupt on extern pin
            btfsc INTCON, TMR0IF        ; Test for Timer 0 IRQ
            goto tmr0send               ; Send bits out
            goto errorcase              ; no interrupt source match = Error!!

; --------- handling when interrupt on extern pin start here -------------------
ext_ir      movf PISTATE, 0             ; move pistate to w
            xorlw B'00000000'           ; Test if State is zero ("start")
            btfsc STATUS, Z             ; compare don't match -> skip next goto
            goto extcommstart           ; We start in pi side with communication
            movf PISTATE, 0             ; move pistate to w
            xorlw B'00000001'           ; Test if State is 1 ("send")
            btfsc STATUS, Z             ; compare don't match -> skip next goto
            goto extcommsend            ; We set pi side to send mode
            ; Test for more states here, if needed

            goto errorcase              ; no PISTATE match = Error!!
;----------- pi state code start here ------------------------------------------
            ; --- Extern IRQ detect communication start code
extcommstart
            movlb 0                     ; Select BANK 0
            clrf TMR0                   ; Set timer 0 to zero
            bcf INTCON, TMR0IF          ; reset timer 0 overflow bit
            movlb 1                     ; Select BANK 1
            bsf OPTION_REG, INTEDG      ; set interrupt on raising edge
            movlw B'00000001'           ; Set PIstate to next level
            movwf PISTATE
            movlb 0                     ; Select BANK 0
            bcf INTCON, INTF            ; Clear external interrupt flag
            retfie                      ; Sets bit GIE of INTCON too

            ;--- Extern IRQ switch to send code
extcommsend                             ; we expect more then 150(~10ms) in TMR0
            movlb 0                     ; Select BANK 0
            btfsc INTCON, TMR0IF        ; check Timer 0 overflow bit
            goto errorcase              ; upps t0 overflow - far more than 10ms
            movf TMR0, 0                ; Timer 0 count to W
            sublw D'180'                ; Check if W smaller than 180
            btfsc STATUS, C             ; C bit is set (W<=k) -> skip next goto
            goto errorcase              ; Time has to been to long = Error!!
            sublw D'30'                 ; Check if W has been greater than 150
            btfsc STATUS, C             ; W should't be grater than 30 (180-150)
            goto errorcase              ; Time has to been to short = Error!!
            ; No timing error we go to send mode :)
            movlw B'00000010'           ; Set PIstate to next level
            movwf PISTATE
            movlb 1                     ; Select BANK 1
            bsf OPTION_REG, D'0'        ; Prescaler Timer 0 to 1:16
            bsf OPTION_REG, D'1'        ; that mean 1 bit = 16 uS
            bcf OPTION_REG, D'2'
            movlw D'179'                ; Timer 0 to 0,500 ms
            movwf TMR0                  ; 76 step to TMR0 IRQ
            bsf TRISA,RA2               ; set RA2 as output
            movlb 0                     ; Select BANK 0
            bsf PORTA,RA2               ; set RA2 high
            clrf BITCOUNTER_TX          ; Reset sendbitcounter
            bcf INTCON, TMR0IF          ; reset timer 0 overflow bit
            bsf INTCON, TMR0IE          ; Enable TMR0 interrupt
            retfie                      ; Sets bit GIE of INTCON too

            ; --- Timer0 send code
tmr0send    movf BITCOUNTER_TX, 0       ; Check Bitcounter
            btfsc STATUS, Z             ; Bitcounter is zero
            goto sendstart              ; Send start

            ; For now end here with pi communication
            ; Later switch to bit send routine
            reset                       ; easy way for now!
            retfie

sendstart   movlb 2                     ; Select BANK 2
            btfsc LATA,RA2              ; check output state high
            goto sendstartlow
            movlb 0                     ; Select BANK 0
            bsf PORTA,RA2               ; set RA2 high
            movlw D'1'
            movwf BITCOUNTER_TX         ; Switch sendmode to first bit
            goto sendstarttmr
sendstartlow
            movlb 0                     ; Select BANK 0
            bcf PORTA,RA2               ; set RA2 low
sendstarttmr                            ; init timer for next run
            movlw D'55'                 ; Timer 0 to 1,600 ms
            movwf TMR0                  ; 200 step to TMR0 IRQ
            bcf INTCON, TMR0IF          ; reset timer 0 overflow bit
            bsf INTCON, TMR0IE          ; Enable TMR0 interrupt
            retfie                      ; Sets bit GIE of INTCON too

;---------- error routine start here -------------------------------------------
errorcase   reset                       ; not sure for now, what to do here
                                        ; reset?

;XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
                                END