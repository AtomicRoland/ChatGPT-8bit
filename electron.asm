\ ChatGPT client for Acorn 8bit micros
\ Settings, definitions and constants for the Acorn Electron, BBC Micro and BBC Master

\ (C)Roland Leurs 2023
\ Version 1.00 August 2023

pagereg = &FCFF
pageram = &FD00

chatbuf = &1D00			\ start address of 256 byte input buffer, must by page aligned!
cmdbuf = &1E00			\ start address of 512 byte command and http request buffer, must by page aligned!
heap = cmdbuf           \ reuse of memory, cmdbuf is used before http request, heap is used after the request
textbuf = &3000			\ start address of text buffer for ChatGPT response

osrdch = &FFE0
oswrch = &FFEE
osasci = &FFE3
osword = &FFF1
osbyte = &FFF4
osnewl = &FFE7

line = &F2              \ address for command line pointer
zp = &40                \ workspace

save_a = zp+2           \ only used in driver, outside driver is may be used for "local" work
save_x = zp+3           \ only used in driver, outside driver is may be used for "local" work
save_y = zp+4           \ only used in driver, outside driver is may be used for "local" work
writepointer = zp+5		\ used for TCP send command, pointer to write buffer (2 bytes)
readpointer = zp+5		\ used for text reader
writelength = zp+7		\ used for TCP send command, length counter (3 bytes, before http transfer)
blocksize = writelength \ used for parsing data (3 bytes, after http transfer)
data_counter = zp+10	\ used for paramters transfer to prdec24 (3 bytes)
pr24pad = zp+13			\ workspace for hexadecimal print to ascii digits (1 byte)
size = zp+13            \ size of search string in fnd (find) function (1 byte)
needle = zp+14          \ pointer to search string in fnd (find) function (2 bytes)
save_cl = zp+16			\ used to save content (query) length (1 byte)
datalen = zp+17         \ number of received bytes (2 bytes)
screenwidth = zp+19		\ number of characters per line
screenheight = zp+20	\ number of lines per screen

start_address = &2000-22 	\ Start address and it containts an ATM header
