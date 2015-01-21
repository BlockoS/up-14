BACKGROUND_TILE = $A732

	.include "system.inc"

	.include "equ.inc"
	.include "macro.inc"
	.include "vdc.inc"
	.include "psg.inc"
	.include "joypad.inc"
    .include "ramcpy.inc"
        
;----------------------------------------------------------------------
; ZP variables declaration
;----------------------------------------------------------------------
	.zp  
__tmp		ds    4  ; todo : maybe put this in equ.inc
__ptr		ds    4  ; todo
scanline	ds    2
fxloopcnt   ds    2
combocnt    ds    2

	.include "effect.inc"
	.include "interrupts.asm"
    .include "joypad.asm"
	.include "gfx.asm"
    .include "math.asm"
	.include "vgm.asm"
	.include "sprite_font.asm"
    
    .code
;----------------------------------------------------------------------
; Main program
;----------------------------------------------------------------------
    .db "main::begin"
main:
    lda    #%11111001
    sta    irq_disable
    stz    irq_status
	
	stz <irq_m
	
    jsr    math_init

	jsr     set_xres256
    lda		#BGMAP_SIZE_64x32
	jsr		set_bat_size
    
    ; set vdc control register
	vreg  #5
	; enable bg, enable sprite, vertical blanking and scanline interrupt
	lda   #%1100_1100
	sta    <vdc_crl
	sta   video_data_l
    
	cli	
    
    vreg   #07
    st1    #$ff
    st2    #$01

    vreg   #08
    st1    #$00
    st2    #$00

    vec_off #VSYNC
    vec_off #HSYNC
    
    set_vec #HSYNC, hsync_handler
    vec_on  #HSYNC

	set_vec #VSYNC, vsync_handler
    vec_on  #VSYNC

    stw    #song_addr, <_si
    lda    #song_bank
    jsr    vgm_init

    smb0   <vgm_status
    
	lda    #3
	ldx    #0
	sta    psgport, X
		
	lda    #%01_000000
	ldx    #4
	sta    psgport, X
	
	lda    #%00_000000
	sta    psgport, X

    tma    #2
    pha
    lda    #bank(sprite_font)
    tam    #2
    stw    #sprite_font, <_si
    stw    #$7340, <_di
    lda    #47
    sta    <_cl
    jsr    load_16x8_sprite_font
    pla
    tam    #2
     
main_loop:
   
    ; save effect page
	tma    #EFFECT_CODE_PAGE
	pha
	; map rotozoom code
	lda    #EFFECT_CODE_BANK
	tam    #EFFECT_CODE_PAGE
   
    stw    #TITLE_FRAME_COUNT, <fxloopcnt
    stw    #TITLE_FRAME_COUNT, <combocnt
    
    ; run title screen
	jsr    rasterBar_init    
    cli
.fx0_loop:
    lda    #0
    jsr    wait_vsync
    jsr    rasterBar_update
    
    jsr    read_joypad_mini
    lda    joy
    cmp    #(JOY_I | JOY_UP)
    bne    .no_match
        decw    <combocnt
.no_match:

    dec    <fxloopcnt
    bne    .fx0_loop
    dec    <fxloopcnt+1
    bne    .fx0_loop
    
    lda    #phase_count
    sta    <_counter
    
    stw   #txtData, <spr_font_ptr
    clx
    
    lda    <combocnt
    ora    <combocnt+1
    bne    .no_hidden_part
        stw   #txtData_hidden, <spr_font_ptr
        ldx   #(TXT_COUNT+2)
.no_hidden_part:

    stx    <current_txt_bloc

    jsr    vgm_update

    ; run rotozoom
	jsr    rotozoom_init
.fx1_loop:
    lda    #0
    jsr    wait_vsync
    jsr    scroller
    jsr    rotozoom_update
    bra    .fx1_loop
        
	; restore mprs
	pla
	tam     #EFFECT_CODE_PAGE
	jmp    main_loop

    .db "main::end"

;----------------------------------------------------------------------
; VSYNC handler
vsync_handler:

    lda    <vdc_reg
    sta    video_reg

    jsr    vgm_update
    
    ply
    plx
    pla
    rti
    
;----------------------------------------------------------------------
; HSYNC handler
hsync_handler:
    stz    irq_status
	irq1_end
    
sprite_font:
    .incbin "data/sprite_font_stripped.dat"    
palette:
    .incbin "data/datastorm.pal"
    
;----------------------------------------------------------------------
; Effects:
;----------------------------------------------------------------------
	.code 
	.bank EFFECT_CODE_BANK
	.org  EFFECT_CODE_PAGE<<13
	
    .include "invtro_title.asm"
    .include "gentiles12.asm"
    .include "rotozoom.asm"
    	
    .data
	.bank ROTOZOOM_DATA_BANK
	.org ROTOZOOM_DATA_PAGE<<13
roto_data:
	.incbin "data/datastorm.dat"
    
    .code
	.bank TITLE_DATA_BANK
	.org  TITLE_DATA_PAGE<<13

raster_bar_start_i:
    .db 0, 16
raster_bar_color_lo:
    .db $ff, $f6, $f6, $f6, $f6, $f6, $f6, $f6
    .db $f6, $f6, $ed, $ed, $ed, $ed, $ed, $ed
    .db $ed, $ed, $ed, $e4, $e4, $e4, $e4, $e4
    .db $e4, $e4, $e4, $e4, $db, $db, $db, $db
    .db $db, $db, $db, $db, $db, $d2, $d2, $d2
    .db $d2, $d2, $d2, $d2, $d2, $d2, $c9, $c9
    .db $c9, $c9, $c9, $c9, $c9, $c9, $c9, $c0
    .db $c0, $c0, $c0, $c0, $c0, $c0, $c0, $c0
    .db $c0, $81, $81, $81, $81, $81, $81, $81
    .db $81, $81, $42, $42, $42, $42, $42, $42
    .db $42, $42, $42, $03, $03, $03, $03, $03
    .db $03, $03, $03, $03, $c4, $c4, $c4, $c4
    .db $c4, $c4, $c4, $c4, $c4, $85, $85, $85
    .db $85, $85, $85, $85, $85, $85, $46, $46
    .db $46, $46, $46, $46, $46, $46, $46, $07
    .db $07, $07, $07, $07, $07, $07, $07, $07
    
raster_bar_color_hi:
    .db $01, $01, $01, $01, $01, $01, $01, $01 
    .db $01, $01, $01, $01, $01, $01, $01, $01 
    .db $01, $01, $01, $01, $01, $01, $01, $01 
    .db $01, $01, $01, $01, $01, $01, $01, $01 
    .db $01, $01, $01, $01, $01, $01, $01, $01 
    .db $01, $01, $01, $01, $01, $01, $01, $01 
    .db $01, $01, $01, $01, $01, $01, $01, $01 
    .db $01, $01, $01, $01, $01, $01, $01, $01 
    .db $01, $01, $01, $01, $01, $01, $01, $01 
    .db $01, $01, $01, $01, $01, $01, $01, $01 
    .db $01, $01, $01, $01, $01, $01, $01, $01 
    .db $01, $01, $01, $01, $00, $00, $00, $00 
    .db $00, $00, $00, $00, $00, $00, $00, $00 
    .db $00, $00, $00, $00, $00, $00, $00, $00 
    .db $00, $00, $00, $00, $00, $00, $00, $00 
    .db $00, $00, $00, $00, $00, $00, $00, $00 

title_pal:
title_pal_lo:
    .db $07, $00, $49, $92, $db, $24, $6d, $b6, $ff, $ff, $38, $38, $38, $38, $38, $38 
title_pal_hi:
    .db $00, $00, $00, $00, $00, $01, $01, $01, $01, $01, $00, $00, $00, $00, $00, $00
    
title_string:
    .db $80, $88, $90, $88, $98, $90, $A0, $A8, $B0 
    
title_data:
    .incbin "data/title.dat"

TITLE_SPRITE_VRAM_ADDR = $3000
    
    .include "data/invtro_txt.inc"

;----------------------------------------------------------------------
; Data:
;----------------------------------------------------------------------
    .include "data/stripped/song.inc"
    
