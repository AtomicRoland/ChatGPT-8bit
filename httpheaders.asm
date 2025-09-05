\ ChatGPT client for Acorn 8bit micros
\ Common settings, definitions and constants

\ (C)Roland Leurs 2023
\ Version 1.3 September 2025

\ Put your personal API keys in the headers. You also might need to change the url of the proxy host
\ and the name of the proxy script.

.protocol	EQUS "TCP",&0D
.port		EQUS "80",&0D

if __TARGET__ = "ChatGPT"
    .postcmd 	    EQUS "POST /proxy.php?https://api.openai.com/v1/chat/completions HTTP/1.1",&0D,&0A
    .host		    EQUS "HOST: proxy.acornelectron.nl",&0D,&0A
    .contenttype	EQUS "Content-Type: application/json",&0D,&0A
    .authorization	EQUS "Authorization: Bearer sk-proj-<your bearer code goes here>",&0D,&0A
    .project        EQUS "OpenAI-Project: proj_<your project code goes here>",&0D,&0A
    .contentlength	EQUS "Content-length: ", &00;
    .postdata_1	    EQUB &0D,&0A,&0D,&0A
                    EQUS "{",&22,"model",&22,": ",&22,"gpt-4o-mini",&22,",",&22,"messages",&22,": [{",&22,"role",&22,": ",&22,"user",&22,", ",&22,"content",&22,": ",&22, &00
    .postdata_2	    EQUS &22,"}]}"
endif

if __TARGET__ = "Copilot"
    \ TODO: enter your resource and deployment names in the URL! Here they're called acorn-ai and acornchat
    .postcmd 	    EQUS "POST /proxy.php?https://acorn-ai.openai.azure.com/openai/deployments/acornchat/chat/completions?api-version=2024-06-01 HTTP/1.1",&0D,&0A
    .host		    EQUS "HOST: proxy.acornelectron.nl",&0D,&0A
    .contenttype	EQUS "Content-Type: application/json",&0D,&0A
    .authorization	EQUS "api-key: <your private API key>",&0D,&0A
    .contentlength	EQUS "Content-length: ", &00;
    .postdata_1     EQUB &0D,&0A,&0D,&0A
                    EQUS "{",&22,"messages",&22,": [{ ",&22,"role",&22,": ",&22,"system",&22,", ",&22,"content",&22,": ",&22,"You are a helpful assistant.",&22," },"
                    EQUS "{",&22,"role",&22,": ",&22,"user",&22,", ",&22,"content",&22,":",&22,&00
    \ TODO: You may adjust max_tokens and temperature to your own preferences
    .postdata_2     EQUS &22,"}],",&22,"max_tokens",&22,":100,",&22,"temperature",&22,":0.5",&22,"}"
endif

if __TARGET__ = "Gemini"
    .postcmd 	    EQUS "POST /proxy.php?https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent HTTP/1.1",&0D,&0A
    .host		    EQUS "HOST: proxy.acornelectron.nl",&0D,&0A
    .contenttype	EQUS "Content-Type: application/json",&0D,&0A
    .authorization	EQUS "x-goog-api-key: <your private API key>",&0D,&0A
    .contentlength	EQUS "Content-length: ", &00;
    .postdata_1     EQUB &0D,&0A,&0D,&0A
                    EQUS "{",&22,"contents",&22,":[{",&22,"parts",&22,": [{",&22,"text",&22,":",&22,&00
    .postdata_2     EQUS &22,"}]}]}"
endif

.crlf		EQUB &0D,&0A,&00
