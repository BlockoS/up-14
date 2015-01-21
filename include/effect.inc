;----------------------------------------------------------------------
; Effects bank
;----------------------------------------------------------------------
EFFECT_CODE_BANK = 1
EFFECT_CODE_PAGE = 2

ROTOZOOM_DATA_BANK = 3
ROTOZOOM_DATA_PAGE = 5

;TUNNEL_DATA_BANK     = 4
;TUNNEL_DATA_PAGE     = 5

TITLE_DATA_BANK     = 2
TITLE_DATA_PAGE     = 5

SPIRAL_TXT_DATA_BANK = 2
SPIRAL_TXT_DATA_PAGE = 5

;----------------------------------------------------------------------
; ZP variables declaration
;----------------------------------------------------------------------
_zp_fx = $208B

;----------------------------------------------------------------------
; name : checker_load_pal
;
; description : load the corresponding palette 
;
; in :	X	palette to load
;
;;;;checker_load_pal .macro
;;;;	; Set data pointer
;;;;	lda    checker_pal_ptr,X
;;;;	sta    <__ptr
;;;;	inx
;;;;	lda    checker_pal_ptr,X
;;;;	sta    <__ptr+1
;;;;	
;;;;	; Initialize palete
;;;;	; 1. Set color index register
;;;;	stz    color_reg_l
;;;;	stz    color_reg_h
;;;;	
;;;;	; 2. Copy colors
;;;;	cly
;;;;.l\@:
		;;;;lda    [__ptr],Y
		;;;;sta    color_data_l
		;;;;iny
		;;;;lda    [__ptr],Y
		;;;;sta    color_data_h
		;;;;iny
;;;;		
		;;;;cpy    #$10
	;;;;bne    .l\@
;;;;	
;;;;	.endm
;;;;

