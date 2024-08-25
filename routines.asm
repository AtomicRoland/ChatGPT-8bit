\ routines.asm

\ **********************************************************************
\ *                 Machine independent routines                       *
\ **********************************************************************

\ This routine prints a text string until a byte is read with bit7 set. It returns
\ to the first instruction after the string to be printed. This routine will usually
\ be called to print fixed strings in the ROM.
.printtext          pla                     \ get low byte from stack
                    sta zp                  \ set in workspace
                    pla                     \ get high byte from stack
                    sta zp+1                \ set in workspace
.printtext_l1       ldy #0                  \ load index
                    inc zp                  \ increment pointer
                    bne printtext_l2        
                    inc zp+1
.printtext_l2       lda (zp),y              \ load character
                    bmi printtext_l3        \ jmp if end of string
                    jsr osasci              \ print character
                    jmp printtext_l1        \ next character
.printtext_l3       jmp (zp)                \ return to calling routine


\ This routine reads characters from the command line and returns after the first
\ non-space character. The Y register points to this character. The accu holds the
\ first non-space character.
.skipspace          iny                     \ increment pointer
.skipspace1         lda (line),y            \ load character
                    cmp #&20                \ is it a space
                    beq skipspace           \ yes, read next character
                    rts                     \ it's not a space, return


\ This routine prints the value of the accu in hex digits
.printhex           pha                     \ save accu
                    lsr a                   \ shift high nibble to low
                    lsr a
                    lsr a
                    lsr a
                    jsr printhex_l1         \ print nibble
                    pla                     \ restore value
 .printhex_l1       and #&0F                \ remove high nibble
                    cmp #&0A                \ test for hex digit
                    bcc printhex_l2         \ if not then continue
                    adc #6                  \ add 6 for hex letter
 .printhex_l2       adc #&30                \ add &30 for ascii value
                    jmp oswrch              \ print the digit and return


 \ find routine: search for a needle in a haystack.
 \ The haystack is the paged ram. 
 \ zeropage: X-reg    = pointer to memory block in current selected ram page
 \           needle   = pointer to string
 \           size     = number of bytes to search
 \ on exit:  carry = 1: string found, X points directly after needle in paged ram buffer
 \           carry = 0: string not found
 \           registers A and X are undefined

.fnd
 ldy #0                         \ reset index
.fnd1
 jsr read_buffer                \ read the data at position X
 beq fnd_not_found              \ if the end of data is reached then the string is not found
 cmp (needle),y                 \ compare with needle
 bne fnd                        \ if not equal reset search pointer
 iny
 cpy size
 bne fnd1
 sec
 rts
.fnd_not_found
 clc
 rts
 
\ Check if the string, pointed by X, in the buffer is "OK". 
\ On exit: Z = 1 -> yes, it is "OK"
\          Z = 0 -> no, it is not "OK"
\          A = not modified
\          X = not modified
.test_ok
 pha
 lda pageram,x
 cmp #'O'
 bne test1
 lda pageram+1,x  \\ this goes wrong if x=255 !
 cmp #'K'
.test1
 pla
 rts
  
\ Check if the string, pointed by X, in the buffer is "ERROR" (actually it is a bit lazy, only 
\ checks for the string "ERR" 
\ On exit: Z = 1 -> yes, it is "ERR"
\          Z = 0 -> no, it is not "ERR"
\          A = undefined
\          X = undefined (however, still points to the next position for reading the buffer)
.test_error
 pha
 jsr read_buffer
 cmp #'E'
 bne test1
 jsr read_buffer
 cmp #'R'
 bne test1
 jsr read_buffer
 cmp #'R'
 pla
 rts

\ Search for the next occurence of the newline character (&0A). 
\ On exit:  A is undefined (&0A if found, otherwise unknown) 
\           X points to the next character 
\           Z = 1 if end of buffer is reached
\           Z = 0 if newline is found
.search0a
 jsr read_buffer        \ read character from buffer
 beq search0a_l1        \ jump if end of buffer is reached
 cmp #&0A               \ compare with &0A
 bne search0a           \ it's not, keep searching
 cmp #&0D               \ it is &0A, compare to another value to clear the Z-flag
.search0a_l1     
 rts                    \ return


.save_registers                     \ save registers
 sta save_a
 stx save_x
 sty save_y
 rts

.restore_registers                  \ restore registers
 lda save_a
 ldx save_x
 ldy save_y
 rts

\ Calculates  DIVEND / DIVSOR = RESULT	
.div16
 divisor = zp+6                     \ just to make the code more human readable
 dividend = zp                    \ what a coincidence .... this is the address of baudrate
 remainder = zp+2                   \ not necessary, but it's calculated
 result = dividend                  \ more readability

 lda #0	                            \ reset remainder
 sta remainder
 sta remainder+1
 ldx #16	                        \ the number of bits

.div16loop	
 asl dividend	                    \ dividend lb & hb*2, msb to carry
 rol dividend+1	
 rol remainder	                    \ remainder lb & hb * 2 + msb from carry
 rol remainder+1
 lda remainder
 sec                                \ set carry for substraction
 sbc divisor	                    \ substract divisor to see if it fits in
 tay	                            \ lb result -> Y, for we may need it later
 lda remainder+1
 sbc divisor+1
 bcc div16skip	                    \ if carry=0 then divisor didn't fit in yet

 sta remainder+1	                \ else save substraction result as new remainder,
 sty remainder	
 inc result	                        \ and INCrement result cause divisor fit in 1 times

.div16skip
 dex
 bne div16loop	
 rts                                \ do you understand it? I don't ;-)

.wait_a_second                      \ wait a second....
 ldx #25                            \ load counter
.was1
 txa
 pha
 jsr wait
 pla
 tax
 dex                                \ decrement counter
 bne was1                           \ jump if not ready
 rts                                \ return

 \ print hex value in ascii digits
 \ code from mdfs.net - j.g.harston
.prdec24buf {
 lda data_counter+0
 pha
 lda data_counter+1
 pha
 lda data_counter+2
 pha
 ldy #21
 lda #0
 sta pr24pad
.prdec24lp1
 ldx #&ff
 sec
.prdec24lp2
 lda data_counter+0
 sbc prdec24tens+0,y
 sta data_counter+0
 lda data_counter+1
 sbc prdec24tens+1,y
 sta data_counter+1
 lda data_counter+2
 sbc prdec24tens+2,y
 sta data_counter+2
 inx
 bcs prdec24lp2
 lda data_counter+0
 adc prdec24tens+0,y
 sta data_counter+0
 lda data_counter+1
 adc prdec24tens+1,y
 sta data_counter+1
 lda data_counter+2
 adc prdec24tens+2,y
 sta data_counter+2
 txa
 bne prdec24digit
 lda pr24pad
 bne prdec24print
 beq prdec24next
.prdec24digit
 ldx #'0'
 stx pr24pad
 ora #'0'
 .prdec24print
 jsr tcp_write_buf
 .prdec24next
 dey
 dey
 dey
 bpl prdec24lp1
 pla
 sta data_counter+2
 pla
 sta data_counter+1
 pla
 sta data_counter+0
 rts
.prdec24tens
   EQUW 1       :EQUB 1 DIV 65536
   EQUW 10      :EQUB 10 DIV 65536
   EQUW 100     :EQUB 100 DIV 65536
   EQUW 1000    :EQUB 1000 DIV 65536
   EQUW 10000   :EQUB 10000 DIV 65536
   EQUW 100000 MOD 65535    :EQUB 100000 DIV 65536
   EQUW 1000000 MOD 65535   :EQUB 1000000 DIV 65536
   EQUW 10000000 MOD 65535  :EQUB 10000000 DIV 65536
}            

.mul10 \ MULTIPLY VALUE OF blocksize BY 10 AND ADD A
 pha
 asl blocksize
 lda blocksize
 rol blocksize+1
 rol blocksize+2
 ldy blocksize+1
 asl blocksize
 rol blocksize+1
 rol blocksize+2
 asl blocksize
 rol blocksize+1
 rol blocksize+2 
 clc
 adc blocksize
 sta blocksize
 tya
 adc blocksize+1
 sta blocksize+1
 lda blocksize+2
 adc #0
 sta blocksize+2
 clc
 pla
 adc blocksize
 sta blocksize
 lda blocksize+1
 adc #0
 sta blocksize+1
 lda blocksize+2
 adc #0
 sta blocksize+2
 rts

.breakpoint
 brk            \ perform a break
 EQUB 0         \ error number (not relevant here)
 EQUS "Breakpoint",0

\ **********************************************************************
\ *             Machine specific routines: Electron/BBC                *
\ **********************************************************************

 if __ELECTRON__ = 1
.reset_buffer
 ldx #&00
 stx pagereg
 rts

\ Get character from buffer
\ On entry: X points to the character to read
\ On exit:  Z = 1 when end of buffer reached otherwise 0
\           A = character
\           X = pointer to next character
\           Y = unchanged
\           page register is incremented on page overflow
\ Reads a character from the paged ram buffer at position X
\ returns the character in A and the X register points 
\ to the next data byte.
.read_buffer
 lda pageram,x
 php
.read_buffer_inc
 inx
 bne read_buffer_end
 jsr inc_page_reg
.read_buffer_end
 plp
 rts

\ Wait for two vertical sync for a short delay
.wait
 pha
 lda #19
 jsr osbyte
 jsr osbyte
 pla
 rts

\ Increments the paged ram register and sets the (X) pointer to the beginning of the page. 
\ If the end of paged ram has been reached then the page register will roll over from &FF
\ to &00 and the Z flag is set. The pageregister and X will not be updated and the routine
\ returns with Z=1. The calling routine can test this flag for the end of buffer.
.inc_page_reg
 ldx pagereg            \ load page register
 inx                    \ increment the value
 beq buffer_end         \ if it becomes zero then the end of the buffer (paged ram) is reached
 stx pagereg            \ write back to page register (i.e. select next page)
 ldx #0                 \ reset y register
 cpx #1                 \ clears Z-flag
.buffer_end
 rts                    \ return to store routine

 endif

\ **********************************************************************
\ *             Machine specific routines: Acorn Atom and System 5     *
\ **********************************************************************
 if __ATOM__ = 1 or __SYSTEM5__ = 1
.osasci
 jsr oswrch
 cmp #&0D
 bne osend
 pha
 lda #&0A
 jsr oswrch
 pla
.osend
 rts 

\ Test presense of paged ram
\ This test is destructive for both the ram content and the A register.
\ Returns with Z=0 for ram error.
.test_paged_ram
  lda #&AA                   \ load byte
  sta pageram                \ write to memory
  cmp pageram                \ compare memory with value
 .ram_error
  rts                        \ return from subroutine

\ OSWAIT simulation, wait about 1/60 second
.wait
.oswait
 pha
 tya
 pha
 txa
 pha
 ldx #4
.oswait_loop_x
 ldy #0
.oswait_loop_y
 nop
 nop
 nop
 nop
 nop
 dey
 bne oswait_loop_y
 dex
 bne oswait_loop_x
 pla
 tax
 pla
 tay
 pla
 rts

 endif


