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
START_X                  equ 0
START_Y                  equ 0
LEFT_X_FROM_START_X      equ 0
TOP_Y_FROM_START_Y       equ 0
WIDTH                    equ 100
HEIGHT                   equ 100
*--------------------------------------------

    INCLUDE "draw_image.X68"
    
START:
    move.l #BACKGROUND_IMG_DATA,-(sp)
    move.l #BACKGROUND_IMG_DATA_END,-(sp)
    move.l #START_X,-(sp)                                 ; first instruction of program
    move.l #START_Y,-(sp)
    move.l #LEFT_X_FROM_START_X,-(sp)
    move.l #TOP_Y_FROM_START_Y,-(sp)
    move.l #380,-(sp)
    move.l #285,-(sp)
    jsr    drawImage
    add    #32,sp
    
    move.l #PLAYER_IMG_DATA,-(sp)
    move.l #PLAYER_IMG_DATA_END,-(sp)
    move.l #100,-(sp)
    move.l #100,-(sp)
    move.l #LEFT_X_FROM_START_X,-(sp)
    move.l #TOP_Y_FROM_START_Y,-(sp)
    move.l #32,-(sp)
    move.l #32,-(sp)
    jsr    drawImage
    add    #32,sp

    move.b #9,d0
    trap   #15                                      ; halt simulator

* Variables
ALIGNMENT_BACKGROUND       dc.l    1
BACKGROUND_IMG_DATA        INCBIN  "t4.bmp"
BACKGROUND_IMG_DATA_END    dc.b    1

ALIGNMENT_PLAYER       dc.l    1
PLAYER_IMG_DATA        INCBIN  "snowboarder.bmp"
PLAYER_IMG_DATA_END    dc.b    1

    END    START        ; last line of source


*~Font name~Courier New~
*~Font size~10~
*~Tab type~1~
*~Tab size~4~
