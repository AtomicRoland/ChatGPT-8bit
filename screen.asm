\ ChatGPT client for Acorn 8bit micros

\ (C)Roland Leurs 2023
\ Version 1.00 August 2023

\ Setup the screen and its parameters
.init_screen
if __ELECTRON__
	lda #22			        \ switch to mode 3
	jsr oswrch
	lda #3
	jsr oswrch
	lda #79			        \ set screen width
	sta screenwidth
	lda #23			        \ set screen height
	sta screenheight
	rts			            \ return to main program
endif

if __ATOM__
    lda #&FF                \ set initial screen mask for Atom display
    sta screenmask
    lda #12                 \ clear the screen
    jsr oswrch
    lda godil+&EF		    \ load godil version number
    and #&F0		        \ mask subversion
    cmp #&10		        \ major version should be 1
    bne no_godil		    \ jump of not 1 (&10)
    \ There is a godil, check VGA80 mode
    lda godil+&E0		    \ load value of mode extension register
    and #&80                \ check mode bit
    beq no_godil            \ jump if not in 80 column mode
    lda #79			        \ set screen width
    sta screenwidth
    lda #39			        \ set screen height
    sta screenheight
    rts			            \ return to main program

.no_godil
    lda &208                \ test if default Atom screen is active
    cmp #&52                \ test low byte of wrch vector
    bne not_default         \ jump if not default value
    lda &209                \ double check
    cmp #&FE
    bne not_default
    lda #31                 \ set screen width
    sta screenwidth
    lda #15                 \ set screen height
    sta screenheight
    lda #&DF                \ set screen mask
    sta screenmask
    rts                     \ return

.not_default
	lda #39			        \ set screen width
	sta screenwidth
	lda #23			        \ set screen height
	sta screenheight
	rts     			    \ return to main program
endif

if __SYSTEM5__
    lda #12                 \ clear the screen
    jsr oswrch
	lda #SCREENWIDTH        \ set screen width
	sta screenwidth
	lda #SCREENHEIGTH       \ set screen height
	sta screenheight
	rts     			    \ return to main program
endif

\ Display a welcome message
.welcome_msg
	jsr printtext
	equs "WELCOME TO CHATGPT CLIENT V1.1",&0D
	equs "==============================",&EA
	rts

\ Show the input prompt
.display_prompt
	jsr printtext
    equb &0D,&0D
	equs "prompt > ",&EA
	rts

\ Ask if user wants to quit, ends with jump to read character routine
.prompt_end
	jsr printtext
	equs "No input, do you want to quit? ",&EA
	jmp osrdch


\ Sound a beep
.beep	lda #7			\ for now, we do just a simple bell
	jmp oswrch		\ ring the bell and return


\ Read input from keyboard until <return> is pressed. Returns with the number of characters in Y. Maximum number
\ of chacters is limited to 255.
.read_input
	ldy #0			\ reset character pointer
.read_l1
	jsr osrdch		\ read a character
	cmp #&0D		\ is it <return>
	beq read_end	\ yes, then jump to the end of the routine
	cmp #&7F		\ is it <delete>
	bne read_l2		\ no, go store it in the buffer
	cpy #0			\ buffer empty?
	beq read_beep	\ if yes then give a signal and get next character
    dey             \ decrease the pointer
    jsr oswrch      \ erase the last character from screen
    jmp read_l1     \ jump for next character
.read_l2
	cpy #&FE		\ is the buffer full (except for the last &0D)?
	beq read_beep	\ if yes then give a signal and get next character
	cmp #&20		\ is it a control character?
	bmi read_beep	\ if yes then ignore it
	sta chatbuf,y	\ we like it, store it in the buffer
    jsr oswrch      \ print the character
	iny			    \ increment the pointer
	bne read_l1		\ this will always jump
.read_beep
	jsr beep		\ do beep
	jmp read_l1		\ go for the next character
.read_end
    sta chatbuf,y   \ store the terminating CR in the buffer
	rts			    \ return with data in buffer and Y contains number of characters

