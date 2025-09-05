#!/bin/bash

# Service, to which AI service do you want to talk?
# 1 => aiclient
# 2 => Copilot
# 3 => Gemini
SERVICE=2

# Assemble for Atom with BeebWiFi board  (Standard Atom, Atom2k14, Atom2k15)
beebasm -D __ATOM__=1 -D __FPGATOM__=0 -D __ELECTRON__=0  -D __SYSTEM5__=0 -D __SERVICE__=$SERVICE -i aiclient.asm -v > aiclient-atom-output.lst
mv aiclient.bin aiclient-atom.bin
mv aiclient.atm aiclient-atom.atm
cp aiclient-atom.bin /var/www/html

# Assemble for FPGAtom (a.k.a. Atom2k18)
beebasm -D __ATOM__=1 -D __FPGATOM__=1 -D __ELECTRON__=0 -D __SYSTEM5__=0 -D __SERVICE__=$SERVICE -i aiclient.asm -v > aiclient-fpgatom-output.lst
mv aiclient.bin aiclient-fpgatom.bin
mv aiclient.atm aiclient-fpgatom.atm
cp aiclient-fpgatom.bin /var/www/html

# Assemble for Electron and BBC Micro
beebasm -D __ATOM__=0 -D __FPGATOM__=0 -D __ELECTRON__=1 -D __SYSTEM5__=0 -D __SERVICE__=$SERVICE -i aiclient.asm -v > aiclient-electron-output.lst
mv aiclient.bin aiclient-electron.bin
cp aiclient-electron.bin /var/www/html

# Assemble for Acorn System5
beebasm -D __ATOM__=0 -D __FPGATOM__=0 -D __ELECTRON__=0 -D __SYSTEM5__=1 -D __SERVICE__=$SERVICE -i aiclient.asm -v > aiclient-system5-output.lst
mv aiclient.bin aiclient-system5.bin
mv aiclient.atm aiclient-system5.atm
cp aiclient-system5.bin /var/www/html


