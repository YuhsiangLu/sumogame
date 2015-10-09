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
BG_IMG_WIDTH                equ 380
BG_IMG_HEIGHT               equ 285

PLAYER_IMG_WIDTH            equ 32
PLAYER_IMG_HEIGHT           equ 32
PLAYER_START_X              equ 200
PLAYER_START_Y              equ 200
* Key codes
KEY_UP_INPUT                equ $26
* Commands and Command parameters
GET_USER_INPUT_TRAP_CODE    equ 19
DRAWING_MODE_TRAP_CODE      equ 92
DOUBLE_BUFFERED_MODE        equ 17
REPAINT_TRAP_CODE           equ 94
*--------------------------------------------

    INCLUDE "draw_image.X68"
    
START:                                              ; first instruction of program
    ; Set double buffered mode
    move.b #DRAWING_MODE_TRAP_CODE,d0
    move.b #DOUBLE_BUFFERED_MODE,d1
    trap   #15

    ; Initialize background
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
    
    jsr    swapBuffers
    
    ; Initialize player's position
    move.l #PLAYER_START_X,d6
    move.l #PLAYER_START_Y,d7
    move.l #PLAYER_START_X,d4
    move.l #PLAYER_START_Y,d5
    
gameLoop:
    ; Get input commands
    jsr getInput
    
    ; Update objects
    jsr update
    
    ; Rendering
    jsr drawingPlayer
    jsr swapBuffers
    
    bra gameLoop

    move.b #9,d0
    trap   #15                                      ; halt simulator
    
swapBuffers
    move.b #REPAINT_TRAP_CODE,d0
    trap   #15
    rts

* Get keyboard input and translate the key code into commands and stores in d3
getInput:
    move.l #KEY_UP_INPUT,d1
    move.b #GET_USER_INPUT_TRAP_CODE,d0
    TRAP   #15
    andi.l #$FF,d1
    move.l d1,d3
    rts

* Update the objects in game according to the input from keyboard or the physic of the game world.
* The update routine assumes the states of commands will be store in d3
update:
    ; Update according to command
    cmpi.l #0,d3
    ble noCommand
    
    ; Store the old position
    move.l d6,d4
    move.l d7,d5
            
    subi.l #1,d7
noCommand:
    rts
    
* Draw player's position according to players's position in d6,d7
drawingPlayer:
    jsr    invalPlayer
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
    rts
    
invalPlayer:
    cmp.l  d5,d7
    bne    invalPlayerStart
    cmp.l  d4,d6
    beq    noIvalPlayer
invalPlayerStart:
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
noIvalPlayer:
    rts
    

* Variables
ALIGNMENT_BACKGROUND       ds.l    1
BACKGROUND_IMG_DATA        INCBIN  "t4.bmp"
BACKGROUND_IMG_DATA_END    ds.b    1

ALIGNMENT_PLAYER       ds.l    1
PLAYER_IMG_DATA        INCBIN  "snowboarder.bmp"
PLAYER_IMG_DATA_END    ds.b    1

ALIGNMENT_PLAYER_DATA  ds.l    1

    END    START        ; last line of source




*~Font name~Courier New~
*~Font size~10~
*~Tab type~1~
*~Tab size~4~
