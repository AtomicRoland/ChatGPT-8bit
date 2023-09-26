#!/bin/bash

# Assemble for Atom with BeebWiFi board  (Standard Atom, Atom2k14, Atom2k15)
beebasm -D __ATOM__=1 -D __FPGATOM__=0 -D __ELECTRON__=0 -i chatgpt.asm -v > chatgpt-atom-output.lst
mv chatgpt.bin chatgpt-atom.bin
mv chatgpt.atm chatgpt-atom.atm
cp chatgpt-atom.bin /var/www/html

# Assemble for FPGAtom (a.k.a. Atom2k18)
beebasm -D __ATOM__=1 -D __FPGATOM__=1 -D __ELECTRON__=0 -i chatgpt.asm -v > chatgpt-fpgatom-output.lst
mv chatgpt.bin chatgpt-fpgatom.bin
mv chatgpt.atm chatgpt-fpgatom.atm
cp chatgpt-fpgatom.bin /var/www/html

# Assemble for Electron and BBC Micro
beebasm -D __ATOM__=0 -D __FPGATOM__=0 -D __ELECTRON__=1 -i chatgpt.asm -v > chatgpt-electron-output.lst
mv chatgpt.bin chatgpt-electron.bin
cp chatgpt-electron.bin /var/www/html

