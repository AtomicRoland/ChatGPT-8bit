\ AI client for Acorn 8bit micros
\ (C)Roland Leurs 2023 - 2024
\ Version 1.10 August 2024

__DEBUG__ = 0               \ If enabled then all serial input/output is echoed to serial port A

if __SERVICE__ = 1
__TARGET__ = "ChatGPT"
endif

if __SERVICE__ = 2
__TARGET__ = "Copilot"
endif

if __SERVICE__ = 3
__TARGET__ = "Gemini"
endif

if __ELECTRON__ = 1
include "electron.asm"
endif

if __ATOM__ = 1
include "atom.asm"
endif 

if __SYSTEM5__ = 1
include "system5.asm"
endif

org start_address

.atmheader
if __TARGET__ = "ChatGPT"
            equs "CHATGPT",0,0,0,0,0,0,0,0,0
endif
if __TARGET__ = "Copilot"
            equs "COPILOT",0,0,0,0,0,0,0,0,0
endif
if __TARGET__ = "Gemini"
            equs "GEMINI",0,0,0,0,0,0,0,0,0,0
endif
            equw chatstart
            equw chatstart
            equw chatend-chatstart

\ Rom header
.chatstart	jmp chatgpt
        include "httpheaders.asm"
		include "httprequest.asm"
		include "routines.asm"
		include "screen.asm"
		include "reader.asm"
        if __ATOM__ = 1 OR __SYSTEM5__ = 1
        include "driver.asm"
        include "serial.asm"
        include "errors.asm"
        endif

.chatgpt	jsr init_screen				\ Initialize the screen, MODE3 for Elk/BBC, VGA80 for Atom with Godil
    		jsr welcome_msg				\ print the welcome message
.prompt		jsr display_prompt			\ show the prompt 
		    jsr read_input				\ read user's input until return pressed
		    jsr osnewl                  \ set cursor to the next line
            cpy #0					    \ is there any data entered?
    		bne connect				    \ yes, setup the connection
	    	jsr prompt_end				\ ask if user wants to quit
            ora #&20                    \ convert to lowercase
		    cmp #'y'				    \ did user press 'y'
		    bne prompt				    \ no, then get next input
		    jmp osnewl				    \ quit the program by printing a new line

.connect	sty save_cl				    \ save the user query length
		    jsr tcp_connect				\ setup tcp connection to server
        	jsr tcp_send				\ send the command to the (proxy)server

            jsr reader_copy_result      \ copy the effective data to our text buffer in lower memory
		    jsr tcp_close				\ close the connection
            jsr reader_format           \ adapt the text to the screen width
            jsr reader_print            \ print the text
            jmp prompt                  \ jump for next question

.chatend             

SAVE "aiclient.atm", atmheader, chatend
SAVE "aiclient.bin", chatstart, chatend
