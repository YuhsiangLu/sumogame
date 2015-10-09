*-----------------------------------------------------------
* Title      : Game
* Written by : Yu-Hsiang Lu
* Date       : 10/04/2015
* Description: Game entry point
*-----------------------------------------------------------
    ORG    $1000
    
* Constant values
ALL_REG         REG D0-D7/A0-A6 ; Range of REG
* Game parameters
STAGE_WIDTH                 equ 744
STAGE_HEIGHT                equ 100
JUMP_FORCE                  equ 20
PUSH_FORCE                  equ 5
FRICTION_FORCE              equ 2
GRAVITY_FORCE               equ 10
* Background image
BG_START_X                  equ 0
BG_START_Y                  equ 0
BG_IMG_WIDTH                equ 1182
BG_IMG_HEIGHT               equ 536
* Player image
PLAYER_IMG_WIDTH            equ 64
PLAYER_IMG_HEIGHT           equ 64
PLAYER1_START_X             equ (BG_IMG_WIDTH/2-STAGE_WIDTH/2)+10
PLAYER1_START_Y             equ BG_IMG_HEIGHT-STAGE_HEIGHT-PLAYER_IMG_HEIGHT
PLAYER2_START_X             equ (BG_IMG_WIDTH/2+STAGE_WIDTH/2)-10-PLAYER_IMG_WIDTH
PLAYER2_START_Y             equ PLAYER1_START_Y
* Key codes
KEY_UP_INPUT                equ $26
KEY_LEFT_INPUT              equ $25
KEY_RIGHT_INPUT             equ $27
KEY_W_INPUT                 equ $57
KEY_A_INPUT                 equ $41
KEY_D_INPUT                 equ $44
* Commands and Command parameters
GET_USER_INPUT_TRAP_CODE    equ 19
DRAWING_MODE_TRAP_CODE      equ 92
DOUBLE_BUFFERED_MODE        equ 17
REPAINT_TRAP_CODE           equ 94
SET_RESOLUTION_TRAP_CODE    equ 33
*--------------------------------------------
 
START:                                              ; first instruction of program
    ; Set double buffered mode
    move.b #DRAWING_MODE_TRAP_CODE,d0
    move.b #DOUBLE_BUFFERED_MODE,d1
    trap   #15
    
    ; Set screen resolution
    move.b #SET_RESOLUTION_TRAP_CODE,D0
    move.l #BG_IMG_WIDTH*$10000+BG_IMG_HEIGHT,D1
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
    
gameLoop:
    ; Get input commands
    jsr getInput
    
    ; Update objects
    jsr update
    
    ; Rendering
    ;jsr drawPlayers
    ;jsr drawTimer
    ;jsr drawScore
    ;jsr swapBuffers
    
    bra gameLoop

    move.b #9,d0
    trap   #15                                      ; halt simulator

* Swap the drawing buffers
swapBuffers
    move.b #REPAINT_TRAP_CODE,d0
    trap   #15
    rts

* Get keyboard input and stores in d2,d3
getInput:
    move.l #KEY_UP_INPUT<<16+KEY_LEFT_INPUT<<8+KEY_RIGHT_INPUT,d1
    move.b #GET_USER_INPUT_TRAP_CODE,d0
    TRAP   #15
    move.l d1,d3
    
    move.l #KEY_W_INPUT<<16+KEY_A_INPUT<<8+KEY_D_INPUT,d1
    move.b #GET_USER_INPUT_TRAP_CODE,d0
    TRAP   #15
    move.l d1,d2
    rts

* Update the objects in game according to the input from keyboard or the physic of the game world.
* The update routine assumes the states of input will be store in d2,d3
update:
    ; Update according to the input
    cmpi.l #0,d2
    ble  doneInputPlayer1

    move.l d2,d4
    andi.l #$FF0000,d4
    beq    noP1Up
    subi.l #JUMP_FORCE,PLAYER1_FORCE_Y
noP1Up
    move.l d2,d4
    andi.l #$FF00,d4
    beq    noP1Left
    subi.l #PUSH_FORCE,PLAYER1_FORCE_X
noP1Left
    move.l d2,d4
    andi.l #$FF,d4
    beq    doneInputPlayer1
    addi.l #PUSH_FORCE,PLAYER1_FORCE_X
doneInputPlayer1:
    cmpi.l #0,d3
    ble    doneInputPlayer2
    
    move.l d3,d4
doneInputPlayer2:
    ; Physic update
    ; Store the old position
    move.l PLAYER1_POS_X,PLAYER1_PREVIOUS_POS_X
    move.l PLAYER1_POS_Y,PLAYER1_PREVIOUS_POS_Y
    rts
    
    ; Drawing function
    INCLUDE "draw_image.X68"
    
* Draw player's position according to players's position in d6,d7
drawPlayers:
    move.l PLAYER1_POS_X,d7
    cmp.l  PLAYER1_POS_X,d7
    bne    needDrawPlayers
    cmp.l  d4,d6
    beq    noDrawPlayers
needDrawPlayers:
    jsr    invalPlayer1
    move.l #PLAYER1_IMG_DATA,-(sp)
    move.l #PLAYER1_IMG_DATA_END,-(sp)
    move.l d6,-(sp)
    move.l d7,-(sp)
    move.l #0,-(sp)
    move.l #0,-(sp)
    move.l #PLAYER_IMG_WIDTH,-(sp)
    move.l #PLAYER_IMG_HEIGHT,-(sp)
    jsr    drawImage
    add    #32,sp
noDrawPlayers:
    rts
    
invalPlayer1:
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
    rts
    
invalPlayer2:
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
    rts

drawTimer
    rts
drawScore
    rts

* Variables
ALIGNMENT_BACKGROUND       ds.l    1
BACKGROUND_IMG_DATA        INCBIN  "stage.bmp"
BACKGROUND_IMG_DATA_END    ds.b    1

ALIGNMENT_PLAYER1          ds.l    1
PLAYER1_IMG_DATA           INCBIN  "sumo1.bmp"
PLAYER1_IMG_DATA_END       ds.b    1

ALIGNMENT_PLAYER2          ds.l    1
PLAYER2_IMG_DATA           INCBIN  "sumo2.bmp"
PLAYER2_IMG_DATA_END       ds.b    1

ALIGNMENT_PLAYER_DATA      ds.l    1
PLAYER1_POS_X              dc.l    PLAYER1_START_X
PLAYER1_POS_Y              dc.l    PLAYER1_START_Y
PLAYER1_PREVIOUS_POS_X     dc.l    PLAYER1_START_X+1 ;A trick to make the logic draw the very first player image
PLAYER1_PREVIOUS_POS_Y     dc.l    PLAYER1_START_Y+1
PLAYER1_VELOCITY_X         dc.l    0
PLAYER1_VELOCITY_Y         dc.l    0
PLAYER1_ACCELERATION_X     dc.l    0
PLAYER1_ACCELERATION_Y     dc.l    0
PLAYER1_FORCE_X            dc.l    0
PLAYER1_FORCE_Y            dc.l    0
PLAYER2_POS_X              dc.l    PLAYER2_START_X
PLAYER2_POS_Y              dc.l    PLAYER2_START_Y
PLAYER2_PREVIOUS_POS_X     dc.l    PLAYER2_START_X+1 ;A trick to make the logic draw the very first player image
PLAYER2_PREVIOUS_POS_Y     dc.l    PLAYER2_START_Y+1
PLAYER2_VELOCITY_X         dc.l    0
PLAYER2_VELOCITY_Y         dc.l    0
PLAYER2_ACCELERATION_X     dc.l    0
PLAYER2_ACCELERATION_Y     dc.l    0
PLAYER2_FORCE_X            dc.l    0
PLAYER2_FORCE_Y            dc.l    0

    END    START        ; last line of source




*~Font name~Courier New~
*~Font size~10~
*~Tab type~1~
*~Tab size~4~
