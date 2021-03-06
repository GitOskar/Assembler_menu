;KWARC = 11 059 200 LICZBA CYKLI ZEGAROWYCH W CIAGU 1 SEK
; 11 059 200 / 12 = 921 600
;TRYB0 TIMERA = 8BIT
;TRYB1 TIMERA = 16BIT ********
;TRYB2 TIMERA = 32BITY
;TRYB3 TIMERA = 64BITY
;WYBOR TRYBU TMOD BITY?
T0_VAL_POCZ EQU 65535 - 9215
TH0_POCZ EQU T0_VAL_POCZ / 256
TL0_POCZ EQU T0_VAL_POCZ MOD 256
_LICZNIK_PROGRAMOWY DATA 045h
_SEKUNDY DATA 030h
_MINUTY DATA 031h
_GODZINY DATA 032h
_COUNTER DATA 033h
_MSG_1 DATA 034h
_MSG_2 DATA 035h
_MSG_3 DATA 036h
LCDWC  XDATA 0FF80h
LCDWD  XDATA 0FF81h
LCDRC  XDATA 0FF82h
LCDRD  XDATA 0FF83h
CSKB1  XDATA 0FF22h
KBD	   DATA  02Fh
_ENTER	BIT  KBD.7
_ESC	BIT  KBD.6
_UP 	BIT  KBD.4
_DOWN	BIT  KBD.5
_LEFT	BIT  KBD.2
_RIGHT	BIT  KBD.3
_1_LEVEL EQU R3
_2_LEVEL EQU R2
_LOCATION_OF_X EQU R4
_RECIVE_COUNT EQU R1
_RECV_FLG BIT 00h
_SEND_FLG BIT 01h
_RECIVE_MSG_1 DATA 037h
_RECIVE_MSG_2 DATA 038h
_RECIVE_MSG_3 DATA 039h


	ORG 000h
_RESET:
	LJMP _INIT


;--------- PRZERWANIA TIMER -----------------
	ORG 00Bh
_OVRFL:
	
	MOV TH0, #TH0_POCZ
	
	CALL _TIMER_OBSLUGA

RETI

;------------ PRZERWANIA TRANSMISJA ------------

ORG 0023h

_INT_SERIAL:
	JB TI,_INT_SERIAL_TI

_INT_SERIAL_RI:
	
	CALL _TRANSMISJA_OBSLUGA
	
	CLR RI
	SETB _RECV_FLG
	RETI

_INT_SERIAL_TI:

	CLR TI
	SETB _SEND_FLG

RETI

	ORG 0100h
_INIT:
	CALL _TIMER_INIT
	CALL _LCD_INIT
	CALL _MENU_INIT
	CALL _TRANSMISJA_INIT

_PROGRAM:

	;---------------------------------------MENU GLOWNE-----------------------------------
	; MSG - 2        SETTINGS - 1       TEST - 0

		CALL _DISPLAY_MAIN_MENU

		_MAIN_MENU_PREP:
			CALL _WAIT_FOR_ESC

		_MAIN_MENU:

			CALL _POBIERZ_KLAWISZ

			_MAIN_MENU_UP:

				JB _UP, _MAIN_MENU_DOWN
				INC _1_LEVEL
				CJNE _1_LEVEL, #3d, _MAIN_MENU_UP_DALEJ
				MOV _1_LEVEL, #0d

			_MAIN_MENU_UP_DALEJ:
				CALL _DISPLAY_MAIN_MENU
				CALL _WAIT_FOR_UP

			_MAIN_MENU_DOWN:

				JB _DOWN, _MAIN_MENU_ENTER
				CJNE _1_LEVEL, #0d, _MAIN_MENU_DOWN_DEC
				MOV _1_LEVEL, #2d
				LJMP _MAIN_MENU_DOWN_DISPLAY

				_MAIN_MENU_DOWN_DEC:
					DEC _1_LEVEL

				_MAIN_MENU_DOWN_DISPLAY:
					CALL _DISPLAY_MAIN_MENU
					CALL _WAIT_FOR_DOWN

			_MAIN_MENU_ENTER:

			JB _ENTER, _MAIN_MENU

			;_MAIN_MENU_ENTER_MSG
				CJNE _1_LEVEL, #2d, _MAIN_MENU_ENTER_SETTINGS
				CALL _DISPLAY_MSG
				LJMP _MSG_PREP

			_MAIN_MENU_ENTER_SETTINGS:
				CJNE _1_LEVEL, #1d, _MAIN_MENU_ENTER_TEST
				CALL _DISPLAY_SETTINGS
				LJMP _SETTINGS_PREP

			_MAIN_MENU_ENTER_TEST:
				CALL _DISPLAY_TEST
				LJMP _TEST_PREP


		;-------------------------------- MSG ----------------------------------------------		

		_MSG_PREP:

			CALL _WAIT_FOR_ENTER

		_MSG:

			CALL _POBIERZ_KLAWISZ

		;_MSG_UP:

			JB _UP, _MSG_DOWN
			CJNE _2_LEVEL, #1d, _MSG_UP_TO_1
			MOV _2_LEVEL, #0d
			LJMP _MSG_UP_DALEJ

			_MSG_UP_TO_1:
				MOV _2_LEVEL, #1d

			_MSG_UP_DALEJ:
				CALL _DISPLAY_MSG
				CALL _WAIT_FOR_UP

		_MSG_DOWN:

			JB _DOWN, _MSG_ESC
			CJNE _2_LEVEL, #1d, _MSG_DOWN_TO_1
			MOV _2_LEVEL, #0d
			LJMP _MSG_DOWN_DALEJ

			_MSG_DOWN_TO_1:
				MOV _2_LEVEL, #1d

			_MSG_DOWN_DALEJ:
				CALL _DISPLAY_MSG
				CALL _WAIT_FOR_DOWN

			_MSG_ESC:
				JB _ESC, _MSG_ENTER
				MOV _2_LEVEL, #0d
				CALL _DISPLAY_MAIN_MENU
				LJMP _MAIN_MENU_PREP

			_MSG_ENTER:

				JB _ENTER, _MSG
				CJNE _2_LEVEL, #0d, _MSG_ENTER_READ

				_MSG_SEND:	
					CALL _SEND_MESSAGE
					CALL _WAIT_FOR_ENTER
					LJMP _MSG

				_MSG_ENTER_READ:
					CALL _DISPLAY_READ
					CALL _WAIT_FOR_ENTER

				_MSG_READ_ESC_LOOP:
					CALL _POBIERZ_KLAWISZ
					JB _ESC, _MSG_READ_ESC_LOOP

				CALL _DISPLAY_MSG
				CALL _WAIT_FOR_ESC
				LJMP _MSG

		;-------------------------------- SETTINGS ----------------------------------------------	

		_SETTINGS_PREP:
			CALL _WAIT_FOR_ENTER

		_SETTINGS:

			CALL _POBIERZ_KLAWISZ

		;_SETTINGS_UP:

			JB _UP, _SETTINGS_DOWN
			CJNE _2_LEVEL, #1d, _SETTINGS_UP_TO_1
			MOV _2_LEVEL, #0d
			LJMP _SETTINGS_UP_DALEJ

			_SETTINGS_UP_TO_1:
				MOV _2_LEVEL, #1d

			_SETTINGS_UP_DALEJ:
				CALL _DISPLAY_SETTINGS
				CALL _WAIT_FOR_UP

		_SETTINGS_DOWN:

			JB _DOWN, _SETTINGS_ENTER
			CJNE _2_LEVEL, #1d, _SETTINGS_DOWN_TO_1
			MOV _2_LEVEL, #0d
			LJMP _SETTINGS_DOWN_DALEJ

			_SETTINGS_DOWN_TO_1:
				MOV _2_LEVEL, #1d

			_SETTINGS_DOWN_DALEJ:
				CALL _DISPLAY_SETTINGS
				CALL _WAIT_FOR_DOWN

		_SETTINGS_ENTER:

			JNB _ENTER, _SETTINGS_ENTER_INSTR
			LJMP _SETTINGS_ESC

			_SETTINGS_ENTER_INSTR:

			CJNE _2_LEVEL, #1d, _SETTINGS_UPTIME_LJMP
			JMP _EDIT_MESSAGE_INSTR

			_SETTINGS_UPTIME_LJMP:
				LJMP _SETTINGS_UPTIME

			_EDIT_MESSAGE_INSTR:			

			CALL _DISPLAY_EDIT_MSG
			CALL _WAIT_FOR_ENTER

			_SETTINGS_EDIT_MESSAGE:

				_X_AT_FIRST:

					CJNE _LOCATION_OF_X, #0d, _X_AT_SECOND
					CALL _POBIERZ_KLAWISZ

					;_FIRST_UP:
						JB _UP, _FIRST_DOWN
						INC _MSG_1
						MOV A, _MSG_1
						CJNE A, #10d, _FIRST_UP_DALEJ
							MOV _MSG_1, #0d

					_FIRST_UP_DALEJ:
						CALL _DISPLAY_EDIT_MSG
						CALL _WAIT_FOR_UP
						LJMP _X_AT_FIRST


					_FIRST_DOWN:
						JB _DOWN, _FIRST_LEFT
						MOV A, _MSG_1
						CJNE A, #0d, _FIRST_DOWN_DALEJ
						MOV _MSG_1, #10d

					_FIRST_DOWN_DALEJ:
						DEC _MSG_1
						CALL _DISPLAY_EDIT_MSG
						CALL _WAIT_FOR_DOWN
						LJMP _X_AT_FIRST

					_FIRST_LEFT:
						JB _LEFT, _FIRST_RIGHT
						LJMP _EDIT_MESSAGE_LEFT

					_FIRST_RIGHT:
						JB _RIGHT, _FIRST_ESC
						LJMP _EDIT_MESSAGE_RIGHT

					_FIRST_ESC:
						JB _ESC, _FIRST_END
						LJMP _EDIT_MESSAGE_ESC

					_FIRST_END:

					LJMP _X_AT_FIRST

				_X_AT_SECOND:
					CJNE _LOCATION_OF_X, #1d, _X_AT_THIRD
					CALL _POBIERZ_KLAWISZ

					;_SECOND_UP:
						JB _UP, _SECOND_DOWN
						INC _MSG_2
						MOV A, _MSG_2
						CJNE A, #10d, _SECOND_UP_DALEJ
							MOV _MSG_2, #0d

					_SECOND_UP_DALEJ:
						CALL _DISPLAY_EDIT_MSG
						CALL _WAIT_FOR_UP
						LJMP _X_AT_SECOND


					_SECOND_DOWN:
						JB _DOWN, _SECOND_LEFT
						MOV A, _MSG_2
						CJNE A, #0d, _SECOND_DOWN_DALEJ
						MOV _MSG_2, #10d
						
					_SECOND_DOWN_DALEJ:
						DEC _MSG_2
						CALL _DISPLAY_EDIT_MSG
						CALL _WAIT_FOR_DOWN
						LJMP _X_AT_SECOND

					_SECOND_LEFT:
						JNB _LEFT, _EDIT_MESSAGE_LEFT

					;_SECOND_RIGHT:
						JNB _RIGHT, _EDIT_MESSAGE_RIGHT

					;_SECOND_ESC:
						JNB _ESC, _EDIT_MESSAGE_ESC

					LJMP _X_AT_SECOND


				_X_AT_THIRD:		
					CALL _POBIERZ_KLAWISZ

					;_THIRD_UP:
						JB _UP, _THIRD_DOWN
						INC _MSG_3
						MOV A, _MSG_3
						CJNE A, #10d, _THIRD_UP_DALEJ
						MOV _MSG_3, #0d

					_THIRD_UP_DALEJ:
						CALL _DISPLAY_EDIT_MSG
						CALL _WAIT_FOR_UP
						LJMP _X_AT_SECOND


					_THIRD_DOWN:
						JB _DOWN, _THIRD_LEFT
						MOV A, _MSG_3
						CJNE A, #0d, _THIRD_DOWN_DALEJ
						MOV _MSG_3, #10d
						
					_THIRD_DOWN_DALEJ:
						DEC _MSG_3
						CALL _DISPLAY_EDIT_MSG
						CALL _WAIT_FOR_DOWN
						LJMP _X_AT_THIRD

					_THIRD_LEFT:
						JNB _LEFT, _EDIT_MESSAGE_LEFT

					;_THIRD_RIGHT:
						JNB _RIGHT, _EDIT_MESSAGE_RIGHT

					;_THIRD_ESC:
						JNB _ESC, _EDIT_MESSAGE_ESC

					LJMP _X_AT_THIRD


				_EDIT_MESSAGE_LEFT:

					CJNE _LOCATION_OF_X, #0d, _EDIT_MESSAGE_LEFT_NEXT
					MOV _LOCATION_OF_X, #3d

					_EDIT_MESSAGE_LEFT_NEXT:
						DEC _LOCATION_OF_X

					CALL _DISPLAY_EDIT_MSG
					CALL _WAIT_FOR_LEFT
					LJMP _SETTINGS_EDIT_MESSAGE

				_EDIT_MESSAGE_RIGHT:

					INC _LOCATION_OF_X

					CJNE _LOCATION_OF_X, #3d, _EDIT_MESSAGE_RIGHT_NEXT
					MOV _LOCATION_OF_X, #0d

					_EDIT_MESSAGE_RIGHT_NEXT:
						
					CALL _DISPLAY_EDIT_MSG
					CALL _WAIT_FOR_RIGHT
					LJMP _SETTINGS_EDIT_MESSAGE

				_EDIT_MESSAGE_ESC:
					
					MOV _LOCATION_OF_X, #0d
					CALL _DISPLAY_SETTINGS
					CALL _WAIT_FOR_ESC
					LJMP _SETTINGS_PREP


			_SETTINGS_UPTIME:
				CALL _DISPLAY_UPTIME
				CALL _WAIT_FOR_ENTER

			_SETTINGS_UPTIME_DALEJ:
				CALL _POBIERZ_KLAWISZ
				JB _ESC, _SETTINGS_UPTIME_DALEJ
				CALL _DISPLAY_SETTINGS
				CALL _WAIT_FOR_ESC

		_SETTINGS_ESC:
			JB _ESC, _SETTINGS_JUMP
			MOV _2_LEVEL, #0d
			CALL _DISPLAY_MAIN_MENU
			LJMP _MAIN_MENU_PREP

		_SETTINGS_JUMP:
			LJMP _SETTINGS

		;-------------------------------- TEST ----------------------------------------------
		; 0 - BUZZER         1 - LED

		_TEST_PREP:
			CALL _WAIT_FOR_ENTER

		_TEST:
			CALL _POBIERZ_KLAWISZ
		
		;_TEST_UP:

			JB _UP, _TEST_DOWN
			CJNE _2_LEVEL, #1d, _TEST_UP_TO_1
			MOV _2_LEVEL, #0d
			LJMP _TEST_UP_DALEJ

			_TEST_UP_TO_1:
				MOV _2_LEVEL, #1d

			_TEST_UP_DALEJ:
				CALL _DISPLAY_TEST
				CALL _WAIT_FOR_UP

		_TEST_DOWN:

			JB _DOWN, _TEST_ENTER
			CJNE _2_LEVEL, #1d, _TEST_DOWN_TO_1
			MOV _2_LEVEL, #0d
			LJMP _TEST_DOWN_DALEJ

			_TEST_DOWN_TO_1:
				MOV _2_LEVEL, #1d

			_TEST_DOWN_DALEJ:
				CALL _DISPLAY_TEST
				CALL _WAIT_FOR_DOWN

		_TEST_ENTER:
			JB _ENTER, _TEST_ESC
			CJNE _2_LEVEL, #1d, _TEST_BUZZER
			CPL P1.7
			LJMP _TEST_ENTER_DALEJ

			_TEST_BUZZER:
				CPL P1.5

		_TEST_ENTER_DALEJ:
			CALL _WAIT_FOR_ENTER

		_TEST_ESC:
			JB _ESC, _TEST
			MOV _2_LEVEL, #0d
			CALL _DISPLAY_MAIN_MENU
			LJMP _MAIN_MENU_PREP

_LOOP:
	LJMP _MAIN_MENU

;------------------------------------------ TRANSMISJA ------------------------------------------------------

_TRANSMISJA_INIT:


	;MO M1 M2 REN TB8 RB8 TI RI
	MOV SCON,#01010000b ;M0=0, M1=1, M2=0, REN=1, TB8=0, RB8=0, TI=0, RI=0
	;GATE1 CT1 T1M1 T1M0 GATE0 CT0 T0M1 T0M0
	ANL TMOD, #00101111b ;GATE1=0, CT1=0, T1M1=?, T1M0=0, GATE0=?, CT0=?, T0M1=?, T0M0=?
	ORL TMOD, #00100000b ;GATE1=?, CT1=?, T1M1=1, T1M0=?, GATE0=?, CT0=?, T0M1=?, T0M0=?

	MOV TL1,#0FDh
	MOV TH1,#0FDh
	ANL PCON,#01111111b
	CLR TF1
	SETB TR1
	SETB ES
	SETB EA
	SETB _RECV_FLG
	SETB _SEND_FLG
	MOV _RECIVE_MSG_1, #'0'
	MOV _RECIVE_MSG_2, #'0'
	MOV _RECIVE_MSG_3, #'0'
	MOV _RECIVE_COUNT, #0d

RET

_SEND_MESSAGE:

	SETB _SEND_FLG
	MOV A, _MSG_1
	ADD A, #48d
	_FIRST_MESSAGE:
		JNB _SEND_FLG, _FIRST_MESSAGE
		MOV SBUF, A
		CLR _SEND_FLG

	MOV A, _MSG_2
	ADD A, #48d
	_SECOND_MESSAGE:
		JNB _SEND_FLG, _SECOND_MESSAGE
		MOV SBUF, A
		CLR _SEND_FLG

	MOV A, _MSG_3
	ADD A, #48d
	_THIRD_MESSAGE:
		JNB _SEND_FLG, _THIRD_MESSAGE
		MOV SBUF, A
		CLR _SEND_FLG

RET

_TRANSMISJA_OBSLUGA:

	;JNB _RECV_FLG, _TRANSMISJA_OBSLUGA

	_FIRST_RECIVE:
		
		CJNE _RECIVE_COUNT, #0d, _SECOND_RECIVE
		MOV _RECIVE_MSG_1 ,SBUF
		INC _RECIVE_COUNT
		JMP _RECIVE_FI

	_SECOND_RECIVE:

		CJNE _RECIVE_COUNT, #1d, _THIRD_RECIVE
		MOV _RECIVE_MSG_2 ,SBUF
		INC _RECIVE_COUNT
		JMP _RECIVE_FI

	_THIRD_RECIVE:

		MOV _RECIVE_MSG_3 ,SBUF
		MOV _RECIVE_COUNT, #0d
		JMP _RECIVE_FI

	_RECIVE_FI:

RET



;------------------------------------------FUNKCJE WYSWIETLAJACE----------------------------------------------

_MENU_INIT:
	MOV _1_LEVEL, #2d
	MOV _2_LEVEL, #0d
	CLR c
	MOV _MSG_1, #0d
	MOV _MSG_2, #0d
	MOV _MSG_3, #0d
	MOV _LOCATION_OF_X, #0d
RET

_DISPLAY_MAIN_MENU:
	
	CALL _CLEAR_LCD
	CALL _WRITE_MAIN_MENU
	CALL _USTAW_2_LINIE
	
	;_MAIN_MENU_MSG
		CJNE _1_LEVEL, #2d, _MAIN_MENU_SETTINGS
		CALL _WRITE_MSG
		LJMP DISPLAY_MAIN_MENU_RET

	_MAIN_MENU_SETTINGS:
		CJNE _1_LEVEL, #1d, _MAIN_MENU_TEST
		CALL _WRITE_SETTINGS
		LJMP DISPLAY_MAIN_MENU_RET

	_MAIN_MENU_TEST:
		CALL _WRITE_TEST

	DISPLAY_MAIN_MENU_RET:

RET

_DISPLAY_SETTINGS:
	
	CALL _CLEAR_LCD
	CALL _WRITE_SETTINGS
	CALL _USTAW_2_LINIE
	
	;_SETTINGS_UPTIME
		CJNE _2_LEVEL, #0d, _SETTINGS_EDIT_MSG
		CALL _WRITE_UPTIME
		LJMP DISPLAY_SETTINGS_RET

	_SETTINGS_EDIT_MSG:
		CALL _WRITE_EDIT_MSG

	DISPLAY_SETTINGS_RET:

RET

_DISPLAY_MSG:
	
	CALL _CLEAR_LCD
	CALL _WRITE_MSG
	CALL _USTAW_2_LINIE
	
	;_MSG_SEND
		CJNE _2_LEVEL, #0d, _MSG_READ
		CALL _WRITE_SEND
		LJMP DISPLAY_MSG_RET

	_MSG_READ:
		CALL _WRITE_READ

	DISPLAY_MSG_RET:

RET

_DISPLAY_TEST:
	
	CALL _CLEAR_LCD
	CALL _WRITE_TEST
	CALL _USTAW_2_LINIE
	
	;_TEST_BUZZER
		CJNE _2_LEVEL, #0d, _TEST_LED
		CALL _WRITE_BUZZER
		LJMP DISPLAY_TEST_RET

	_TEST_LED:
		CALL _WRITE_LED

	DISPLAY_TEST_RET:

RET

_DISPLAY_READ:

	CALL _CLEAR_LCD

	MOV R7, _RECIVE_MSG_1

	CALL _LCD_DATA_FROM_R7

	MOV R7, _RECIVE_MSG_2

	CALL _LCD_DATA_FROM_R7

	MOV R7, _RECIVE_MSG_3

	CALL _LCD_DATA_FROM_R7

RET

_DISPLAY_UPTIME:

	CALL _CLEAR_LCD
	CALL _WRITE_UPTIME
	CALL _USTAW_2_LINIE

	MOV A, _GODZINY
	MOV B, #10d
	DIV AB

	ADD A, #'0'
	MOV R7, A
	CALL _LCD_DATA_FROM_R7

	MOV A, B
	ADD A, #'0'
	MOV R7, A
	CALL _LCD_DATA_FROM_R7

	MOV R7, #58d
	CALL _LCD_DATA_FROM_R7

	MOV A, _MINUTY
	MOV B, #10d
	DIV AB

	ADD A, #'0'
	MOV R7, A
	CALL _LCD_DATA_FROM_R7

	MOV A, B
	ADD A, #'0'
	MOV R7, A
	CALL _LCD_DATA_FROM_R7

	MOV R7, #58d
	CALL _LCD_DATA_FROM_R7

	MOV A, _SEKUNDY
	MOV B, #10d
	DIV AB

	ADD A, #'0'
	MOV R7, A
	CALL _LCD_DATA_FROM_R7

	MOV A, B
	ADD A, #'0'
	MOV R7, A
	CALL _LCD_DATA_FROM_R7

RET

_DISPLAY_EDIT_MSG:

	CALL _CLEAR_LCD

	MOV A, _MSG_1
	ADD A, #'0'
	MOV R7, A

	CALL _LCD_DATA_FROM_R7

	MOV A, _MSG_2
	ADD A, #'0'
	MOV R7, A

	CALL _LCD_DATA_FROM_R7

	MOV A, _MSG_3
	ADD A, #'0'
	MOV R7, A

	CALL _LCD_DATA_FROM_R7

	CALL _USTAW_2_LINIE

	;_X_IN_FIRST:
		CJNE _LOCATION_OF_X, #0d, _X_IN_SECOND

		MOV R7, #'x'
		CALL _LCD_DATA_FROM_R7
		MOV R7, #' '
		CALL _LCD_DATA_FROM_R7
		MOV R7, #' '
		CALL _LCD_DATA_FROM_R7

		LJMP _DISPLAY_EDIT_MSG_RET

	_X_IN_SECOND:
		CJNE _LOCATION_OF_X, #1d, _X_IN_THIRD

		MOV R7, #' '
		CALL _LCD_DATA_FROM_R7
		MOV R7, #'x'
		CALL _LCD_DATA_FROM_R7
		MOV R7, #' '
		CALL _LCD_DATA_FROM_R7

		LJMP _DISPLAY_EDIT_MSG_RET

	_X_IN_THIRD:

		MOV R7, #' '
		CALL _LCD_DATA_FROM_R7
		MOV R7, #' '
		CALL _LCD_DATA_FROM_R7
		MOV R7, #'x'
		CALL _LCD_DATA_FROM_R7	

	_DISPLAY_EDIT_MSG_RET:

RET

;----------------------------------------------------- KLAWIATURA -----------------------------------------

_POBIERZ_KLAWISZ:

	MOV DPTR, #CSKB1
	MOVX A, @DPTR
	MOV KBD, A

RET

_WAIT_FOR_UP:
	
	MOV _COUNTER, #60d

	DJNZ _COUNTER, _WAIT_FOR_UP_INSTR

	LJMP _WAIT_FOR_UP_RET

	_WAIT_FOR_UP_INSTR:

		CALL _POBIERZ_KLAWISZ
		JNB _UP, _WAIT_FOR_UP


	_WAIT_FOR_UP_RET:

RET

_WAIT_FOR_DOWN:
	
	MOV _COUNTER, #60d

	DJNZ _COUNTER, _WAIT_FOR_DOWN_INSTR

	LJMP _WAIT_FOR_DOWN_RET

	_WAIT_FOR_DOWN_INSTR:

		CALL _POBIERZ_KLAWISZ
		JNB _DOWN, _WAIT_FOR_DOWN

	_WAIT_FOR_DOWN_RET:

RET

_WAIT_FOR_LEFT:
	
	MOV _COUNTER, #60d

	DJNZ _COUNTER, _WAIT_FOR_LEFT_INSTR

	LJMP _WAIT_FOR_LEFT_RET

	_WAIT_FOR_LEFT_INSTR:

		CALL _POBIERZ_KLAWISZ
		JNB _LEFT, _WAIT_FOR_LEFT

	_WAIT_FOR_LEFT_RET:

RET

_WAIT_FOR_RIGHT:
	
	MOV _COUNTER, #60d

	DJNZ _COUNTER, _WAIT_FOR_RIGHT_INSTR

	LJMP _WAIT_FOR_RIGHT_RET

	_WAIT_FOR_RIGHT_INSTR:

		CALL _POBIERZ_KLAWISZ
		JNB _RIGHT, _WAIT_FOR_RIGHT

	_WAIT_FOR_RIGHT_RET:

RET

_WAIT_FOR_ENTER:
	
	MOV _COUNTER, #60d

	DJNZ _COUNTER, _WAIT_FOR_ENTER_INSTR

	LJMP _WAIT_FOR_ENTER_RET

	_WAIT_FOR_ENTER_INSTR:

		CALL _POBIERZ_KLAWISZ
		JNB _ENTER, _WAIT_FOR_ENTER

	_WAIT_FOR_ENTER_RET:

RET

_WAIT_FOR_ESC:
	
	MOV _COUNTER, #60d

	DJNZ _COUNTER, _WAIT_FOR_ESC_INSTR

	LJMP _WAIT_FOR_ESC_RET

	_WAIT_FOR_ESC_INSTR:

		CALL _POBIERZ_KLAWISZ
		JNB _ESC, _WAIT_FOR_ESC

	_WAIT_FOR_ESC_RET:

RET

;------------------------------------------------- TIMER --------------------------------------

_TIMER_INIT:

	MOV _SEKUNDY, #0d
	MOV _MINUTY, #0d
	MOV _GODZINY, #0d
	MOV _LICZNIK_PROGRAMOWY, #0d

	;USTAWIC TMOD
	;TRYB NAJMLODSZE 2 BITY ( 01 )
	;GATE=0 - IGNORUJE LINIE INT 0 [ 0 ]
	;C/T=0 - LICZNIK CZY CZASOMIERZ? = CZASOMIERZ, 1 = LICZNIK [ 0 ]
	MOV TMOD, #00000001B

	;UMIESCIC WARTOSC DO TH0 I TL0
	;TRYB 1 16BITOWY MAKSYMALNA WARTOOA 65 536 2^16 + 1 BO OD 0
	;65 536 - 9216 = 56 320
	MOV TH0, #TH0_POCZ
	MOV TL0, #TL0_POCZ

	;URUCHOMIENIE OBSLUGI INT_OD_T0
	SETB EA
	SETB ET0

	;flaga przepelnienia - wyczyscic
	CLR TF0

	;wlaczenie timera
	SETB TR0
RET

_TIMER_OBSLUGA:

	INC _LICZNIK_PROGRAMOWY

	MOV R6, _LICZNIK_PROGRAMOWY
	CJNE R6, #100d, _RETI

	MOV _LICZNIK_PROGRAMOWY, #0d
	INC _SEKUNDY
	MOV R6, _SEKUNDY
	CJNE R6, #60d, _RETI

	MOV _SEKUNDY, #0d
	INC _MINUTY
	MOV R6, _MINUTY
	CJNE R6, #60d, _RETI

	MOV _MINUTY, #0d
	INC _GODZINY

	_RETI:

RET

;----------------------------------- LCD ---------------------------------------------------------

_LCD_CMD_FROM_R7:
	CALL _LCD_WAIT_WHILE_BUSY
	MOV A, R7
	MOV DPTR, #LCDWC
	MOVX @DPTR, A
RET

_LCD_DATA_FROM_R7:
	CALL _LCD_WAIT_WHILE_BUSY
	MOV A, R7
	MOV DPTR, #LCDWD
	MOVX @DPTR, A
RET

_LCD_WAIT_WHILE_BUSY:
    
    _BUSY:
       MOV DPTR, #LCDRC
       MOVX A, @DPTR
	   JNB ACC.7, _LCD_READY
	   LJMP _BUSY
	_LCD_READY:

RET

_LCD_INIT:
	MOV R7,#00111000B
	CALL _LCD_CMD_FROM_R7
	MOV R7,#0FH
	CALL _LCD_CMD_FROM_R7
	MOV R7,#00000110B
	CALL _LCD_CMD_FROM_R7
	MOV R7,#1
	CALL _LCD_CMD_FROM_R7
RET


_CLEAR_LCD:
	MOV R7, #1b
	CALL _LCD_CMD_FROM_R7
RET

_USTAW_2_LINIE:

	MOV R7, #11000000B
    CALL _LCD_CMD_FROM_R7

RET

;--------------------------------- NAPISY --------------------------------------------

_WRITE_MAIN_MENU:

	MOV R5, #0

_WRITE_MAIN_MENU_LOOP:
	
	CJNE R5, #9d,  _WRITE_MAIN_MENU_LOOP_INSTR
	LJMP _WRITE_MAIN_MENU_END

_WRITE_MAIN_MENU_LOOP_INSTR:

    MOV DPTR, #_MAIN_MENU_STRING
    MOV A, R5
	MOVC A, @A+DPTR
	MOV R7, A
	CALL _LCD_DATA_FROM_R7	
	INC R5
	LJMP _WRITE_MAIN_MENU_LOOP

_WRITE_MAIN_MENU_END:

RET

_WRITE_MSG:

	MOV R5, #0d

_WRITE_MSG_LOOP:
	
	CJNE R5, #3d, _WRITE_MSG_LOOP_INSTR
	LJMP _WRITE_MAIN_MENU_END

_WRITE_MSG_LOOP_INSTR:

    MOV DPTR, #_MSG_STRING
    MOV A, R5
	MOVC A, @A+DPTR
	MOV R7, A
	CALL _LCD_DATA_FROM_R7	
	INC R5
	LJMP _WRITE_MSG_LOOP

_WRITE_MSG_END:

RET

_WRITE_SETTINGS:

	MOV R5, #0d

_WRITE_SETTINGS_LOOP:
	
	CJNE R5, #8d, _WRITE_SETTINGS_LOOP_INSTR
	LJMP _WRITE_SETTINGS_END

_WRITE_SETTINGS_LOOP_INSTR:

    MOV DPTR, #_SETTINGS_STRING
    MOV A, R5
	MOVC A, @A+DPTR
	MOV R7, A
	CALL _LCD_DATA_FROM_R7	
	INC R5
	LJMP _WRITE_SETTINGS_LOOP

_WRITE_SETTINGS_END:

RET

_WRITE_TEST:

	MOV R5, #0d

_WRITE_TEST_LOOP:
	
	CJNE R5, #4d, _WRITE_TEST_LOOP_INSTR
	LJMP _WRITE_TEST_END

_WRITE_TEST_LOOP_INSTR:

    MOV DPTR, #_TEST_STRING
    MOV A, R5
	MOVC A, @A+DPTR
	MOV R7, A
	CALL _LCD_DATA_FROM_R7	
	INC R5
	LJMP _WRITE_TEST_LOOP

_WRITE_TEST_END:

RET

_WRITE_SEND:

	MOV R5, #0d

_WRITE_SEND_LOOP:
	
	CJNE R5, #4d, _WRITE_SEND_LOOP_INSTR
	LJMP _WRITE_SEND_END

_WRITE_SEND_LOOP_INSTR:

    MOV DPTR, #_SEND_STRING
    MOV A, R5
	MOVC A, @A+DPTR
	MOV R7, A
	CALL _LCD_DATA_FROM_R7	
	INC R5
	LJMP _WRITE_SEND_LOOP

_WRITE_SEND_END:

RET

_WRITE_READ:

	MOV R5, #0d

_WRITE_READ_LOOP:
	
	CJNE R5, #4d, _WRITE_READ_LOOP_INSTR
	LJMP _WRITE_READ_END

_WRITE_READ_LOOP_INSTR:

    MOV DPTR, #_READ_STRING
    MOV A, R5
	MOVC A, @A+DPTR
	MOV R7, A
	CALL _LCD_DATA_FROM_R7	
	INC R5
	LJMP _WRITE_READ_LOOP

_WRITE_READ_END:

RET

_WRITE_UPTIME:

	MOV R5, #0d

_WRITE_UPTIME_LOOP:
	
	CJNE R5, #6d, _WRITE_UPTIME_LOOP_INSTR
	LJMP _WRITE_UPTIME_END

_WRITE_UPTIME_LOOP_INSTR:

    MOV DPTR, #_UPTIME_STRING
    MOV A, R5
	MOVC A, @A+DPTR
	MOV R7, A
	CALL _LCD_DATA_FROM_R7	
	INC R5
	LJMP _WRITE_UPTIME_LOOP

_WRITE_UPTIME_END:

RET

_WRITE_EDIT_MSG:

	MOV R5, #0d

_WRITE_EDIT_MSG_LOOP:
	
	CJNE R5, #8d, _WRITE_EDIT_MSG_LOOP_INSTR
	LJMP _WRITE_EDIT_MSG_END

_WRITE_EDIT_MSG_LOOP_INSTR:

    MOV DPTR, #_EDIT_MSG_STRING
    MOV A, R5
	MOVC A, @A+DPTR
	MOV R7, A
	CALL _LCD_DATA_FROM_R7	
	INC R5
	LJMP _WRITE_EDIT_MSG_LOOP

_WRITE_EDIT_MSG_END:

RET

_WRITE_BUZZER:

	MOV R5, #0d

_WRITE_BUZZER_LOOP:
	
	CJNE R5, #6d, _WRITE_BUZZER_LOOP_INSTR
	LJMP _WRITE_BUZZER_END

_WRITE_BUZZER_LOOP_INSTR:

    MOV DPTR, #_BUZZER_STRING
    MOV A, R5
	MOVC A, @A+DPTR
	MOV R7, A
	CALL _LCD_DATA_FROM_R7	
	INC R5
	LJMP _WRITE_BUZZER_LOOP

_WRITE_BUZZER_END:

RET

_WRITE_LED:

	MOV R5, #0d

_WRITE_LED_LOOP:
	
	CJNE R5, #3d, _WRITE_LED_LOOP_INSTR
	LJMP _WRITE_LED_END

_WRITE_LED_LOOP_INSTR:

    MOV DPTR, #_LED_STRING
    MOV A, R5
	MOVC A, @A+DPTR
	MOV R7, A
	CALL _LCD_DATA_FROM_R7	
	INC R5
	LJMP _WRITE_LED_LOOP

_WRITE_LED_END:

RET

_MAIN_MENU_STRING:
	DB 'MAIN MENU'

_MSG_STRING:
	DB 'MSG'

_SETTINGS_STRING:
	DB 'SETTINGS'

_TEST_STRING:
	DB 'TEST'

_SEND_STRING:
	DB 'SEND'

_READ_STRING:
	DB 'READ'

_UPTIME_STRING:
	DB 'UPTIME'

_EDIT_MSG_STRING:
	DB 'EDIT_MSG'

_BUZZER_STRING:
	DB 'BUZZER'

_LED_STRING:
	DB 'LED'

END