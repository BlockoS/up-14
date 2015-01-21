
	.code
;----------------------------------------------------------------------
; name : read_joypad
;
; description :	 poll joypad
;
; 'joyport' (location $1000) is a control read/write port which only reads
; 4 bits at a time; the program uses joyport to toggle the multiplex line
;
; real logic values are read into the port - the joypad's keys are default
; high, and 'pulled' low when pressed.  Therefore, these values must be
; inverted/complemented to yield values where '1' means 'pressed'
;
; bit values for joypad bytes: (MSB = #7; LSB = #0)
; -------------------------------------------------
; bit 0 (ie $01) = I
; bit 1 (ie $02) = II
; bit 2 (ie $04) = 'select'
; bit 3 (ie $08) = 'run'
; bit 4 (ie $10) = UP
; bit 5 (ie $20) = RIGHT
; bit 6 (ie $40) = DOWN
; bit 7 (ie $80) = LEFT
; ----
; bit values for joypad 6-button bytes: (MSB = #7; LSB = #0)
; ----------------------------------------------------------
; bit 0   (ie $01) = III
; bit 1   (ie $02) = IV
; bit 2   (ie $04) = V
; bit 3   (ie $08) = VI
; bit 4-7 (ie $F0) = exists (all on or all off)
; ----

; Note: Read twice for 6-button joysticks.
; First read should be for 'joy' and second for
; 'joy6'; need to hide values temporarily while
; scanning twice.
;
read_joypad:
	lda		joyena			; suppress reset during individual read
	pha
	stz		joyena

	jsr		.readjoys

	tii		joy, joy6, 5		; move to 6-button area

	jsr		.readjoys

	pla
	sta		joyena

	tii		joytmp, joyold, 5	; restore past info from stash
	tii		joytmp6, joyold6, 5

	;
	; the '.l2' loop determines if first or
	; second scans imply a 6-button joystick,
	; and rearrange bytes if out of order,
	; and zero the joy6 area if necessary
	;
	cly
.l2:
	lda		joy,Y				; check if 6-button joypad, and
	tax
	and		#JOY_TYPE6			; scans became backwards somehow
	cmp		#JOY_TYPE6
	bne		.notswap
	lda		joy6,Y				; then swap them if they need it
	sta		joy,Y
	sax
	sta		joy6,Y

.notswap:
	lda		joy6,Y				; verify whether a 6-button exists
	and		#JOY_TYPE6
	cmp		#JOY_TYPE6
	beq		.type6
	cla
	sta		joy6,Y				; not 6-button, so clear extra entry

.type6:
	lda		joy6,Y				; strip off unused bits
	and		#(JOY_III | JOY_IV | JOY_V | JOY_VI | JOY_TYPE6)
	sta		joy6,Y				; clear unnecessary bits

	;
	; The '.l2a' area sets appropriate values
	; for all of the joytrg and joybuf areas
	;
.l2a:
	lda		joy,Y
	eor		joyold,Y			; check against previous value
	and		joy,Y
	sta		joytrg,Y			; 'new key pressed' key values

	; ----
	; buffered 'new key pressed'
	; see joy_events();
	;
	ora		joybuf,Y			; collect 'new key pressed'
	sta		joybuf,Y

	; ----
	; repeat the joyold/joytrg/joybuf stuff
	; for 6-button values
	;
	lda		joy6,Y
	eor		joyold6,Y
	and		joy6,Y
	sta		joytrg6,Y
	ora		joybuf6,Y
	sta		joybuf6,Y

	; ----
	; next joypad
	;
	iny
	cpy		#$05				; cycle for next of 5 joypads
	bcc		.l2

	; ----
	; return
	;
	tii		joy, joytmp, 5		; stash values for next read because CDROM
	tii		joy6, joytmp6, 5	; may force another read between VSYNC's

	rts

	; ----
	; read 5 joystick values into 'joy' buffer area
	;
.readjoys:
	tii		joy, joyold, 5
	lda		#$01				; reset joypad port to joystick #1
	sta		joyport
	lda		#$03
	sta		joyport
	jsr		.delay

	cly							; counter for 5 joypads
.rdlp:
	lda		#$01				; first nybble
	sta		joyport
	bsr		.delay				; required delay (approx 9 cycles)

	lda		joyport				; fetch first nybble
	asl		A					; shift it to 'high' position within byte
	asl		A
	asl		A
	asl		A
	sta		joy,Y				; store in 'current' area
	stz		joyport				; toggle port (to read other 4 key values)
	bsr		.delay				; delay again
	lda		joyport				; fetch second nybble
	and		#$0F				; clear unused bits
	ora		joy,Y				; merge 2 nybbles into 1 byte
	eor		#$FF				; reset 'sense' of keys
	sta		joy,Y				; store it
	iny
	cpy		#$05				; cycle for next of 5 joypads
	bcc		.rdlp

	rts

; small delay
.delay:
	ldx		#3
.l6:
	dex
	bne		.l6
	rts

; minimalistic version (only reads 1 joypad)
read_joypad_mini:
	lda		joyena			    ; suppress reset during individual read
	pha
	stz		joyena
    
    lda		#$01			    ; reset joypad port to joystick #1
	sta		joyport
	lda		#$03
	sta		joyport
	
    nop                         ; small delay
    nop
    nop
    nop

    lda		#$01				; first nybble
	sta		joyport

    nop                         ; small delay
    nop
    nop
    nop

    lda		joyport				; fetch first nybble
	asl		A					; shift it to 'high' position within byte
	asl		A
	asl		A
	asl		A
	sta		joy 				; store in 'current' area
	stz		joyport				; toggle port (to read other 4 key values)
	
    nop                         ; small delay
    nop
    nop
    nop
    
	lda		joyport				; fetch second nybble
	and		#$0F				; clear unused bits
	ora		joy 				; merge 2 nybbles into 1 byte
	eor		#$FF				; reset 'sense' of keys
	sta		joy 				; store it
    
    pla
	sta		joyena
    
    rts
    
.bitmsk:
	.db $01,$02,$04,$08,$10		; bit-masks for check-reset

       
