*-----------------------------------------------------------
* Title      : Game
* Written by : Yu-Hsiang Lu
* Date       : 10/04/2015
* Description: Game entry point
*-----------------------------------------------------------
    ORG    $1000
    
* Constant values
ALL_REG         REG D0-D7/A0-A6 ; Range of REG
NUMBER_BITS_OF_FRACTIONAL_PART equ 8
ADD_FOR_ROUND                  equ 1<<(NUMBER_BITS_OF_FRACTIONAL_PART-1)  ; For negative fix point number truncate
* Game parameters

PUSH_FORCE                  equ 200
FRICTION_FORCE              equ 10
GRAVITY_FORCE               equ 10
* Background image
BG_START_X                  equ 0
BG_START_Y                  equ 0
BG_IMG_WIDTH                equ 1182
BG_IMG_HEIGHT               equ 536
* Player image
PLAYER_IMG_WIDTH            equ 64
PLAYER_IMG_HEIGHT           equ 64
* Stage
STAGE_WIDTH                 equ 744
STAGE_HEIGHT                equ 100
STAGE_X_BEGIN               equ (BG_IMG_WIDTH/2-STAGE_WIDTH/2)
STAGE_X_END                 equ (BG_IMG_WIDTH/2+STAGE_WIDTH/2)
* Player
PLAYER1_START_X             equ (STAGE_X_BEGIN+10)<<NUMBER_BITS_OF_FRACTIONAL_PART
PLAYER1_START_Y             equ (BG_IMG_HEIGHT-STAGE_HEIGHT-PLAYER_IMG_HEIGHT)<<NUMBER_BITS_OF_FRACTIONAL_PART
PLAYER2_START_X             equ (STAGE_X_END-10-PLAYER_IMG_WIDTH)<<NUMBER_BITS_OF_FRACTIONAL_PART
PLAYER2_START_Y             equ PLAYER1_START_Y
PLAYER_WIDTH                equ PLAYER_IMG_WIDTH<<NUMBER_BITS_OF_FRACTIONAL_PART
PLAYER_HEIGHT               equ PLAYER_IMG_HEIGHT<<NUMBER_BITS_OF_FRACTIONAL_PART
* Key codes
KEY_LEFT_INPUT              equ $25
KEY_RIGHT_INPUT             equ $27
KEY_A_INPUT                 equ $41
KEY_D_INPUT                 equ $44
* Commands and Command parameters
GET_USER_INPUT_TRAP_CODE    equ 19
DRAWING_MODE_TRAP_CODE      equ 92
DOUBLE_BUFFERED_MODE        equ 17
REPAINT_TRAP_CODE           equ 94
SET_RESOLUTION_TRAP_CODE    equ 33
*--------------------------------------------

************************************
* First instruction of program
START:
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
    
    ; First draw
    jsr    drawPlayers
    jsr    swapBuffers
    
gameLoop:
    ; Get input commands
    jsr getInput
    
    ; Update objects
    jsr update
    
    ; Rendering
    jsr drawPlayers
    ;jsr drawTimer
    ;jsr drawScore
    jsr swapBuffers
    
    bra gameLoop

    move.b #9,d0
    trap   #15                                      ; halt simulator
    
************************************
* Swap the drawing buffers
swapBuffers
    move.b #REPAINT_TRAP_CODE,d0
    trap   #15
    rts
    
************************************
* Get keyboard input and stores in d2,d3
getInput:
    clr.l  d2
    clr.l  d3
    move.l #KEY_A_INPUT<<8+KEY_D_INPUT,d1
    move.b #GET_USER_INPUT_TRAP_CODE,d0
    TRAP   #15
    move.l d1,d4
    
    move.l #KEY_LEFT_INPUT<<8+KEY_RIGHT_INPUT,d1
    move.b #GET_USER_INPUT_TRAP_CODE,d0
    TRAP   #15
    move.l d1,d5
    
    cmpi.l #0,d4
    bne    haveInput
    cmpi.l #0,d5
    beq    noInput
haveInput:
    move.b  HAVE_HAD_NO_INPUT,d0
    beq     aroundNoInput
    move.b  #0,HAVE_HAD_NO_INPUT
    
    move.l d4,d2
    move.l d5,d3
    
    bra aroundNoInput
noInput:
    move.b #1,HAVE_HAD_NO_INPUT
aroundNoInput:
    rts

************************************
* Update the objects in game according to the input from keyboard or the physic of the game world.
* The update routine assumes the states of input will be store in d2,d3
update:
    ; Input update
    cmpi.l #0,d2
    ble  doneInputPlayer1
    
    move.l d2,d4
    andi.l #$FF00,d4
    beq    noP1Left
    subi.l #PUSH_FORCE,PLAYER1_FORCE_X
noP1Left:
    move.l d2,d4
    andi.l #$FF,d4
    beq    doneInputPlayer1
    addi.l #PUSH_FORCE,PLAYER1_FORCE_X
doneInputPlayer1:
    cmpi.l #0,d3
    ble    doneInputPlayer2
    
    move.l d3,d4
    andi.l #$FF00,d4
    beq    noP2Left
    subi.l #PUSH_FORCE,PLAYER2_FORCE_X
noP2Left:
    move.l d3,d4
    andi.l #$FF,d4
    beq    doneInputPlayer2
    addi.l #PUSH_FORCE,PLAYER2_FORCE_X
    move.l d3,d4
doneInputPlayer2:
 
    ; Physic update
    
    ; Player1
    lea PLAYER1_FORCE_X,a0
    lea PLAYER1_VELOCITY_X,a1
    lea PLAYER1_POS_X,a2
    lea PLAYER1_PREVIOUS_POS_X,a3
    jsr updatePlayer
    
    ; Player2
    lea PLAYER2_FORCE_X,a0
    lea PLAYER2_VELOCITY_X,a1
    lea PLAYER2_POS_X,a2
    lea PLAYER2_PREVIOUS_POS_X,a3
    jsr updatePlayer
    
    ; Check player collision
    move.l PLAYER1_POS_X,-(sp)
    move.l PLAYER1_POS_Y,-(sp)
    move.l #PLAYER_WIDTH,-(sp)
    move.l #PLAYER_HEIGHT,-(sp)
    move.l PLAYER2_POS_X,-(sp)
    move.l PLAYER2_POS_Y,-(sp)
    move.l #PLAYER_WIDTH,-(sp)
    move.l #PLAYER_HEIGHT,-(sp)
    jsr    IsCollided
    add.l  #32,sp
    
    cmp.l  #0,d7
    beq    noPlayerCollusion
    move.l #0,PLAYER1_VELOCITY_X
    move.l #0,PLAYER2_VELOCITY_X
noPlayerCollusion:
    rts
    
************************************
* Collision check
* INPUT: Put x1, y1, width1, height1, x2, y2, width2, height2 in the stack
* OUTPUT: d7, 1 collision, 0 otherwise
ARG_COL_HEIGHT2_OFFSET       equ 4
ARG_COL_WIDTH2_OFFSET        equ ARG_COL_HEIGHT2_OFFSET+4
ARG_COL_Y2_OFFSET            equ ARG_COL_WIDTH2_OFFSET+4
ARG_COL_X2_OFFSET            equ ARG_COL_Y2_OFFSET+4
ARG_COL_HEIGHT1_OFFSET       equ ARG_COL_X2_OFFSET+4
ARG_COL_WIDTH1_OFFSET        equ ARG_COL_HEIGHT1_OFFSET+4
ARG_COL_Y1_OFFSET            equ ARG_COL_WIDTH1_OFFSET+4
ARG_COL_X1_OFFSET            equ ARG_COL_Y1_OFFSET+4

IsCollided:
    clr.l   d7
    move.l  ARG_COL_X2_OFFSET(sp),d1
    add.l   ARG_COL_WIDTH2_OFFSET(sp),d1
    cmp.l   ARG_COL_X1_OFFSET(sp),d1
    blt     noCollision
    
    move.l  ARG_COL_X1_OFFSET(sp),d1
    add.l   ARG_COL_WIDTH1_OFFSET(sp),d1
    cmp.l   ARG_COL_X2_OFFSET(sp),d1
    blt     noCollision
    
    move.l  ARG_COL_Y2_OFFSET(sp),d1
    add.l   ARG_COL_HEIGHT2_OFFSET(sp),d1
    cmp.l   ARG_COL_Y1_OFFSET(sp),d1
    blt     noCollision
    
    move.l  ARG_COL_Y1_OFFSET(sp),d1
    add.l   ARG_COL_WIDTH1_OFFSET(sp),d1
    cmp.l   ARG_COL_Y2_OFFSET(sp),d1
    blt     noCollision
collision:
    move.l  #1,d7    
noCollision:
    rts    
    
************************************
* Update player
* INPUT: Put the address of player's force, velocity, current position and previous position to a0, a1, a2, a3

updatePlayer
    ; Update acceleration f=ma, m=1, f=a
    move.l (a2),(a3)
    move.l (a0),d4
    move.l (a1),d5
    beq    aroundFrictionForce
    blt    posiveFrictionForce
    ; Negative friction
    cmpi.l #FRICTION_FORCE,d5
    bgt    noCancelOutNegativeFrictionForce
    sub.l  d5,d4
    bra    aroundFrictionForce
noCancelOutNegativeFrictionForce:
    subi.l #FRICTION_FORCE,d4
    bra    aroundFrictionForce
    ; Postive friction
posiveFrictionForce:
    cmpi.l #-FRICTION_FORCE,d5
    blt    noCancelOutPositiveFrictionForce
    sub.l  d5,d4
    bra    aroundFrictionForce
noCancelOutPositiveFrictionForce:
    addi.l #FRICTION_FORCE,d4
   
    ;Update velocity v=v0+a*t
aroundFrictionForce:
    move.l #0,(a0)
    add.l  d4,d5
    move.l d5,(a1)

    ; Update position s=s0+v*t
    add.l  d5,(a2)
    rts
************************************      
* Drawing function
    INCLUDE "draw_image.X68"
    
************************************
* Round Fix point
* INPUT: fix point number in d0
* OUT: roundted integer in d0
roundDown:
    add.l  #ADD_FOR_ROUND,d0
    asr.l  #NUMBER_BITS_OF_FRACTIONAL_PART,d0
    rts
    
************************************    
* Draw player image
drawPlayers:
    move.l PLAYER1_POS_X,d6
    move.l PLAYER1_POS_Y,d7
    move.l PLAYER1_PREVIOUS_POS_X,d5
    
    move.l d6,d0
    jsr    roundDown
    move.l d0,d6
    move.l d7,d0
    jsr    roundDown
    move.l d0,d7
    move.l d5,d0
    jsr    roundDown
    move.l d0,d5
    
    cmp.l  d5,d6
    beq    noDrawPlayer1
needDrawPlayer1:
    jsr    invalPlayer
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
noDrawPlayer1:
    move.l PLAYER2_POS_X,d6
    move.l PLAYER2_POS_Y,d7
    move.l PLAYER2_PREVIOUS_POS_X,d5
    
    move.l d6,d0
    jsr    roundDown
    move.l d0,d6
    move.l d7,d0
    jsr    roundDown
    move.l d0,d7
    move.l d5,d0
    jsr    roundDown
    move.l d0,d5
    
    cmp.l  d5,d6
    beq    noDrawPlayer2
needDrawPlayer2:
    jsr    invalPlayer
    move.l #PLAYER2_IMG_DATA,-(sp)
    move.l #PLAYER2_IMG_DATA_END,-(sp)
    move.l d6,-(sp)
    move.l d7,-(sp)
    move.l #0,-(sp)
    move.l #0,-(sp)
    move.l #PLAYER_IMG_WIDTH,-(sp)
    move.l #PLAYER_IMG_HEIGHT,-(sp)
    jsr    drawImage
    add    #32,sp
noDrawPlayer2:
    rts
    
************************************
* Repaint invalid rectangle of the background for player
* INPUT: Put current x and previuous x in d6 and d5
invalPlayer:
    move.l #BACKGROUND_IMG_DATA,-(sp)
    move.l #BACKGROUND_IMG_DATA_END,-(sp)
    move.l #0,-(sp)
    move.l #0,-(sp)
    
    cmp.l  d5,d6
    blt    moveLeft
    move.l d5,d3
    move.l d6,d4
    sub.l  d5,d4
    bra    putArgs
moveLeft:
    move.l d6,d3
    addi.l #PLAYER_IMG_WIDTH,d3
    move.l d5,d4
    sub.l  d6,d4
putArgs:    
    move.l d3,-(sp)
    move.l d7,-(sp)
    move.l d4,-(sp)
    move.l #PLAYER_IMG_HEIGHT,-(sp)
    jsr    drawImage
    add    #32,sp
    move.l PLAYER1_POS_X,PLAYER1_PREVIOUS_POS_X
    rts

************************************
drawTimer
    rts
    
************************************
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

HAVE_HAD_NO_INPUT          dc.b    1
WINNER                     dc.b    0

ALIGNMENT_PLAYER_DATA      ds.l    1
PLAYER1_POS_X              dc.l    PLAYER1_START_X
PLAYER1_POS_Y              dc.l    PLAYER1_START_Y
PLAYER1_PREVIOUS_POS_X     dc.l    PLAYER1_START_X+(1<<NUMBER_BITS_OF_FRACTIONAL_PART) ;A trick to make the logic draw the very first player image
PLAYER1_VELOCITY_X         dc.l    0
PLAYER1_FORCE_X            dc.l    0
PLAYER2_POS_X              dc.l    PLAYER2_START_X
PLAYER2_POS_Y              dc.l    PLAYER2_START_Y
PLAYER2_PREVIOUS_POS_X     dc.l    PLAYER2_START_X+(1<<NUMBER_BITS_OF_FRACTIONAL_PART) ;A trick to make the logic draw the very first player image
PLAYER2_VELOCITY_X         dc.l    0
PLAYER2_FORCE_X            dc.l    0

    END    START        ; last line of source





*~Font name~Courier New~
*~Font size~10~
*~Tab type~1~
*~Tab size~4~
