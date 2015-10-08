*-----------------------------------------------------------
* Title      : Game
* Written by : Yu-Hsiang Lu
* Date       : 10/04/2015
* Description: Game entry point
*-----------------------------------------------------------
    ORG    $1000
*--------------------------------------------
* Constant values
ALL_REG         REG D0-D7/A0-A6 ; Range of REG
* The rectangle of the particular area we want to draw
BG_START_X                  equ 0
BG_START_Y                  equ 0
BG_IMG_WIDTH             equ 380
BG_IMG_HEIGHT          equ 285

PLAYER_IMG_WIDTH         equ 32
PLAYER_IMG_HEIGHT         equ 32
PLAYER_START_X           equ 200
PLAYER_START_Y           equ 200
* Key codes
KEY_UP_INPUT             equ $26
* Commands
GET_USER_INPUT_COMMAND   equ 19
*--------------------------------------------

    INCLUDE "draw_image.X68"
    
START:                                              ; first instruction of program
    move.l #BACKGROUND_IMG_DATA,-(sp)
    move.l #BACKGROUND_IMG_DATA_END,-(sp)
    move.l #0,-(sp)
    move.l #0,-(sp)
    move.l #0,-(sp)
    move.l #0,-(sp)
    move.l #BG_IMG_WIDTH,-(sp)
    move.l #BG_IMG_HEIGHT,-(sp)
    jsr    drawImage
    add    #32,sp
    

    move.l #PLAYER_START_X,d6
    move.l #PLAYER_START_Y,d7
    move.l #PLAYER_IMG_DATA,-(sp)
    move.l #PLAYER_IMG_DATA_END,-(sp)
    move.l d6,-(sp)
    move.l d7,-(sp)
    move.l #0,-(sp)
    move.l #0,-(sp)
    move.l #PLAYER_IMG_WIDTH,-(sp)
    move.l #PLAYER_IMG_HEIGHT,-(sp)
    jsr    drawImage
    add    #32,sp
    
gameLoop:
    move.l #KEY_UP_INPUT,d1
    move.b #GET_USER_INPUT_COMMAND,d0
    TRAP   #15
    andi.l #$FF,d1
    beq    noInput
    
    move.b HAVE_HAD_NO_INPUT,d0
    ;beq    aroundNoInput
    move.b #0,HAVE_HAD_NO_INPUT
    
    move.l #PLAYER_IMG_DATA,-(sp)
    move.l #PLAYER_IMG_DATA_END,-(sp)
    move.l d6,-(sp)
    move.l d7,d5
    subi.l #1,d7
    move.l d7,-(sp)
    move.l #0,-(sp)
    move.l #0,-(sp)
    move.l #PLAYER_IMG_WIDTH,-(sp)
    move.l #PLAYER_IMG_HEIGHT,-(sp)
    jsr    drawImage
    add    #32,sp
    
    move.l #BACKGROUND_IMG_DATA,-(sp)
    move.l #BACKGROUND_IMG_DATA_END,-(sp)
    move.l #0,-(sp)
    move.l #0,-(sp)
    
    move.l d6,-(sp)
    move.l d7,d3
    addi.l #PLAYER_IMG_HEIGHT,d3
    move.l d3,-(sp)
    
    move.l #PLAYER_IMG_WIDTH,-(sp)
    move.l d5,d3
    sub.l  d7,d3
    move.l d3,-(sp)
    jsr    drawImage
    add    #32,sp
    
    bra    aroundNoInput
noInput:
    move.b #1,HAVE_HAD_NO_INPUT
aroundNoInput
    bra    gameLoop

    move.b #9,d0
    trap   #15                                      ; halt simulator

* Variables
ALIGNMENT_BACKGROUND       dc.l    1
BACKGROUND_IMG_DATA        INCBIN  "t4.bmp"
BACKGROUND_IMG_DATA_END    dc.b    1

ALIGNMENT_PLAYER       dc.l    1
PLAYER_IMG_DATA        INCBIN  "snowboarder.bmp"
PLAYER_IMG_DATA_END    dc.b    1

HAVE_HAD_NO_INPUT      ds.b    1

    END    START        ; last line of source



*~Font name~Courier New~
*~Font size~10~
*~Tab type~1~
*~Tab size~4~
