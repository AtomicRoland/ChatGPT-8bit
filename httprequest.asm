\ ChatGPT client for Acorn 8bit micros
\ Common settings, definitions and constants 

\ (C)Roland Leurs 2023
\ Version 1.00 August 2023

.tcp_connect	\ Set up the TCP connection to the web service
\ Copy protocol (TCP) to command buffer
		ldy #3				    \ load pointer to command buffer
		ldx #0				    \ load pointer to data
.connect_l1	lda protocol,x		\ read data
		sta cmdbuf,y			\ write to command buffer
		iny				        \ increment pointer to command buffer
		inx				        \ increment data pointer
		cpx #4				    \ is all data copied?
		bne connect_l1			\ jump if not all copied
		
\ Copy host to command buffer (read from host-header)
		ldx #0				    \ load counter
.connect_l2	lda host+6,x		\ read data
		sta cmdbuf,y			\ write to buffer
		iny				        \ increment pointer to command buffer
        inx                     \ increment pointer to data
		cpx #(contenttype-host-8)	\ is all data copied?
		bne connect_l2			\ no, then jump for next character
		
		ldx #0				    \ reset data pointer
.connect_l3	lda port-1,x		\ read data (because the -1 the &0D is also copied ;-)
		sta cmdbuf,y			\ write to buffer
		iny				        \ increment pointer to command buffer
		inx				        \ increment data pointer
		cpx #4				    \ all data copied?
		bne connect_l3			\ no, then jump for next character

if __ELECTRON__
		lda #&08			    \ load OSWORD &65 function number
		sta cmdbuf			    \ write to parameter block
		lda #((cmdbuf+3) div 256)	\ load OSWORD &65 x-value
		sta cmdbuf+1			\ write to parameter block
		lda #((cmdbuf+3) mod 256)	\ load OSWORD &65 y-value
		sta cmdbuf+2			\ write to parameter block
		lda #&65			    \ load A for OSWORD &65
		ldx #(cmdbuf mod 256)	\ load high byte parameter block
		ldy #(cmdbuf div 256)	\ load low byte parameter block
		jmp osword			    \ perform driver function &08: connect to host
else
        lda #&08                    \ load driver function number
		ldx #((cmdbuf+3) mod 256)	\ load high byte parameter block
        ldy #((cmdbuf+3) div 256)	\ load low byte parameter block
		jmp wifidriver              \ execute wifi function and return
endif



.tcp_send	\ Send the data
\ Copy POST command to cmd buffer
		ldx #0				        \ reset read pointer (postcmd)
		ldy #0				        \ reset write pointer (cmdbuf)
		sty writelength			    \ reset data length
		sty writelength+1
		sty writelength+2               
		jsr tcp_send_initbuf		\ initialise buffer pointer
		jsr tcp_send_postcmd		\ copy first part of data to command buffer
		jsr tcp_send_contentlength	\ now write content length (= data entered by user + json length) to cmdbuf
		jsr tcp_send_postdata_1		\ copy the first part of the data to the command buffer
		jsr tcp_send_query		    \ copy the user query to the command buffer
		jsr tcp_send_postdata_2		\ copy the last part of the data to the command buffer
        jsr tcp_set_timeout         \ set the time out for the tcp send command

\ Now prepare the TCP send command
		jsr tcp_send_initbuf		\ set pointer back to start of buffer
		ldx #writepointer		    \ load pointer to parameter block
		lda #&0D			        \ load driver function number (13 = send data)

if __ELECTRON__

		sta save_a			        \ write OSWORD &65 function number to parameter block
		stx save_x			        \ write OSWORD &65 x-value
		sty save_y			        \ write OSWORD &65 y-value
		lda #&65			        \ load A for OSWORD &65
		ldx #save_a			        \ load low byte parameter block (this is the address, not the value!)
		ldy #&00			        \ load high byte parameter block (it's in zero page)
		jsr osword			        \ perform driver function &0D: send data
		lda pagereg                 \ load page register
        sta datalen+1               \ store high byte of data length
        lda &F0                     \ load pointer to byte just after the last received one
        sta datalen                 \ store as low byte of data length
else
		jsr wifidriver              \ execute WiFi function
		lda pagereg                 \ load page register
        sta datalen+1               \ store high byte of data length
        stx datalen                 \ store low byte of data length
endif
        rts                         \ return


\ Copy data to command buffer
\ The data should end with a &00 byte, this byte is not copied.
.tcp_send_postcmd
        ldx #0                      \ reset index
.tcp_send_cp1
		lda postcmd,x			    \ read data
		beq tcp_send_cp2		    \ jump if data = 0 (end of first part)
		jsr tcp_write_buf		    \ write data to command buffer
		inx				            \ increment read pointer
		bne tcp_send_cp1		    \ jump if not all data are copied
.tcp_send_cp2	inx                 \ increment read pointer to skip the &00 byte
        rts				            \ return to calling routine

.tcp_send_postdata_1
        ldx #0                      \ reset index
.tcp_send_cp3
		lda postdata_1,x		    \ read data
		beq tcp_send_cp4		    \ jump if data = 0 (end of first part)
		jsr tcp_write_buf		    \ write data to command buffer
		inx				            \ increment read pointer
		bne tcp_send_cp3		    \ jump if not all data are copied
.tcp_send_cp4	inx                 \ increment read pointer to skip the &00 byte
        rts				            \ return to calling routine

.tcp_send_postdata_2
        ldx #0                      \ reset index
.tcp_send_cp5
		lda postdata_2,x		    \ read data
		beq tcp_send_cp6		    \ jump if data = 0 (end of first part)
		jsr tcp_write_buf		    \ write data to command buffer
		inx				            \ increment read pointer
		bne tcp_send_cp5		    \ jump if not all data are copied
.tcp_send_cp6	inx                 \ increment read pointer to skip the &00 byte
        rts				            \ return to calling routine



\ Copy user entered query to command buffer
\ On entry: write pointer in zeropage
.tcp_send_query
		ldx #0				        \ reset read pointer
.tcp_send_q1	lda chatbuf,x		\ read data
		cmp #&0D			        \ test for end of query
		beq tcp_send_cp2		    \ jump to calling routine if end of query is reached
		jsr tcp_write_buf		    \ write data to command buffer
		inx				            \ increment read pointer
		bne tcp_send_q1			    \ jump always

\ Initializes the zeropage pointer to the command buffer
.tcp_send_initbuf
		lda #(cmdbuf mod 256)		\ load low byte (should be 0)
		sta writepointer		    \ write to zero page
		lda #(cmdbuf div 256)		\ load high byte
		sta writepointer+1		    \ write to zero page
		rts				            \ and return

.tcp_write_buf	
		sty save_y			        \ save Y register
		ldy #0				        \ clear Y register
		sta (writepointer),y		\ write to pointer
		inc writepointer		    \ increment low byte write pointer
		inc writelength			    \ increment low byte data length
		bne tcp_write_buf1		    \ jump if no page boundary crossed
		inc writepointer+1		    \ increment high byte write pointer
		inc writelength+1		    \ increment high byte data length
.tcp_write_buf1	ldy save_y			\ restore Y register
		rts				            \ return to calling routine



\ Write content length to command buffer
.tcp_send_contentlength
        clc                         \ clear carry for addition
		lda save_cl			        \ load the content length
        adc #(crlf-postdata_1-4)    \ add length of empty json query
		sta data_counter		    \ write to workspace
		lda #0				        \ other two bytes are 0
		sta data_counter+2          \ the third byte is always 0 (length is always < 512 bytes)
        adc #0                      \ add carry
		sta data_counter+1		    \ write to second byte of the length (always 0 or 1)
		jmp prdec24buf			    \ add content length to command buffer and return

\ Close connection to server
.tcp_close      lda #&0E			\ load driver function number (14 = close connection)
.tcp_close_1	ldx #&00			\ Load x and y with channel number (ignored, added for future compatibility)
.tcp_close_2	ldy #&00

if __ELECTRON__
		sta save_a			        \ write OSWORD &65 function number to parameter block
		stx save_x			        \ write OSWORD &65 x-value
		sty save_y		        	\ write OSWORD &65 y-value
		lda #&65			        \ load A for OSWORD &65
		ldx #save_a		        	\ load low byte parameter block
		ldy #&00		        	\ load high byte parameter block (it's in zero page)
		jmp osword		        	\ perform driver function &0E: close connection

else
        lda datalen                 \ save the data length because the Atom driver overwrites this after each call
        pha
        lda datalen+1
        pha
        lda #&0E
        jsr wifidriver              \ execute function
        pla                         \ restore the data length
        sta datalen+1
        pla
        sta datalen
        rts                         \ end routine
endif
		
.tcp_set_timeout
        lda #&1D                    \ load function number
        ldx #50                     \ give ChatGPT some time to think about our question ;-)
if __ELECTRON__
        bne tcp_close_2             \ jump to driver call
else
        rts                         \ not implemented on Atom
endif

