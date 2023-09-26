\ ChatGPT client for Acorn 8bit micros
\ Reader for result

\ (C)Roland Leurs 2023
\ Version 1.00 August 2023


.reader_init
		lda #<textbuf    			\ set start of read buffer into pointer
		sta readpointer
		lda #>textbuf 
		sta readpointer+1
		rts


\ Format the text
\ Look for words in the buffer and place an &0D at the last space before the screenwidth
\ is reached.
.reader_format
		jsr reader_init				\ initialize the read pointer
		ldy #0					    \ initialize index
.reader_l1	ldx #0					\ reset counter
.reader_l2	lda (readpointer),y		\ read a character from buffer
		beq reader_l3				\ jump if the end of the text is reached
		jsr reader_incr				\ increment reader pointer
		cmp #&0D				    \ compare with end of line
		beq reader_l1				\ if end of line then go for the next line
		inx					        \ increment counter
		cpx screenwidth				\ compare with number of characters per line
		bne reader_l2				\ jump if not end of screen line
		jsr reader_space			\ search backward for last space
		lda #&0D				    \ replace it with a CR
		sta (readpointer),y
		jsr reader_incr				\ set pointer to the next character (should be the next word)
		bne reader_l1				\ jumps always
.reader_l3	rts					    \ return
		

\ Increment read pointer
.reader_incr
		inc readpointer				\ increment low byte of pointer
		bne reader_l4				\ jump if no page boundary crossed
		inc readpointer+1			\ increment high byte of pointer
.reader_l4	rts					    \ return

\ Decrement read pointer
.reader_decr
		pha					        \ save accu
		dec readpointer				\ decrement read pointer low byte
		lda readpointer				\ load the result
		cmp #&FF				    \ test for page boundary crossed
		bne reader_l5				\ jump if no page boundary
		dec readpointer+1			\ decrement read pointer high byte
.reader_l5	pla					    \ restore accu
		rts					        \ return

\ Search backwards for a space
\ This routine exits with the pointer pointing to the last space of the line
.reader_space	
		lda (readpointer),y			\ load byte from data
		cmp #' '				    \ test for space
		beq reader_l4				\ jump if it's a space
		jsr reader_decr				\ decrement read pointer
		jmp reader_space			\ continue to search

\ Print the text
.reader_print
		jsr reader_init				\ initialize the read pointer
.reader_l6	ldy #0					\ reset index
		ldx #0					    \ reset line counter
.reader_l7	lda (readpointer),y		\ read data
		beq reader_l11				\ if end of data then jump
		cmp #&0A				    \ is it a LF
		beq reader_l10				\ yes, jump to ignore it
		stx save_x				    \ save x register
		sty save_y				    \ save y register
		cmp #&0D				    \ test for end of line
		bne reader_l8				\ jump if not end of line
		jsr osnewl				    \ print new line
		inc save_x				    \ increment line counter
		jmp reader_l9				\ jump for the next screen
.reader_l8	
        if __ATOM__
        cmp #'a'                    \ check if lower than 'a'
        bmi rd1                     \ jump if it's lower
        cmp #'z'+1                  \ check if higher than 'z'
        bpl rd1                     \ jump if it's higher
        and screenmask              \ convert to uppercase if default Atom vdu
        .rd1
        endif
        jsr oswrch				    \ print data
.reader_l9	ldx save_x				\ restore x register
		ldy save_y				    \ restore y register
.reader_l10	jsr reader_incr			\ increment read pointer
		cpx screenheight			\ test for end of screen
		bne reader_l7				\ not end of screen, jump for next line
		jsr reader_key				\ wait for a key press
		jmp reader_l6				\ jump for the next screen
.reader_l11	rts					    \ return

\ Wait for a key press
.reader_key	jsr osrdch				\ for now this will do.
		ldx save_x				    \ restore x register (might be changed by osrdch)
		ldy save_y				    \ restore y register (might also have changed)
		rts			        		\ return


\ Copy the result from buffer to main memory
.reader_copy_result
        jsr reset_buffer            \ reset pointer to recieve buffer
        lda #<textbuf               \ load low byte of text buffer
        sta writepointer            \ set in zero page
        lda #>textbuf               \ load high byte of text buffer
        sta writepointer+1          \ set in zero page

.reader_copy_l1 jsr wget_search_ipd                     \ search IPD string
                bcs reader_copy_l3                      \ jump if string found
.reader_copy_l2 jmp reader_copy_end                     \ end if no IPD string found 
.reader_copy_l3 jsr wget_read_ipd                       \ read IPD (= number of bytes in datablok)
                lda writepointer+1                      \ load value of high byte write pointer
                cmp #>textbuf                           \ compare with start of buffer
                bne reader_copy_l4                      \ if this is not the first pass, then skip searching for content tag
                jsr reader_search_content               \ search for the "content": " string, that's the start of the response.
                bcc reader_copy_l2                      \ jump if content is not found

                
.reader_copy_l4 jsr wget_test_end_of_data               \ check for end of data
                bcc reader_copy_end                     \ jump to end of copy routine
                jsr read_buffer                         \ read character from receive buffer
                cmp #'"'                                \ is this a quote
                beq reader_copy_end                     \ yes, then it's the end of the answer   @TODO: quotes can be escaped with \"
                cmp #'\'                                \ is it an escaped character?
                bne reader_copy_l5
                jsr read_escape                         \ read the escaped character
.reader_copy_l5 ldy #0                                  \ reset index register
                sta (writepointer),y                    \ write to text buffer
                jsr inc_writeptr                        \ increment write pointer
                jsr dec_blocksize                       \ decrease block size
                beq reader_copy_l1                      \ end of current block is reached, read new ipd
                bne reader_copy_l4                      \ jump to read next character from receive buffer


.reader_copy_end 
                lda #0                                  \ load end of text marker
                sta (writepointer),y                    \ write to text buffer                
                rts                                     \ end routine


\ Following routines are shamelessly copied from *WGET command

.ipd_needle equb "+IPD,"
.wget_search_ipd
 ldy #4                     \ load pointer 
.sipd0
 lda ipd_needle,y           \ load character from search string (= needle)
 sta heap,y                 \ store in workspace
 dey                        \ decrement pointer
 bpl sipd0                  \ jump if characters follow
 lda #5                     \ load needle length
.wget_search
 sta size                   \ store in workspace
 ldy #0                     \ reset pointer
.sipd1
 jsr wget_test_end_of_data  \ check for end of data
 bcc sipd5                  \ jump if no more data
 jsr read_buffer            \ read character from input buffer
 pha                        \ save it on stack
 jsr dec_blocksize          \ decrement block size
 pla                        \ restore character
 cmp heap,y                 \ compare with character in needle
 bne sipd3                  \ jump if not equal
\ CHARACTER MATCH
 iny                        \ character matches, increment pointer 
 cpy size                   \ test for end of needle
 bne sipd4                  \ not the end, continue for next character
 sec                        \ set carry for needle found
 rts                        \ return to calling routine
.sipd3
\ CHARACTER DOES NOT MATCH, RESET POINTER
 ldy #0                     \ character does not match, reset pointer
.sipd4
 jsr wget_test_end_of_data  \ test if any data follows
 bcs sipd1                  \ jump if there is more data
.sipd5
 rts                        \ else return with carry cleared, i.e. needle not found

.contentstring              equs '"', "content", '"', ": ", '"'
.reader_search_content
 ldy #11                    \ initialize pointer
.scrlf1
 lda contentstring,y        \ load character from search string (= needle)
 sta heap,y                 \ write to workspace
 dey                        \ decrement pointer
 bpl scrlf1                 \ jump if more characters to copy
 lda #12                    \ load needle length
 bne wget_search            \ jumps always

.wget_read_ipd
 lda #0                     \ reset block size
 sta blocksize
 sta blocksize+1
 sta blocksize+2
.read_ipd_loop
 jsr read_buffer            \ read character from input buffer
 cmp #':'                   \ test for end of IPD string
 beq read_ipd_end           \ jump if end of IPD string
 sec                        \ set carry for substraction
 sbc #'0'                   \ convert to hex value
 jsr mul10                  \ multiply the IPD value by 10 and add the last value read
 jmp read_ipd_loop          \ repeat for next character
.read_ipd_end
;         lda blocksize+1:jsr printhex
;         lda blocksize:jsr printhex
;         jsr osnewl
 lda blocksize+1            \ load blocksize+1
 ora blocksize              \ ora with blocksize
 rts                        \ return with Z flag indicating the IPD value (zero or non-zero)

.wget_test_end_of_data
 cpx datalen                \ compare pam index with data length LSB
 bne not_end_of_data        \ jump if not equal
 lda datalen+1              \ load MSB data length
 cmp pagereg                \ compare with pam register
 bne not_end_of_data        \ jump if not equal
 clc                        \ end of data, clear carry
 rts                        \ return with c=0 (no more data)
.not_end_of_data
 sec                        \ there is still data, set carry
 rts                        \ return with c=1 (data available)

\ Decrement blocksize. Blocksize is a 24 bit number but in WGET
\ we only use 16 bit values so we skip the third byte.
.dec_blocksize
 sec
 lda blocksize
 sbc #1
 sta blocksize
 cmp #&FF
 bne DBS1
 lda blocksize+1
 sbc #1
 sta blocksize+1
.DBS1 \ CHECK IF blocksize IS 0
 lda blocksize
 ora blocksize+1
 rts

\ Increment write pointer
.inc_writeptr
 inc writepointer           \ increment low byte
 bne inc_wp_l1              \ jump if no page crossing
 inc writepointer+1         \ increment high byte
.inc_wp_l1 rts              \ return

\ read escaped character
.read_escape
 jsr dec_blocksize          \ decrement block size
 \ @TODO: check if blocksize = 0 and read next IPD
 jsr read_buffer            \ read the next character
 cmp #'n'                   \ is it an 'n'?
 bne read_esc_l1            \ no, then return with the next character
 lda #&0D                   \ load value for CR
.read_esc_l1
 rts                        \ return
