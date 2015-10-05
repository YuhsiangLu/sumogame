*-----------------------------------------------------------
* Title      : BMP Painter
* Written by : Yu-Hsiang Lu
* Date       : 09/26/2015
* Description: This is a 68K program which loads (INCBIN in assembly time) a 24-bit uncompressed BMP image and draws it on the screen.
*              The program is able to draw a particualr area of the image by specify x, y offset, width, and height of the rectangle of the area.
*-----------------------------------------------------------

*--------------------------------------------
* Constant values
SIZE_PER_PIXEL  equ 3 ; 3 bytes, 0xBGR
ARG_HEIGHT_OFFSET       equ 64
ARG_WIDTH_OFFSET        equ ARG_HEIGHT_OFFSET+4
ARG_TOP_Y_OFFSET        equ ARG_WIDTH_OFFSET+4
ARG_LEFT_X_OFFSET       equ ARG_TOP_Y_OFFSET+4
ARG_Y_OFFSET            equ ARG_LEFT_X_OFFSET+4
ARG_X_OFFSET            equ ARG_Y_OFFSET+4
ARG_IMG_DATA_END_OFFSET equ ARG_X_OFFSET+4
ARG_IMG_DATA_OFFSET     equ ARG_IMG_DATA_END_OFFSET+4
*--------------------------------------------

drawImage:
    movem.l ALL_REG,-(sp)

    ; Normally, BMP image data is stored upside-down, we start from the last pixel
    move.l  ARG_IMG_DATA_END_OFFSET(sp),a0
    move.l  ARG_IMG_DATA_OFFSET(sp),a1

    ; Get the width of the image, and convert little endian data to big endian
    move.l BMP_IMG_WIDTH(a1),d4
    rol.w  #8,d4
    swap   d4
    rol.w  #8,d4

    ; Get the height of the image, and convert little endian data to big endian
    move.l BMP_IMG_HEIGHT(a1),d5
    rol.w  #8,d5
    swap   d5
    rol.w  #8,d5

    ; Calculate the padding bytes offset for each row
    ; In BMP format, each row is padded to a multiple of 4 bytes
    ; We are tring to find the reminder here
    move.l d4,d3
    and.l  #$FFFFFFFC,d3
    addq.l #4,d3
    sub.l  d4,d3
    and.b  #3,d3                                    ; Trun 4 -> 0, the number will be between 0 ~ 3
    sub.l  d3,a0                                    ; Subsrtract padding bytes offset from the address
    move.l d3,d2                                    ; Store it for adjustment of initial address

    ; Calculate the x offset when we switch to next row of the rectangle
    move.l d4,d1
    move.l #SIZE_PER_PIXEL,d0
    sub.l  ARG_WIDTH_OFFSET(sp),d1
    muls   d0,d1
    add.l  d1,d3

    ; Adjust the initial address of the pixel
    ; Calcualte how many bytes of skiped rows we need for adjustment
    move.l ARG_TOP_Y_OFFSET(sp),d1                  ; Get the skipped rows
    muls   d4,d1
    sub.l  ARG_LEFT_X_OFFSET(sp),d4                 ; Get pixels which are on the left of the first row we are going to draw
    sub.l  ARG_WIDTH_OFFSET(sp),d4
    add.l  d1,d4                                    ; Sum of all pixels
    muls   d0,d4                                    ; Get bytes
    sub.l  d4,a0
    ; Calculate how many padding bytes we need for adjustment
    move.l ARG_TOP_Y_OFFSET(sp),d4
    muls   d2,d4
    sub.l  d4,a0

    ; Set the initial pixel to draw x,y to d6,d7
    move.l ARG_LEFT_X_OFFSET(sp),d6                 ; Get LEFT_X
    add.l  ARG_WIDTH_OFFSET(sp),d6                  ; Add WIDTH
    move.l ARG_TOP_Y_OFFSET(sp),d7                  ; Get TOP_Y

    ; Set the furthest pixels of we want to draw
    move.l ARG_LEFT_X_OFFSET(sp),d4
    move.l ARG_TOP_Y_OFFSET(sp),d5
    add.l  ARG_HEIGHT_OFFSET(sp),d5

DRAW_LOOP:
    ; Move the address to the next pixel
    subq.l #SIZE_PER_PIXEL,a0

    move.l a0,d1

    ; Check if the address is aligned
    ; A non-aligned odd address could cause exception
    and.l  #$1,d1
    beq    ALIGNED
NOTALIGNED:
    move.l -1(a0),d1                                ; If not aligned, get data from the previous byte
    and.l  #$00FFFFFF,d1                            ; Mask out the most significant byte since each color are 3 bytes
    jmp    ENDIF
ALIGNED:
    move.l (a0),d1                                  ; If aligned, just get the data out
    lsr.l  #8,d1                                    ; Shift out the last significant byte of next pixel then we could get 3 bytes color data
ENDIF:
    ; Set the pen color according to d1
    move.l #PEN_COLOR_TRAP_CODE,d0
    trap   #15

    ; Copy the x and y to defined registers abd draw it
    move.l d6,d1
    add.l ARG_X_OFFSET(sp),d1
    move.l d7,d2
    add.l  ARG_Y_OFFSET(sp),d2
    move.l #DRAW_PIXEL_TRAP_CODE,d0
    trap   #15

    ; Check if the row is finished
    subi.l #1,d6
    cmp.l  d4,d6
    bne    DRAW_LOOP

    ; Finish one row, start next row
    sub.l  d3,a0                                    ; Move to next pixel according to x and padding bytes offsets
    move.l ARG_LEFT_X_OFFSET(sp),d6                 ; Reset the column number
    add.l  ARG_WIDTH_OFFSET(sp),d6
    addi.l #1,d7                                    ; Increment the row number
    cmp.l  d5,d7
    bne    DRAW_LOOP

    movem.l (sp)+,ALL_REG
    rts

*--------------------------------------------
* Simple BMP header structure offset
BMP_IDENTIFIER_OFFSET   equ $00
BMP_SIZE_OFFSET         equ $02
BMP_RESERVED_OFFET      equ $06
BMP_IMG_DATA_OFFSET     equ $0A
BMP_HEADER_SIZE_OFFSET  equ $0E
BMP_IMG_WIDTH           equ $12
BMP_IMG_HEIGHT          equ $16
* NOTE: The program assumes it's a 24-bit uncompressed BMP image, so it ignores the rest of the header here
*--------------------------------------------
* 68k Graphic commands
DRAW_PIXEL_TRAP_CODE                equ 82
PEN_COLOR_TRAP_CODE                 equ 80
SET_OUTPUT_RESOLUTION_TRAP_CODE     equ 33
*--------------------------------------------

    











*~Font name~Courier New~
*~Font size~10~
*~Tab type~1~
*~Tab size~4~
