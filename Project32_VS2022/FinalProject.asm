TITLE Program Template			(main.asm)

; Program Description:		Assembly Project
; Author:					Chase Moskowitz
; 							based on Kip Irvine's Template
; Date Created:	5/10/24			
; Last Modification Date: 9/15/2024	

INCLUDE Irvine32.inc
INCLUDE Macros.inc

; (insert symbol definitions here)
.data

; (insert variables here - flush left)
MAX_ROWS = 5                  ; constant for number of rows
MAX_COLS = 5                  ; constant for number of cols  
MAX_VALUE = 100                ; constant for max value

percentValue REAL8 0.8         ; collection percentage
tempStore REAL8 ?              ;temporay storage for arrray value
accumulator REAL8 ?            ;accumulator for amount of candy picked up


valueToLoad DWORD ?           ;value to load into array
rowNum DWORD ?                ;value chosen by user
colNum DWORD ?                ;value chosen by user

counter DWORD ?               ;counts the number of pick ups

warehouseFloor REAL8 MAX_ROWS * MAX_COLS dup(0.0)  ;2d array of floating points


.code
main PROC
	; (insert executable instructions here -- indented)



	mWrite "At Startup.... "
	call	Crlf            ;/n
	call displayArray                      ;call displayArray

	MOV ESI, OFFSET warehouseFloor          ;load edi with address to array
	MOV ECX, MAX_ROWS * MAX_COLS		    ;load ecx with length of array

L1:
	
	MOV EAX, MAX_VALUE                      ;mov max value into eax
	CALL randomRange                        ;eax=0 to Max_Value-1
	
	ADD EAX, 101                            ;eax= 101 plus max value plus 100
	 
	MOV valueToLoad, EAX                   ;load eax into valueToLoad

	FILD valueToLoad                       ;load int to stack
    FSTP REAL8 PTR [esi]                   ; stick value into array

	ADD ESI, 8					  	      ; advance to next set of elements in array
	 
	LOOP L1

	finit					               ; initialize FPU	
	
L2:

	CALL showFPUStack                      ;shows the floatimg point stack
	call displayArray

	call	Crlf            ;/n

	mWrite "Specify from which sector to gather M&M's"

	call	Crlf            ;/n


	mWrite "Enter row(99 to exit): "
	call readDec			; eax has row #
	mov rowNum, eax		    ; store to memory
	CMP rowNum, 99          ;compare rownum to 99
	JE L3	                ;If equal to 99, jump to L3


	mWrite "Enter col(99 to exit): "
	call readDec			; eax has row #
	mov colNum, eax	        ; store to memory
  	CMP colNum, 99          ;compare colNum to 99
	JE L3	                ;If equal to 99, jump to L3

	mov edx, 0				; prepare for mul

	mov ebx, MAX_COLS*8 	      ; calculate the number of bytes in a row
	mov eax, rowNum               ;mov rowNum into EAX

	mul ebx                       ; eax is now rowNum * MAX_COLS*8 - total bytes before current row
    mov edi, eax	              ; put byte offset into edi

	mov eax, colNum                ;load eax with colum number
	mov ebx, 8		       ; load ebx with 8 for size of element
	mul ebx			       ; eax is now colNum*8 which is the byte offset in the current row
	
	
	add edi, eax			  ; edi is now rowNum * NUM_COLS*4 + colNum*4
					  ; which is the byte offset from the beginning
					  ; of the array to this element rowNum,colNum

	mWrite "Current value is: "

    FLD warehouseFloor[EDI]	;Load array based off row and colum #
	call writeFloat         ;Display value of row, col

    FST tempStore            ;temproary store value of array

    FLD percentValue         ; push to stack
    
	call	Crlf            ;/n
	call	Crlf            ;/n
	mWrite "Gathered Amount is: "

	fmul 					; takes top two of stack, multiplies, leaves in place
	call writeFloat         ;Display value of after multiplication

	FST accumulator        ;store in accumulator
	
	FLD tempStore          ; push to stack
	FSUB                   ;Subtract gathered-total
	FABS                   ;take absolute value

	FSTP warehouseFloor[EDI]  ;store new value into array
	inc counter               ;increment counter

	Call Crlf            ;/n
	FSTP ST(0)

	JMP L2


L3:
     Call	Crlf            ;/n

	 mWrite "Number of gatherings = "
	 mov eax, counter     ;move value of counter into EAX
	 call writeDec        ;Display value

	 Call	Crlf            ;/n

	 mWrite "Total gathered = "
	 FLD accumulator        ; move value of accumulator into stack
	 Call writeFloat        ;dispaly value

	 fild counter           ;move int counter to stack

	 fdiv                   ; divide total/counter for the average

	 Call	Crlf            ;/n
	 mWrite "Average amount gathered per gathering is = "
	 Call writeFloat        ;dispaly value

	 FSTP ST(0)

	 Call Crlf            ;/n
	 CALL showFPUStack                      ;shows the floatimg point stack





	
	exit					; exit to operating system
main ENDP

; =============================================
;		
; displayArray procedure displays the 2D array warehouseFloor 
;		
; no parameters, but: 
;      warehouseFloor is expected to be a 2D array of FP
;      MAX_ROWS and MAX_COLS are expected to be declared constants
;		
displayArray PROC uses edx edi ecx eax

	call crlf							; blank line
	
	mWrite "The warehouse of loose M&M's (by pound) currently is:"	; call macro to display header
	
	call crlf							; move to beginning of next line

	mov ecx, MAX_COLS					; load ECX with # of cols
	mov eax, 0							; initialize EAX to 0 -- for this loop, EAX is col#

displayColHeaders:

    mWrite '         '				    ; display space
	call writeDec						; display col header
	mWrite '      '				        ; display space
	inc eax								; inc col#
	loop displayColHeaders				; repeat
	call crlf							; \n

	mov edi, offset	warehouseFloor	    ; load edi with address of warehosue florr

	mov ecx, MAX_ROWS					; load ecx with number of rows so we can loop through rows

displayRow:								; top of outerloop on rows

										; display row#
	mov eax, MAX_ROWS		               ; load EAX with NUM_ROWS
	sub eax, ecx						; subtract ECX to get row number
					
	call writeDec						; display row#
	mWrite ':'							; display :

	push ecx							; preserve ecx from outloop to use innerloop

	mov ecx, MAX_COLS					; load ecx with number of cols so we can loop through cols

displayCol:								; top of innerloop on cols
	FLD REAL8 PTR [EDI]		            ;Load the real value of the array
	call writeFloat                     ;dispaly the value
    FSTP ST(0)

	mWrite ' '							; display space

	add edi,8							; advance edi to next element

	loop displayCol						; bottom of innerloop (loop on cols)

	call crlf							; now that a row has been displayed, move to beginning of next line for next row

	pop ecx								; restore ecx for outerloop on rows

	loop displayRow						; bottom of outerloop (loop on rows)

	ret									; done with this method
displayArray ENDP

END main
