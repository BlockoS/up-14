TITLE_FRAME_COUNT = 512

RASTER_BAR_START_Y = 220
RASTER_BAR_STEP_ANGLE = 240
RASTER_BAR_SPEED = 64
RASTER_BAR_SIZE = 128
RASTER_BAR_RESOLUTION = 18 
RASTER_BAR_STEP = 65536 / RASTER_BAR_RESOLUTION

TITLE_BG_COLOR = $1ff
    
    .rsset _zp_fx
raster_bar_angle    .rs 2
raster_bar_start_y  .rs 4
raster_bar_offset   .rs 2
raster_bar_t        .rs 2
raster_bar_index    .rs 1
raster_bar_y_count  .rs 2
raster_bar_i        .rs 1

    .bss
raster_bar_y        .ds 128

    .code
    
;----------------------------------------------------------------------
;
rasterBar_init:
    ; Disable interrupts
	vec_off #VSYNC
	vec_off #HSYNC
    
    ; map data
	lda    #TITLE_DATA_BANK
	tam    #TITLE_DATA_PAGE

    st0    #00
    st1    #low(TITLE_SPRITE_VRAM_ADDR)
    st2    #high(TITLE_SPRITE_VRAM_ADDR)
    st0    #02
    tia    title_data, $0002, 3840
    
    stz    <raster_bar_angle
    stz    <raster_bar_angle+1
    stz    <raster_bar_start_y
    stz    <raster_bar_start_y+1
    stz    <raster_bar_offset
    stz    <raster_bar_offset+1
    stz    <raster_bar_index
    stz    <raster_bar_y_count
    stz    <raster_bar_i
    
    ; load title palette
    lda    #low(0)
    sta    color_reg_l
    lda    #high(0)
    sta    color_reg_h
    clx
.pal_loop:
    lda    title_pal_lo, X
    sta    color_data_l
    lda    title_pal_hi, X
    sta    color_data_h
    inx
    cpx    #16
    bne    .pal_loop
    
    lda    #BGMAP_SIZE_32x64
	jsr    set_bat_size

	jsr    set_xres256
	
    stz    color_ctrl

    ; setup bg tile
    st0    #$00
    stw    #(BACKGROUND_TILE << 4), video_data
    
    st0    #$02
    st1    #$00
    ldx    #32
.tile_cleanup:    
    st2    #$00
    dex
    bne    .tile_cleanup
    
    ; clean BAT
    st0    #$00
    st1    #$00
    st2    #$00
    
    st0    #$02
    ldy    bat_height
.bat_clean_y:
    ldx    bat_width
.bat_clean_x:
    stw    #BACKGROUND_TILE, video_data
    dex
    bne    .bat_clean_x
    dey
    bne    .bat_clean_y
    
    ; setup BAT
    stw    #$01A0, <_di
    stw    #$0300, <_si
    cly
.bat_loop_y:
    st0    #$00
    lda    <_di
    sta    video_data_l
    clc
    adc    #$20
    sta    <_di
    lda    <_di+1
    sta    video_data_h
    adc    #$00
    sta    <_di+1

    st0    #$02
    clx
.bat_loop_x:
        lda    <_si
        sta    video_data_l
        lda    <_si+1
        sta    video_data_h
        incw   <_si
        
    inx
    cpx    #(240/8)
    bne    .bat_loop_x
    
    iny
    cpy    #4
    bne    .bat_loop_y
    
    st0    #7
    st1    #$fa
    st2    #$ff

    st0    #8
    st1    #12
    st2    #00

    
	; set and enable vdc interrupts;
	set_vec #VSYNC,rasterBarVsyncProc
	vec_on  #VSYNC
	set_vec #HSYNC,rasterBarHsyncProc
	vec_on  #HSYNC
    
	; set vdc control register
	vreg  #5
	; enable bg, enable sprite, vertical blanking and scanline interrupt
	lda   #%11001100
	sta    <vdc_crl
	sta   video_data_l
	st2   #$00
        
    rts
    
;----------------------------------------------------------------------
;
rasterBar_update:
    addw   #RASTER_BAR_SPEED, <raster_bar_offset 
    cmp    #high(RASTER_BAR_STEP)
    bcc    .no_reset
    bne    .reset
    lda    <raster_bar_offset
    cmp    #low(RASTER_BAR_STEP)
    bcc    .no_reset
.reset:
        stwz   <raster_bar_offset
.no_reset:
    stw    <raster_bar_offset, <raster_bar_t
    
    addw   #RASTER_BAR_STEP_ANGLE, <raster_bar_angle
    tax
    adc    #high(RASTER_BAR_STEP_ANGLE)
    sta    <raster_bar_angle+1
    
    cly
    lda    sinTable, X
    bpl    .l0
        ldy   #$ff
.l0:
    clc
    adc    #low(RASTER_BAR_START_Y)
	sta    <raster_bar_start_y
    tya
    adc    #high(RASTER_BAR_START_Y)
	;lsr    A
    ;ror    <raster_bar_start_y
    lsr    A
    sta    <raster_bar_start_y+1
    ror    <raster_bar_start_y
    
    stz    <raster_bar_y_count
    
    lda    <raster_bar_i
    eor    #1
    tay
    lda    raster_bar_start_i, Y
    tax
    
    lda    <raster_bar_t+1
    clc
    adc    #127
    tay
    lda    sinTable, Y
    cmp    #$80
    ror    A
    clc
    adc    #RASTER_BAR_SIZE
    sta    raster_bar_y+32, X
    lsr    A
    sta    raster_bar_y, X
    inx
    
.loop:    
    lda    <raster_bar_offset+1
    clc
    adc    #127
    cmp    <raster_bar_t+1
    bcs    .update
.no_update:
        bra    .loop_end
.update:
    addw   #RASTER_BAR_STEP, <raster_bar_t
    adc    #127
    tay
    lda    sinTable, Y
    cmp    #$80
    ror    A
    clc
    adc    #RASTER_BAR_SIZE
    
    sta    raster_bar_y+32, X
    lsr    A
    sta    raster_bar_y, X
    
    cmp    (raster_bar_y-1), X
    beq    .stalled
    bcs    .continue
.stalled:
        bra    .loop
.continue:
    
    inx
    bra    .loop
.loop_end:
    stx    <raster_bar_y_count
    
    lda    <raster_bar_i
    eor    #1
    sta    <raster_bar_i
    sta    <raster_bar_i+1

    rts
    
;----------------------------------------------------------------------
; VSYNC (raster bar)
rasterBarVsyncProc:
    ldy    <raster_bar_i
    lda    raster_bar_start_i, Y
    sta    <raster_bar_index
    tay
    
    stw    <raster_bar_start_y, <raster_bar_start_y+2
    
    lda    <raster_bar_y_count
    sta    <raster_bar_y_count+1
    
    stz    color_reg_l
    stz    color_reg_h
    
    lda    #low(TITLE_BG_COLOR)
    sta    color_data_l
    lda    #high(TITLE_BG_COLOR)
    sta    color_data_h
    
    st0    #6
    lda    raster_bar_y, Y
    clc
    adc    <raster_bar_start_y+2
    sta    video_data_l
    lda    <raster_bar_start_y+3
    adc    #0
    sta    video_data_h

    jsr    vgm_update
	irq1_end

    
;----------------------------------------------------------------------
; HSYNC (raster bar)
rasterBarHsyncProc:
    inc    <raster_bar_index
    ldy    <raster_bar_index
    cpy    <raster_bar_y_count+1
    bcs    .no_update
.update:
    lda    raster_bar_y+32, Y
    clc
    adc    (raster_bar_y+31), Y
    bpl    .none
        eor   #$ff
        inc   A
.none
    tax
    stz    color_reg_l
    stz    color_reg_h
    lda    raster_bar_color_lo, X
    sta    color_data_l
    lda    raster_bar_color_hi, X
    sta    color_data_h
 
    st0    #6
    lda    raster_bar_y, Y
    clc
    adc    <raster_bar_start_y+2
    sta    video_data_l
    cla
    adc    <raster_bar_start_y+3
    sta    video_data_h
  
    irq1_end

.no_update:    
    stz    color_reg_l
    stz    color_reg_h
    lda    #low(TITLE_BG_COLOR)
    sta    color_data_l
    lda    #high(TITLE_BG_COLOR)
    sta    color_data_h

    irq1_end

;----------------------------------------------------------------------
; Data:
;----------------------------------------------------------------------


