;;-----------------------------LICENSE NOTICE------------------------------------
;;  This file is part of CPCtelera: An Amstrad CPC Game Engine 
;;  Copyright (C) 2018 Arnaud Bouche (@Arnaud6128)
;;  Copyright (C) 2018 ronaldo / Fremos / Cheesetea / ByteRealms (@FranGallegoBR)
;;
;;  This program is free software: you can redistribute it and/or modify
;;  it under the terms of the GNU Lesser General Public License as published by
;;  the Free Software Foundation, either version 3 of the License, or
;;  (at your option) any later version.
;;
;;  This program is distributed in the hope that it will be useful,
;;  but WITHOUT ANY WARRANTY; without even the implied warranty of
;;  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;;  GNU Lesser General Public License for more details.
;;
;;  You should have received a copy of the GNU Lesser General Public License
;;  along with this program.  If not, see <http://www.gnu.org/licenses/>.
;;-------------------------------------------------------------------------------
.module cpct_sprites

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; Function: cpct_drawSpriteMaskedAlignedColorizeM1
;;
;;    Directly replace a color and draw a sprite Masked Aligned to video memory.
;;
;; C Definition:
;;    void <cpct_drawSpriteMaskedAlignedColorizeM1> (void* *sprite*, void* *memory*, <u8> *width*, <u8> *height*, 
;;                                                   <u8> *oldColor*, <u8> *newColor*, <u8*> *pmasktable*) __z88dk_callee;
;;
;; Input Parameters (10 bytes):
;;  (2B HL') sprite      - Source Sprite Pointer (array of pixel data)
;;  (2B DE') memory      - Destination video memory pointer
;;  (1B C' ) height      - Sprite Height in bytes (>0)
;;  (1B B' ) width       - Sprite Width in *bytes* (Beware, *not* in pixels!)
;;  (1B E )  oldColor    - Color to replace
;;  (1B D )  newColor    - New color
;;  (2B HL)  pmasktable  - Pointer to the aligned mask table used to create transparency
;;
;; Assembly call (Input parameters on registers):
;;    > call cpct_drawSpriteMaskedAlignedColorizeM1_asm
;;
;; Parameter Restrictions:
;;  * *sprite* must be an array containing sprite's pixels data in screen pixel format
;; Sprite must be rectangular and all bytes in the array must be consecutive pixels, 
;; starting from top-left corner and going left-to-right, top-to-bottom down to the 
;; bottom-right corner. Total amount of bytes in pixel array should be *width* x *height*.  
;;  * *memory* could be any place in memory, inside or outside current video memory. It
;; will be equally treated as video memory (taking into account CPC's video memory 
;; disposition). This lets you copy sprites to software or hardware backbuffers, and
;; not only video memory.
;;  * *width* must be the width of the sprite *in bytes*. Always remember that the width must be 
;; expressed in bytes and *not* in pixels.
;;  The correspondence is mode 0 : 1 byte = 4 pixels
;;  * *height* must be the height of the sprite in bytes, and must be greater than 0. 
;; There is no practical upper limit to this value. Height of a sprite in
;; bytes and pixels is the same value, as bytes only group consecutive pixels in
;; the horizontal space.
;;  * *oldColor* must be the index of color (0 to 3) to replace
;;  * *newColor* must be the index of the new color (0 to 3)
;;
;; Known limitations:
;;     * This function does not do any kind of boundary check or clipping. If you 
;; try to draw sprites on the frontier of your video memory or screen buffer 
;; if might potentially overwrite memory locations beyond boundaries. This 
;; could cause your program to behave erratically, hang or crash. Always 
;; take the necessary steps to guarantee that you are drawing inside screen
;; or buffer boundaries.
;;     * As this function receives a byte-pointer to memory, it can only 
;; draw byte-sized and byte-aligned sprites. This means that the box cannot
;; start on non-byte aligned pixels (like odd-pixels, for instance) and 
;; their sizes must be a multiple of a byte (2 in mode 0, 4 in mode 1 and
;; 8 in mode 2).
;;     * This function *will not work from ROM*, as it uses self-modifying code.
;;     * This function requires the CPC firmware to be DISABLED. Otherwise, random crashes might happen due to side effects.
;;
;; Destroyed Register values: 
;;    AF, BC, DE, HL, BC', DE', HL', IX
;;
;; Required memory:
;;     C-bindings - 133 bytes
;;   ASM-bindings - 117 bytes
;;
;; Time Measures:
;; (start code)
;;  Case      |   microSecs (us)       |        CPU Cycles
;; ----------------------------------------------------------------
;;            |    32 + (33 + 75W)H    |    128 + (132 + 300W)H
;; ----------------------------------------------------------------
;;  W=2,H=16  |        2960            |       11840
;;  W=4,H=32  |       10688            |       42752
;; ----------------------------------------------------------------
;; Asm saving |         -16            |        -64
;; ----------------------------------------------------------------
;; (end code)
;;    W = *width* in bytes, H = *height* in bytes, HH = [(H-1)/8]
;;
;; Credits:
;;    Original routine optimized by @Docent and discussed in CPCWiki :
;; http://www.cpcwiki.eu/forum/programming/cpctelera-colorize-sprite/
;;
;; Thanks to all of them for their help and support.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

.globl dc_mode1_ct

;; Macro to convert color to pixel Mode1 : Axxx Axxx
.macro convertPixel        ;; From cpct_px2byteM1                   
    ld   bc, #dc_mode1_ct  ;; [3] BC points to conversion table (dc_mode1_ct)
    
    ;; Compute BC += A
    add  c                 ;; [1] | C += A
    ld   c, a              ;; [1] |
    sub  a                 ;; [1] A = 0 (preserving Carry Flag)
    adc  b                 ;; [1] | B += Carry
    ld   b, a              ;; [1] |

    ;; A = *(BC + A)
    ld   a, (bc)           ;; [2] A = Value stored at the table pointed by HL 
.endm
       
    ;; Convert newColor to pixel format (E)
    ld a, h                ;; [1]  A = H new color index
    convertPixel           ;; [10] | Convert into A
    ld e, a                ;; [1]  | E = A new color : Axxx Axxx

    ;; Convert oldColor to pixel format (D)
    ld a, l                ;; [1]  A = L old color index
    convertPixel           ;; [10] | Convert into A
    ld d, a                ;; [1]  | D = A old color : Axxx Axxx
    
    ld c, #0x88            ;; [2] C = Mask to get pixel A : Axxx Axxx
    exx                    ;; [1] Switch to Alternate registers
    
    ld__ixl_c              ;; [1] IXL = C (Width)
    ld c, b                ;; [1] C = B (Height)
    
convertLoop:    
    push de                ;; [4] Store DE start line (DestMem)
    ld__b_ixl              ;; [2] B = IXL (Sprite Width)
        
lineLoop:
    ld  a, (hl)            ;; [2] A = (HL) current Byte of sprite Mask
    exx                    ;; [1] Switch to Default registers
    
    ld  l, a               ;; [1] L = A current Byte of sprite : ABCD ABCD
    and c                  ;; [2] A |= C (C = 0x88)   : Axxx Axxx
    
    cp  d                  ;; [1] Test if pixel (A) is the old colour to be replaced (D)
    jr  nz, readPixelA     ;; [2/3] If not equal go to next pixel 
        ld  a, e           ;; [1] else A = new colour to set (E)
    
readPixelA:
    ld  h, a               ;; [1] H = A (current colorized sprite) : Axxx Axxx
    
    sla l                  ;; [2] L (current byte of sprite) << 1 : ABCD ABCD -> BCDx BCDx
    ld  a, l               ;; [1] A = L  : BCDx BCDx
    and c                  ;; [2] A |= Mask (0x88) : Bxxx Bxxx
    
    cp  d                  ;; [1] Test if pixel (A) is the old colour to be replaced (D)
    jr  nz, readPixelB     ;; [2/3] If not equal go to next pixel 
        ld  a, e           ;; [1] else A = new colour to set (E)
        
readPixelB:
    rrca                   ;; [1] A = Axxx Axxx >> 1  : xBxx xBxx
    or h                   ;; [1] A |= H (color byte) : Axxx Axxx
    ld  h, a               ;; [1] H = A               : ABxx ABxx
    
    sla l                  ;; [2] L ( BCDx BCDx) << 1 : CDxx CDxx  
    ld  a, l               ;; [1] A = L               : CDxx CDxx  
    and c                  ;; [1] A |= C (C = 0x88)   : Cxxx Cxxx
    
    cp  d                  ;; [1] Test if pixel (A) is the old colour to be replaced (D)
    jr  nz, readPixelC     ;; [2/3] If not equal go to next pixel 
        ld  a, e           ;; [1] else A = new colour to set (E)
    
readPixelC:
    rrca                   ;; [1] A = Axxx Axxx >> 1  : xBxx xBxx
    rrca                   ;; [1] A = xxCx xxCx << 1  : xxCx xxCx
    or  h                  ;; [1] A |= H (ABxx ABxx)  : ABCx ABCx
    ld  h, a               ;; [1] H = A               : ABCx ABCx

    sla l                  ;; [2] L (BCDx BCDx) << 1  : Dxxx Dxxx  
    ld  a, l               ;; [1] A = L               : Dxxx Dxxx   
    and c                  ;; [1] A |= C (C = 0x88)   : Dxxx Dxxx
    
    cp  d                  ;; [1] Test if pixel (A) is the old colour to be replaced (D)
    jr  nz, readPixelD     ;; [2/3] If not equal go to next pixel 
        ld  a, e           ;; [1] else A = new colour to set (E)
    
readPixelD:    
    rrca                   ;; [1] A = Axxx Axxx >> 1  : xBxx xBxx
    rrca                   ;; [1] A = xBxx xBxx >> 1  : xxCx xxCx
    rrca                   ;; [1] A = xxCx xxxx >> 1  : xxxD xxxD
    or  h                  ;; [1] A |= H (ABCx ABCx)  : ABCD ABCD  
  
    exx                    ;; [1] Switch to Alternate registers

drawByte:
    push hl                ;; [4] Store HL (current byte sprite source)
    ld   h, b              ;; [1] H = B (Masked table adress High Byte)
    ld   l, a              ;; [1] Access mask table element (table must be 256-byte aligned)
    ld   a, (de)           ;; [2] Get the value of the byte of the screen where we are going to draw
    and  (hl)              ;; [2] Erase background part that is to be overwritten (Mask step 1)
    or   l                 ;; [1] Add up background and sprite information in one byte (Mask step 2)
    ld   (de), a           ;; [2] Save modified background + sprite data information into memory    
    pop  hl                ;; [3] Recover HL (current byte sprite source)
        
    inc  hl                ;; [2] Next byte sprite source
    inc  de                ;; [2] Next byte sprite colorized
    djnz lineLoop          ;; [3] Decrement B (Width) if B != 0 goto lineLoop
    
    dec c                  ;; [1] Decrement C (Height) 
    jr  z, end             ;; [2/3] If C == O goto end

    pop de                 ;; [3] Restore DE start line (DestMem

    ld   a, d              ;; [1] Start of next pixel line normally is 0x0800 bytes away.
    add  #0x08             ;; [2]    so we add it to DE (just by adding 0x08 to D)
    ld   d, a              ;; [1]
    and  #0x38             ;; [2] We check if we have crossed memory boundary (every 8 pixel lines)..    
    
    jr   nz, convertLoop   ;; [2/3]  .. by checking the 4 bits that identify present memory line. 
                           ;; ....  If 0, we have crossed boundaries

dms_sprite_8bit_boundary_crossed:
    ld   a, e              ;; [1] DE = DE + 0xC050h
    add  #0x50             ;; [2] -- Relocate DE pointer to the start of the next pixel line:
    ld   e, a              ;; [1] -- DE is moved forward 3 memory banks plus 50 bytes (4000h * 3) 
    ld   a, d              ;; [1] -- which effectively is the same as moving it 1 bank backwards and then
    adc  #0xC0             ;; [2] -- 50 bytes forwards (which is what we want to move it to the next pixel line)
    ld   d, a              ;; [1] -- Calculations are made with 8 bit maths as it is faster than other alternatives here
    
    jr   convertLoop       ;; [3] Jump to continue with next pixel line    

end:
    pop de                 ;; [3] Empty stack by getting last element (DestMem)
    ;; Return is included in bindings
    