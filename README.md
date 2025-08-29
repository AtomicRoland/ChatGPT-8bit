# ChatGPT client for 8bit Acorn computers

This program will enable your 8bit Acorn computer to communicatie with the OpenAI API. You'll need an ESP8266-based WiFi board such as ElkWiFi (Electron)
or BeebWiFi (BBC Micro, BBC Master or Acorn Atom with 1MHz bus adapter). WiFi ROM Version 0.32 or higher is required. 

You have to create a personal API key at the OpenAI website, see https://platform.openai.com/docs/api-reference/authentication for more information. 

The program is written in BeebAsm which can be found at https://github.com/stardot/beebasm/

# ****************************************************************************************************************************************
# * PLEASE NOTE THAT THIS SOFTWARE IS NOT SECURE! YOUR PERSONAL API KEY IS STORED IN THE BINARY RUN-TIME FILES AND CAN EASILY GET STOLEN *
# * BY EVERY ONE WITH PHYSICAL ACCESS TO YOUR COMPUTER OR STORAGE MEDIUM!                                                                *
# * **************************************************************************************************************************************

All of the processing is done by your Acorn computer. There is however a little practical issue .... your Acorn cannot communicate over HTTPS. So I 
added a little proxy program. I strongly suggest you run this proxy program on your own (preferably local) webserver. You are allowed to use my proxy
service as defined in httpheaders.asm but beware: I can read your API key and all other sensible data. I promise ... I will not take any advantage
of this privilege. But still, use it on your own risk.

Having said that, the best way to protect your money is just to pay small amounts like $5 to your OpenAI wallet. Be warned, be carefull but also
enjoy chatting with ChatGPT from your old Acorn machine :-)

# Getting started
* Step 1: get an API key (you may be charged by OpenAI)
* Step 2: download or clone this source code
* Step 3: add your API key and project ID to httpheaders.asm, optionally: change the URL of the proxy server
  optional: you can also select a model, I have tested versions 4o-mini (preffered) and 5-mini
* Step 4: run the ./build.sh script (beebasm required)
* Step 5: transfer the assembled binary file to your computer

For BBC and Electron use 'chatgpt-electron.bin'

For Acorn Atom with BeebWiFi card use 'chatgpt-atom.bin' (or the .atm file which has an ATM header for the AtoMMC filing system)

For Atom2k18 (a.k.a. FPGAtom) with my first (experimental) WiFi board the 'chatgpt-fpgatom.bin' file is generated. Almost nobody can use this.

If you have any questions or suggestions please use the StarDot forum or open an issue on this Github repository.

Happy Chatting!



Notes to version 1.2 - August 2025 -
====================================

OpenAI switched to project based API keys. So you need to add a project key. Because of the
much longer API keys (even up to one hundred characters) and an additional project identifier,
the original code had a roll-over of the X-index register. So the routine to copy the headers
into the send buffer had to be rewritten. Also the buffer space had to be increased (now 1024 
bytes instead of 512). So a little bit more memory space is required. But the code still
works without any specific memory expansions.