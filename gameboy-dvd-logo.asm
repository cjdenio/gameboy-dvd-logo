INCLUDE "hardware.inc"

SECTION "Header", ROM0[$100]
	jp EntryPoint

	ds $150 - @, 0 ; Make room for the header


EntryPoint:
	; Shut down audio circuitry
	ld a, 0
	ld [rNR52], a

WaitVBlank:
	ld a, [rLY]
	cp 144
	jp c, WaitVBlank

	; Turn the LCD off
	ld a, 0
	ld [rLCDC], a

	; Copy the tile data
	ld de, Tiles
	ld hl, $8000
	ld bc, TilesEnd - Tiles
	call Memcpy

	ld de, Objs
	ld hl, $fe00
	ld bc, ObjsEnd - Objs
	call Memcpy

	ld a, 16
	ld [$d000], a ; y position
	ld a, 64
	ld [$d002], a ; x position
	ld a, %10
	ld [$d001], a ; direction
	ld a, 0
	ld [$d003], a ; frame counter

	call UpdateDvdPosition

	; turn on the display
	ld a, LCDCF_ON | LCDCF_OBJON
	ld [rLCDC], a

	; initialize color palette
	ld a, %10100100
	ld [rOBP0], a

	; setup joypad buttons
	ld hl, rP1
	res 5, [hl]
	res 4, [hl]

Main:
	call WaitForFrame

	; stop animation when any button held
	ld a, [rP1]
	and $0f
	cp $0f
	jp nz, Main

	; run animation on every other frame
	ld hl, $D003
	inc [hl]
	ld a, [hl]
	cp 2
	jp c, Main

	; reset frame counter
	ld a, $00
	ld [$d003], a

	; check vertical direction
	ld hl, $d000
	ld a, [$d001]
	bit 0, a
	jp nz, .DecY
.IncY:
	inc [hl]
	jp .Next
.DecY:
	dec [hl]
.Next:
	; check horizontal direction
	ld hl, $d002
	ld a, [$d001]
	bit 1, a
	jp nz, .DecX
.IncX:
	inc [hl]
	jp .Next2
.DecX:
	dec [hl]
.Next2:
	call UpdateDvdPosition

	ld a, [$d000]
	cp $88
	call nc, FlipY
	ld a, [$d000]
	cp $11
	call c, FlipY
	ld a, [$d002]
	cp $78
	call nc, FlipX
	ld a, [$d002]
	cp $09
	call c, FlipX
	jp Main


UpdateDvdPosition:
	ld a, [$d000]
	ld [$fe04], a
	ld [$fe08], a
	ld [$fe0c], a
	ld [$fe10], a
	ld [$fe14], a
	ld [$fe18], a
	add $08
	ld [$fe1c], a
	ld [$fe20], a
	ld [$fe24], a
	ld [$fe28], a
	ld [$fe2c], a
	ld [$fe30], a
	add $08
	ld [$fe34], a
	ld [$fe38], a
	ld [$fe3c], a
	ld [$fe40], a
	ld [$fe44], a
	ld [$fe48], a
	ld a, [$d002]
	ld [$fe05], a
	ld [$fe1d], a
	ld [$fe35], a
	add $08
	ld [$fe09], a
	ld [$fe21], a
	ld [$fe39], a
	add $08
	ld [$fe0d], a
	ld [$fe25], a
	ld [$fe3d], a
	add $08
	ld [$fe11], a
	ld [$fe29], a
	ld [$fe41], a
	add $08
	ld [$fe15], a
	ld [$fe2d], a
	ld [$fe45], a
	add $08
	ld [$fe19], a
	ld [$fe31], a
	ld [$fe49], a
	ret


FlipY:
	ld a, %01
	ld hl, $d001
	xor [hl]
	ld [$d001], a
	call ToggleColor
	ret


FlipX:
	ld a, %10
	ld hl, $d001
	xor [hl]
	ld [$d001], a
	call ToggleColor
	ret


ToggleColor:
	ld a, $c0
	ld hl, $ff48
	xor [hl]
	ld [hl], a
	ret


WaitForFrame:
	ld a, [$ff44]
	cp 144
	jp nc, WaitForFrame
.wait:
	ld a, [$ff44]
	cp $90
	jp c, .wait

	ret


Memcpy:
	ld a, [de]
	ld [hli], a
	inc de
	dec bc
	ld a, b
	or a, c
	jp nz, Memcpy

	ret

Tiles:
	ds 32

	db $00, $00, $00, $00, $07, $07, $07, $07, $00, $00, $0f, $0f, $0f, $0f, $0f, $0f
	db $00, $00, $00, $00, $ff, $ff, $ff, $ff, $0f, $0f, $83, $83, $03, $03, $03, $03
	db $00, $00, $00, $00, $fc, $fc, $fc, $fc, $fe, $fe, $de, $de, $de, $de, $ce, $ce
	db $00, $00, $00, $00, $07, $07, $0f, $0f, $1f, $1f, $3e, $3e, $3c, $3c, $79, $79
	db $00, $00, $00, $00, $ff, $ff, $ff, $ff, $00, $00, $f0, $f0, $f0, $f0, $e0, $e0
	db $00, $00, $00, $00, $e0, $e0, $f0, $f0, $f8, $f8, $7c, $7c, $7c, $7c, $7c, $7c
	db $0f, $0f, $1e, $1e, $1f, $1f, $1f, $1f, $1f, $1f, $00, $00, $00, $00, $00, $00
	db $07, $07, $0f, $0f, $ff, $ff, $fc, $fc, $f0, $f0, $00, $00, $00, $00, $00, $00
	db $cf, $cf, $8f, $8f, $07, $07, $07, $07, $07, $07, $07, $07, $02, $02, $00, $00
	db $f1, $f1, $e1, $e1, $e3, $e3, $c3, $c3, $83, $83, $00, $00, $00, $00, $00, $00
	db $e0, $e0, $e0, $e0, $ff, $ff, $ff, $ff, $fe, $fe, $00, $00, $00, $00, $00, $00
	db $78, $78, $f8, $f8, $f0, $f0, $c0, $c0, $00, $00, $00, $00, $00, $00, $00, $00
	db $01, $01, $3f, $3f, $7f, $7f, $3f, $3f, $01, $01, $00, $00, $00, $00, $00, $00
	db $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $01, $01, $00, $00, $00, $00
	db $ff, $ff, $ff, $ff, $80, $80, $c0, $c0, $ff, $ff, $ff, $ff, $00, $00, $00, $00
	db $ff, $ff, $ff, $ff, $3f, $3f, $7f, $7f, $ff, $ff, $fc, $fc, $00, $00, $00, $00
	db $fc, $fc, $ff, $ff, $ff, $ff, $ff, $ff, $fe, $fe, $00, $00, $00, $00, $00, $00
	db $00, $00, $c0, $c0, $e0, $e0, $c0, $c0, $00, $00, $00, $00, $00, $00, $00, $00
TilesEnd:

Objs:
	ds 4

	db 0, 0, 2, 0
	db 0, 0, 3, 0
	db 0, 0, 4, 0
	db 0, 0, 5, 0
	db 0, 0, 6, 0
	db 0, 0, 7, 0
	db 0, 0, 8, 0
	db 0, 0, 9, 0
	db 0, 0, 10, 0
	db 0, 0, 11, 0
	db 0, 0, 12, 0
	db 0, 0, 13, 0
	db 0, 0, 14, 0
	db 0, 0, 15, 0
	db 0, 0, 16, 0
	db 0, 0, 17, 0
	db 0, 0, 18, 0
	db 0, 0, 19, 0
ObjsEnd:
