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
    move.l #START_X,-(sp)                                 ; first instruction of program
    move.l #START_Y,-(sp)
    move.l #LEFT_X_FROM_START_X,-(sp)
    move.l #TOP_Y_FROM_START_Y,-(sp)
    move.l #WIDTH,-(sp)
    move.l #HEIGHT,-(sp)
    jsr    drawImage
    add    #24,sp

    move.b #9,d0
    trap   #15                                      ; halt simulator

* Variables
ALIGNMENT       dc.l    1
IMG_DATA        INCBIN  "t4.bmp"
IMG_DATA_END    dc.b    1

* Constant values
* NOTE: Since the assembler doesn't allow forward-reference, we put those data here
BMP_FILE_SIZE   equ (IMG_DATA_END-IMG_DATA)
*--------------------------------------------  
    


    END    START        ; last line of source


*~Font name~Courier New~
*~Font size~10~
*~Tab type~1~
*~Tab size~4~
