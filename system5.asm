\ ChatGPT client for Acorn 8bit micros
\ Settings, definitions and constants for the Acorn System 5

\ (C)Roland Leurs 2024
\ Version 1.00 August 2024

SCREENWIDTH = 39
SCREENHEIGTH = 23

uart    = &B30                 \ Base address for the 16C2552 UART B-port
pagereg = &BFF
pageram = &D00

chatbuf = &3D00			\ start address of 256 byte input buffer, must by page aligned!
cmdbuf = &3E00			\ start address of 512 byte command and http request buffer, must by page aligned!
heap = cmdbuf           \ reuse of memory, cmdbuf is used before http request, heap is used after the request
textbuf = &4000			\ start address of text buffer for ChatGPT response

osrdch = &FFE3
oswrch = &FFF4
osnewl = &FFED

line = &F2              	\ address for command line pointer
zp = &60                	\ workspace

save_a = zp+2           	\ only used in driver, outside driver is may be used for "local" work
save_x = zp+3           	\ only used in driver, outside driver is may be used for "local" work
save_y = zp+4           	\ only used in driver, outside driver is may be used for "local" work
paramblok = save_x
writepointer = zp+5		    \ used for TCP send command, pointer to write buffer (2 bytes)
data_pointer = zp+5         \ used by CIPSEND routine in driver.asm (2 bytes, might conflict!)
readpointer = zp+5		    \ used for text reader
writelength = zp+7		    \ used for TCP send command, length counter (3 bytes, before http transfer)
blocksize = writelength     \ used for parsing data (3 bytes, after http transfer)
data_counter = zp+10		\ used for parameters transfer to prdec24 (3 bytes)
pr24pad = zp+13		    	\ workspace for hexadecimal print to ascii digits (1 byte)
size = zp+13                \ size of search string in fnd (find) function (1 byte)
needle = zp+14              \ pointer to search string in fnd (find) function (2 bytes)
save_cl = zp+16			    \ used to save content (query) length (1 byte)
datalen = zp+17             \ number of received bytes (2 bytes)
screenwidth = zp+19		    \ number of characters per line (1 byte)
screenheight = zp+20		\ number of lines per screen (1 byte)
time_out = zp+21            \ time out value used by driver and serial.asm (1 byte)
timer = zp+22               \ timer used by serial.asm (3 bytes)
screenmask = zp+25          \ value to mask lower case characters for Atom display (1 byte)

start_address = &3000-22 	\ Start address and it containts an ATM header
