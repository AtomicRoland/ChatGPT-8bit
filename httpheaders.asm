\ ChatGPT client for Acorn 8bit micros
\ Common settings, definitions and constants

\ (C)Roland Leurs 2023
\ Version 1.00 August 2023

\ Put your personal API key in line 13 after 'Bearer'. You also might need to change the url of the proxy host
\ and the name of the proxy script.

.protocol	EQUS "TCP",&0D
.port		EQUS "80",&0D
.postcmd 	EQUS "POST /proxy.php?https://api.openai.com/v1/chat/completions HTTP/1.1",&0D,&0A
.host		EQUS "HOST: proxy.acornelectron.nl",&0D,&0A
.contenttype	EQUS "Content-Type: application/json",&0D,&0A
.authorization	EQUS "Authorization: Bearer YOUR-API-KEY-SHOULD-GO-HERE",&0D,&0A
.contentlength	EQUS "Content-length: ", &00;
.postdata_1	EQUB &0D,&0A,&0D,&0A
		EQUS "{",&22,"model",&22,": ",&22,"gpt-3.5-turbo-16k",&22,",",&22,"messages",&22,": [{",&22,"role",&22,": ",&22,"user",&22,", ",&22,"content",&22,": ",&22, &00
.postdata_2	EQUS &22,"}]}"
.crlf		EQUB &0D,&0A,&00
