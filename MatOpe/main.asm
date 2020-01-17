;
; MatOpe.asm
; v1.0
;
; Created: 11.10.2019 12:18:23
; Author : robhaka016
; pslib
;



; Replace with your application code
;start:
;    inc r16
;    rjmp start

	.INCLUDE "m64def.inc" ; vloení definièního souboru pro ATmega64

.DEVICE ATMEGA64	; typ procesoru

.DEF pocet = R12	; pojmenování registrù
.DEF oper1 = R3		; cislo1
.DEF oper2 = R4		; cislo2
.DEF temp = R5		; pomocny
.DEF res = R6		; vysledek
.DEF resH = R7		;vysledek horni B
.DEF nasobL = R8
.DEF nasobH = R9



.EQU FREQ = 16000000	; definice frekvence krystalu
.EQU TLAC = PORTD		; alternativní pojmenování IO registru (pozdìji nelze zmìnit)

.SET DISP = 0x20		; pøiøazení jména hodnotì (lze pozdìji pøedefinovat)

.DSEG	; pamì dat
;.ORG 0x200				; urèení umístìní v pamìti 

; cislo1, cislo2, soucet, rozdil, podil, zbytek 

	cislo1:	.BYTE 1
	cislo2:	.BYTE 1
	soucet:	.BYTE 1
	rozdil:	.BYTE 1
	soucin: .BYTE 2	; high/HIGH/BYTE2(soucin), low/LOW/BYTE1(soucin)
	podil:	.BYTE 1
	zbytek:	.BYTE 1

;.EQU cislo1 = SRAM_START
;.EQU cislo2 = SRAM_START + 1

.ESEG	; pamì EEPROM pro data
		.DB 0x3F; ulozeni konstant do pameti EEPROM

.MACRO     SUBI16               ; Start macro definition
	subi    @1,low(@0)    ; Subtract low byte
	sbci    @2,high(@0)   ; Subtract high byte
.ENDMACRO

;SUBI16 0x1234,r16,r17

.CSEG	; pamì programu
.ORG 0x0000	; umístìní následujích instrukcí v pamìti programu
	
	LDS oper1, cislo1 ;oper1 <- cislo1
	LDS oper2, cislo2 ;oper2 <- cislo2

	;soucet = cislo1 + cislo2
	MOV res, oper1 ;res<-oper1
	ADD res, oper2 ;res<-res + oper2
	STS soucet, res ;soucet<-res

;rozdil = cislo1 - cislo2
	MOV res, oper1 ;res<-oper1
	SUB res, oper2	;res<-res – oper2
	STS rozdil, res  ;rozdil<-res

	



	NOP
; hlavní smyèka
Main:			; LABEL, návìstí, pojmenovaná adresa v pamìti programu

	JMP Main	; nepodmínìnı skok na Main


table:	.DW	2, 0xAB, 0b1011	; tabulka (2B) konstant umístìná v pamìti programu

.EXIT	; konec pøekladu

cislo1<-res
;nasobH:nasobL = cislo1 * cislo2
R1:R0<-oper1 * oper2
soucin<-R0
soucin+1<-R1
 
;nasobH:nasobL = cislo1 * cislo2 opakovanym scitanim
	res<-0
	resH<-0
     pocet<-oper2

cykl0:
	res<-res+oper1
	kdyz STATUS<C>=0 jdi na za_soucet
	resH<-resH+1
za_soucet:
	pocet<-pocet-1
	kdyz pocet!=0 jdi na cykl0
	soucin<-res
     soucin+1<-resH
;podil = cislo1 / cislo2, zbytek = cislo1 % cislo2 opakovanym odcitanim
	res<-oper1
	pocet<-0
cykl01:
	res<-res-oper2
	kdyz STATUS<N>=1 skok na konec
     pocet<-pocet+1
	nepodmineny skok na cykl01
konec:
	res<-res+oper2
	zbytek<-res
	podil<-pocet
;nasobH:nasobL = cislo1 * cislo2 pomoci rotace operandu a vysledku
	pocet<-8
	nasobH<-0
cykl02:
	rotace oper2 vpravo (pres C)
	kdyz STATUS<C>=0 skok na za_soucet2
	nasobH?nasobH+oper1
za_soucet2:
     rotace nasobH vpravo (pres C)
	rotace nasobL vpravo (pres C)
	pocet<-pocet-1
	kdyz pocet!=0 skok na cykl02
     soucin<-nasobL
     soucin+1<-nasobH
;podil = cislo1 / cislo2, zbytek = cislo1 % cislo2 pomoci rotace delitele a odecitanim s navratem
	pocet<-0
	STATUS<C><-0
cykl03:
	pocet<-pocet+1
	rotace oper2 vlevo (prec C)
	kdyz STATUS<C>=0 skok na cykl03
	rotace oper2 vpravo (pres C)
	res<-oper1
     resH<-0
cykl04:
	res<-res-oper2
     STATUS<C> <- 1
     kdyz STATUS<N>=1 tak STATUS<C> <- 0
	rotace resH vlevo (pres C)
	kdyz STATUS<N>=1 skok na za_soucet2
	res<-res+oper2
za_soucet2:
	STATUS<C><-0
	rotace oper2 vpravo (pres C)
	pocet<-pocet-1
	kdyz pocet!=0 skok na cykl4
	podil<-resH
	zbytek<-res
; dekadicka korekce cislo1
     res<-cislo1
	res<-res+0x06
	kdyz STATUS<H>=1 skok na preskoc1
	oper1<-oper1-0x06
preskoc1:
	oper1<-oper1+0x60
	kdyz STATUS<C>=1 preskoc2
	res<-res-0x60
preskoc2:
