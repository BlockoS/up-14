SATB_ADDR = $7f00

    .zp
spr_font_base  .ds 2
spr_font_phase .ds 1
spr_font_index .ds 1
spr_font_x .ds 2
spr_font_y .ds 2
spr_font_count .ds 1
spr_font_ptr .ds 2
spr_font_data .ds 1

current_txt_bloc .ds 1

    .code
;----------------------------------------------------------------------
; name : load_16x8_sprite_font
;
; description : Load a 16x8 font as sprite.
;
; in :  _si = font data
;       _di = VRAM destination
;       _cl = glyph count
;
load_16x8_sprite_font:
    st0    #$00
	lda    <_di
    sta    <spr_font_base
    sta    video_data_l
	lda    <_di+1
    sta    video_data_h

    ldx    #5
.l0:
    lsr    A
    ror    <spr_font_base
    dex
    bne    .l0
    sta    <spr_font_base+1
    
    st0    #$02
	
    lda    #MEMCPY_SRC_INC_DEST_ALT
    sta    _hrdw_memcpy_mode
    stw    #video_data_l, _hrdw_memcpy_dst
    stw    <_si, _hrdw_memcpy_src
    stw    #16, _hrdw_memcpy_len
    
    ldx    <_cl
.l1:
    jsr    hrdw_memcpy
    addw   #16, _hrdw_memcpy_src
    st1    #$00
    st2    #$00
    st2    #$00
    st2    #$00
    st2    #$00
    st2    #$00
    st2    #$00
    st2    #$00
    st2    #$00

    jsr    hrdw_memcpy
    addw   #16, _hrdw_memcpy_src
    st1    #$00

    ldy    #5
.l2:
    st2    #$00
    st2    #$00
    st2    #$00
    st2    #$00
    st2    #$00
    st2    #$00
    st2    #$00
    st2    #$00
    dey
    bne    .l2
    
    dex
    bne    .l1
    
    ldx    #$16
    lda    #$00
    sta    color_reg_l
    lda    #$01
	sta    color_reg_h

.clean_pal
    stz    color_data_l
    stz    color_data_h
    dex
    bne    .clean_pal
    
    lda    #$02
    sta    color_reg_l
    lda    #$01
	sta    color_reg_h
    lda    #$ff
    sta    color_data_l
    lda    #$01
    sta    color_data_h
    
    rts
    
;----------------------------------------------------------------------
; name : 
;
; description :
;
; in :  spr_font_ptr = String data address
;
print_line_16x8:
    st0    #$0f     ; Enable VRAM SATB DMA
    st1    #$10 
    st2    #$00
    
    st0    #$13     ; Set SATB address
    st1    #low(SATB_ADDR)
    st2    #high(SATB_ADDR)
    
    st0    #$00
    st1    #low(SATB_ADDR)
    st2    #high(SATB_ADDR)
 
    st0    #$02

    cly
    clx
.l0:
    lda    [spr_font_ptr], Y             ; Line count
    iny
    sta    <_cl
    
    lda    [spr_font_ptr], Y             ; String bloc y position
    iny
    sta    <spr_font_y
    stz    <spr_font_y+1
    
.l1:
    lda    [spr_font_ptr], Y             ; String line x position
    iny
    asl    A
    sta    <spr_font_x
    stz    <spr_font_x+1
    rol    <spr_font_x+1

.l2:
    lda    [spr_font_ptr], Y             ; Fetch char
    iny

    cmp    #$ff                 ; eol
    beq    .eol
    
    cmp    #$fe                 ; space
    beq    .space
        pha
        
        ; Sprite position
        ; -- Y
        lda    <spr_font_y
        sta    video_data_l
        lda    <spr_font_y+1
        sta    video_data_h

        ; -- X
        lda    <spr_font_x
        sta    video_data_l
        lda    <spr_font_x+1
        sta    video_data_h
        
        ; Vram addr
        pla
        sta    <spr_font_data
        asl    A
        clc
        adc    <spr_font_base
        sta    video_data_l
        cla
        adc    <spr_font_base+1
        sta    video_data_h

        ; flags
        st1    #$80
        st2    #$00
    
        inx
.next_char:
        phy
        ldy    <spr_font_data
        lda    txtSpace, Y
        clc
        adc    <spr_font_x
        sta    <spr_font_x
        lda    <spr_font_x+1
        adc    #0
        sta    <spr_font_x+1
        ply
        
    bra    .l2
.space:
        addw   #TXT_SPACING, <spr_font_x
    bra    .l2

.eol:
    tya
    clc
    adc    <spr_font_ptr
    sta    <spr_font_ptr
    lda    <spr_font_ptr+1
    adc    #$00
    sta    <spr_font_ptr+1
    cly
    
    dec    <_cl
    beq    .end
        addw   #TXT_V_SPACING, <spr_font_y
    jmp    .l1
    
.end:
    
    stx    <spr_font_count
            
.clean_last:
    st1    #$00
    st2    #$00
    st2    #$00
    st2    #$00
    st2    #$00
    iny
    cpy    #64
    bne    .clean_last
    
    rts
    
;----------------------------------------------------------------------
; name : 
;
; description :
;
; in :
;
scroller:  
    lda    <_counter
    bne    .phase_update
.next_phase:
    ldx    <spr_font_phase
    cpx    #phase_count
    bne    .no_reset
        stz    <spr_font_phase
        clx
.no_reset:

    lda    phase_counter, X
    sta    <_counter
    
    sax
    asl    A
    sta    <spr_font_index

    inc    <spr_font_phase    
.phase_update:
    dec    <_counter
    ldx    <spr_font_index
    jmp    [phase_func, X]

sprite_txt_update:
    tma    #SPIRAL_TXT_DATA_PAGE
    pha
    lda    #SPIRAL_TXT_DATA_BANK
	tam    #SPIRAL_TXT_DATA_PAGE
    
    lda    <current_txt_bloc
    bne    .l0
.l1:
        lda    #TXT_COUNT
        sta    <current_txt_bloc
        stw    #txtData, <spr_font_ptr
.l0:
    
    stw    #($7340>>5), <spr_font_base ; [todo]
    jsr    print_line_16x8
    dec    <current_txt_bloc

    pla
    tam    #SPIRAL_TXT_DATA_PAGE
    
    rts
        
sprite_txt_wait:    
    rts

phase_count = 2
phase_counter: .db 1, 42
phase_func: 
    .dw sprite_txt_update
    .dw sprite_txt_wait
    
txtSpace:
    ;    A   B   C   D   E   F   G   H   I   J   K   L   M   N   O   P
    .db 14, 14, 12, 14, 12, 12, 14, 14,  6, 14, 14, 12, 14, 14, 12, 14
    ;    Q   R   S   T   U   V   W   X   Y   Z   '   (   )   0   1   2
    .db 14, 14, 14, 14, 14, 14, 14, 14, 14, 14, 10, 14, 14, 14, 10, 14
    ;    3   4   5   6   7   8   9   ?   !   -   +   .   ,   :   /   
    .db 14, 14, 14, 14, 14, 14, 14, 14, 12, 14, 14, 10, 10, 12, 14