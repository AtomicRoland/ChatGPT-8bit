\ Error messages for Atom ChatGPT client
\ (c) Roland Leurs, May 2020

\ Error handling
\ Version 1.00


\ On entry X points to the error message relative to the beginning of the error table
.error                      lda error_table,x       \ load character from message
                            jsr oswrch
                            inx
                            cmp #&0D
                            bne error
                            brk

.error_table                                        \ Table with error messages

.error_device_not_found     equs "DEVICE?",&0D
.error_no_response          equs "NO RESPONSE",&0D
.error_buffer_full          equs "BUFFER FULL",&0D
.error_buffer_empty         equs "BUFFER EMPTY",&0D
.error_no_date_time
.error_no_version           equs "NO RESPONSE",&0D
.error_not_implemented      equs "NOT IMPLEMENTED",&0D
.error_bad_option           equs "OPTION?",&0D
.error_bad_protocol         equs "PROTOCOL?",&0D
.error_http_status          equs "HTTP ERROR",&0D
.error_no_pagedram          equs "NO PAGED RAM",&0D
.error_disabled             equs "WIFI DISABLED",&0D
.error_opencon              equs "CONNECT ERROR",&0D
.error_bad_param            equs "PARAMETER?",&0D
.error_bank_nr              equs "BANK?",&0D
.error_not_swram            equs "NOT SWRAM OR WPROT", &0D

\ Let op: de error tabel is vol (256 bytes) !