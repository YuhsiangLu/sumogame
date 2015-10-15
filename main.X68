*-----------------------------------------------------------
* Title      : Game
* Written by : Yu-Hsiang Lu
* Date       : 10/04/2015
* Description: Game entry point
*-----------------------------------------------------------
    ORG    $1000
    
* Constant values
ALL_REG         REG D0-D7/A0-A6 ; Range of REG
TRANSPARENT_COLOR_GREEN        equ $0000FF00
NUMBER_BITS_OF_FRACTIONAL_PART equ 8
ADD_FOR_ROUND                  equ 1<<(NUMBER_BITS_OF_FRACTIONAL_PART-1)  ; For negative fix point number truncate
LARGE_NUMBER                   equ $5678   ; For randomness
H_SECS_PER_FRAME               equ 4 ; hundredth seconds per frame, 1 frame/0.0x sec , for ex, 4 means 1/0.04 => 25fps
BAR_WIDTH                      equ 15
BAR_HEIGHT                     equ 5
BAR_GAP                        equ 2
BAR_Y_OFFSET                   equ 70
* Game parameters
PUSH_FORCE                  equ 300
FRICTION_FORCE              equ 50
GRAVITY_FORCE               equ 50
MASS_CHANGE                 equ 1
MASS_ADJUSTMENT             equ 4
FOOD_DROP_INTERVAL          equ 100
* Background image
BG_START_X                  equ 0
BG_START_Y                  equ 0
BG_IMG_WIDTH                equ 1182
BG_IMG_HEIGHT               equ 536
* Player image
PLAYER_IMG_WIDTH            equ 64
PLAYER_IMG_HEIGHT           equ 64
* Food image
FOOD_IMG_WIDTH              equ 32
FOOD_IMG_HEIGHT             equ 32
* Stage
STAGE_WIDTH                 equ 744
STAGE_HEIGHT                equ 100
STAGE_X_BEGIN               equ (BG_IMG_WIDTH/2-STAGE_WIDTH/2)<<NUMBER_BITS_OF_FRACTIONAL_PART
STAGE_X_END                 equ (BG_IMG_WIDTH/2+STAGE_WIDTH/2)<<NUMBER_BITS_OF_FRACTIONAL_PART
MAX_Y                       equ (BG_IMG_HEIGHT+PLAYER_IMG_HEIGHT)<<NUMBER_BITS_OF_FRACTIONAL_PART
* Player
PLAYER1_START_X             equ STAGE_X_BEGIN+10<<NUMBER_BITS_OF_FRACTIONAL_PART
PLAYER1_START_Y             equ (BG_IMG_HEIGHT-STAGE_HEIGHT-PLAYER_IMG_HEIGHT)<<NUMBER_BITS_OF_FRACTIONAL_PART
PLAYER2_START_X             equ STAGE_X_END-(10+PLAYER_IMG_WIDTH)<<NUMBER_BITS_OF_FRACTIONAL_PART
PLAYER2_START_Y             equ PLAYER1_START_Y
PLAYER_WIDTH                equ PLAYER_IMG_WIDTH<<NUMBER_BITS_OF_FRACTIONAL_PART
PLAYER_HEIGHT               equ PLAYER_IMG_HEIGHT<<NUMBER_BITS_OF_FRACTIONAL_PART
PLAYER1_LED_OFFSET          equ 83
PLAYER2_LED_OFFSET          equ 1070
* Food
FOOD_WIDTH                  equ FOOD_IMG_WIDTH<<NUMBER_BITS_OF_FRACTIONAL_PART
FOOD_HEIGHT                 equ FOOD_IMG_HEIGHT<<NUMBER_BITS_OF_FRACTIONAL_PART
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
GET_TIME_TRAP_CODE          equ 8
GET_CYCLE_TRAP_CODE         equ 31
CLEAR_CYCLE_TRAP_CODE       equ 30
DRAW_RECTANGLE_TRAP_CODE    equ 87
FILL_COLOR_TRAP_CODE        equ 81
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
    move.l #0,-(sp)
    jsr    drawImage
    add    #36,sp
    
    ; First draw
    jsr    drawPlayers
    jsr    swapBuffers
    
    ; Initialize the random seed
    jsr    seedRandomNumber
    
    ; Initialize the time
    move.b  #GET_TIME_TRAP_CODE,d0
    TRAP    #15
    move.l  d1,LAST_UPDATE_TIME
    
gameLoop:
    ; Update the time for this update
    move.b  #GET_TIME_TRAP_CODE,d0
    TRAP    #15
    move.l  d1,d4
    sub.l   LAST_UPDATE_TIME,d1
    cmpi.l  #H_SECS_PER_FRAME,d1
    blt     gameLoop
    move.l  d4,LAST_UPDATE_TIME
    divu    #H_SECS_PER_FRAME,d1
    ext.l   d1
    move.l  d1,ROUNDS

    ; Get input commands
    jsr getInput
    
    ; Update objects
    jsr updatePlayers
    jsr updateFood
    
    ; Rendering
    jsr drawPlayers
    jsr drawFood
    jsr drawMass
    jsr swapBuffers
    
    ; Check winning condition
    jsr    checkWinner
    cmpi.b #0,d7
    beq    gameLoop
    
    ; Draw winning screen
    jsr    drawWining
    jsr    swapBuffers
    
    move.b #9,d0
    trap   #15                                      ; halt simulator
    
************************************
* Swap the drawing buffers
swapBuffers
    move.b #REPAINT_TRAP_CODE,d0
    trap   #15
    rts

************************************
* Check  the winne
* OUTPUT: store result byte in d7
checkWinner:
    clr.b  d7
    move.l PLAYER2_POS_Y,d6
    cmpi.l #MAX_Y,d6
    blt    p1NoWin
    move.b #1,d7
p1NoWin:    
    move.l PLAYER1_POS_Y,d6
    cmpi.l #MAX_Y,d6
    blt    noWinner
    move.b #2,d7
noWinner:
    rts

************************************
* Seed the randomness function
seedRandomNumber:
    clr.l   d6
    move.b  #GET_TIME_TRAP_CODE,d0
    TRAP    #15
    move.l  d1,d6
    mulu    #LARGE_NUMBER,d6
    move.l  d6,RANDOMVAL
    rts
    
************************************
* Get random long into d7
* INPUT d2,d3, min and max range
* OUTPUT: d7
getRandomWordIntoD7:
    move.l  d3,-(sp)
    move.l  d2,-(sp)
    move.l  d1,-(sp)
    move.l  d0,-(sp)
    move.l  RANDOMVAL,d7
    mulu    #LARGE_NUMBER,d7
    move.l  #GET_CYCLE_TRAP_CODE,d0
    TRAP    #15
    cmpi.l  #0,d1
    bne     noClearCycle
    move.l  #CLEAR_CYCLE_TRAP_CODE,d0
    TRAP    #15
    move.l  #GET_CYCLE_TRAP_CODE,d0
    TRAP    #15
noClearCycle:
    mulu    d1,d7
    bcs     nocarry
    add.l   #1,d7
nocarry:
    andi.l  #$FFFF,d7 
    sub.l   d2,d3
    divu    d3,d7
    swap    d7
    ext.l   d7
    add.l   d2,d7
    addi.l  #1,d7
    move.l  d7,RANDOMVAL
    move.l  d0,(sp)+
    move.l  d1,(sp)+
    move.l  d2,(sp)+
    move.l  d3,(sp)+
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
    
    cmpi.l #0,d4
    beq    noInput1

    move.b  HAVE_HAD_NO_INPUT_P1,d0
    beq     aroundNoInput1
    move.b  #0,HAVE_HAD_NO_INPUT_P1
    
    move.l d4,d2
    
    bra aroundNoInput1
noInput1:
    move.b #1,HAVE_HAD_NO_INPUT_P1
aroundNoInput1:
    move.l #KEY_LEFT_INPUT<<8+KEY_RIGHT_INPUT,d1
    move.b #GET_USER_INPUT_TRAP_CODE,d0
    TRAP   #15
    move.l d1,d5
    
    cmpi.l #0,d5
    beq    noInput2

    move.b  HAVE_HAD_NO_INPUT_P2,d0
    beq     aroundNoInput2
    move.b  #0,HAVE_HAD_NO_INPUT_P2
    
    move.l d5,d3
    
    bra aroundNoInput2
noInput2:
    move.b #1,HAVE_HAD_NO_INPUT_P2
aroundNoInput2:
    rts

************************************
* Update the players in game according to the input from keyboard or the physic of the game world.
* The update routine assumes the states of input will be store in d2,d3
updatePlayers:
    ; Input update
    cmpi.l #0,d2
    ble    doneInputPlayer1
    
    move.l PLAYER1_VELOCITY_Y,d5
    bne    doneInputPlayer1
    
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
    
    move.l PLAYER2_VELOCITY_Y,d5
    bne    doneInputPlayer2
    
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
    lea PLAYER1_VELOCITY_Y,a4
    lea PLAYER1_POS_Y,a5
    lea PLAYER1_PREVIOUS_POS_Y,a6
    jsr updatePlayer
    
    ; Player2
    lea PLAYER2_FORCE_X,a0
    lea PLAYER2_VELOCITY_X,a1
    lea PLAYER2_POS_X,a2
    lea PLAYER2_PREVIOUS_POS_X,a3
    lea PLAYER2_VELOCITY_Y,a4
    lea PLAYER2_POS_Y,a5
    lea PLAYER2_PREVIOUS_POS_Y,a6
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
    jsr    isCollided
    add.l  #32,sp
    
    cmp.l  #0,d7
    beq    noPlayerCollusion
    ; Handle player collision 
    clr.l  d0
    ; v1' = (m1-m2)/(m1+m2)v1+2m2/(m1+m2)v2
    move.l PLAYER1_VELOCITY_X,d0
    move.l PLAYER2_VELOCITY_X,d1
    move.l PLAYER1_MASS,d2
    addi.l #MASS_ADJUSTMENT,d2  ; adjusment
    lsl.l  #NUMBER_BITS_OF_FRACTIONAL_PART,d2
    move.l PLAYER2_MASS,d3
    addi.l #MASS_ADJUSTMENT,d3  ; adjusment
    lsl.l  #NUMBER_BITS_OF_FRACTIONAL_PART,d3
    move.l d2,d4  ; m1-m2
    sub.l  d3,d4
    move.l d3,d5  ; m1+m2
    add.l  d2,d5
    move.l d2,d6
    add.l  d2,d6  ; 2m1
    move.l d3,d7  ; 
    add.l  d3,d7  ; 2m2
    
    ; v1
    move.l d4,d2
    asl.l  #NUMBER_BITS_OF_FRACTIONAL_PART,d2
    divs   d5,d2
    ext.l  d2
    muls   d0,d2
    asr.l  #NUMBER_BITS_OF_FRACTIONAL_PART,d2
    
    move.l d7,d3
    asl.l  #NUMBER_BITS_OF_FRACTIONAL_PART,d3
    divs   d5,d3
    ext.l  d3
    muls   d1,d3
    asr.l  #NUMBER_BITS_OF_FRACTIONAL_PART,d3
    
    add.l  d2,d3
    move.l d3,PLAYER1_VELOCITY_X
    
    ; v2
    move.l d6,d3
    asl.l  #NUMBER_BITS_OF_FRACTIONAL_PART,d3
    divs   d5,d3
    ext.l  d3
    muls   d0,d3
    asr.l  #NUMBER_BITS_OF_FRACTIONAL_PART,d3
    
    move.l d4,d2
    asl.l  #NUMBER_BITS_OF_FRACTIONAL_PART,d2
    divs   d5,d2
    ext.l  d2
    muls   d1,d2
    asr.l  #NUMBER_BITS_OF_FRACTIONAL_PART,d2
    
    sub.l  d2,d3
    move.l d3,PLAYER2_VELOCITY_X
    
    
    ; Find the center position in between two players
    move.l PLAYER1_POS_X,d0
    move.l PLAYER2_POS_X,d1
    move.l d0,d2
    add.l  #PLAYER_WIDTH,d2
    sub.l  d1,d2
    asr.l  #1,d2
    add.l  d2,d1
    sub.l  d2,d0
    move.l d0,PLAYER1_POS_X
    move.l d1,PLAYER2_POS_X
    
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

isCollided:
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
    add.l   ARG_COL_HEIGHT1_OFFSET(sp),d1
    cmp.l   ARG_COL_Y2_OFFSET(sp),d1
    blt     noCollision
collision:
    move.l  #1,d7    
noCollision:
    rts    

************************************
* Update the food    
updateFood:
    lea FOOD_VELOCITY_Y,a4
    lea FOOD_POS_Y,a5
    lea FOOD_PREVIOUS_POS_Y,a6
    jsr freeFall

    move.l FOOD_POS_X,d5
    move.l FOOD_POS_Y,d6
    move.l d5,FOOD_PREVIOUS_POS_X
; Check player1 collision
    move.l PLAYER1_POS_X,-(sp)
    move.l PLAYER1_POS_Y,-(sp)
    move.l #PLAYER_WIDTH,-(sp)
    move.l #PLAYER_HEIGHT,-(sp)
    move.l d5,-(sp)
    move.l d6,-(sp)
    move.l #FOOD_WIDTH,-(sp)
    move.l #FOOD_HEIGHT,-(sp)
    jsr    isCollided
    add.l  #32,sp
    
    cmpi.l #1,d7
    bne    noPlayer1Collision
    move.l PLAYER1_MASS,d1
    cmpi.l #8,d1
    bgt    skipGetFat1
    addi.l #MASS_CHANGE,PLAYER1_MASS
skipGetFat1:
    move.l #MAX_Y,d6
    bra    foodCollisionDone
noPlayer1Collision:
    ; Check player2 collision
    move.l PLAYER2_POS_X,-(sp)
    move.l PLAYER2_POS_Y,-(sp)
    move.l #PLAYER_WIDTH,-(sp)
    move.l #PLAYER_HEIGHT,-(sp)
    move.l d5,-(sp)
    move.l d6,-(sp)
    move.l #FOOD_WIDTH,-(sp)
    move.l #FOOD_HEIGHT,-(sp)
    jsr    isCollided
    add.l  #32,sp
    
    cmpi.l #1,d7
    bne    foodCollisionDone
    move.l PLAYER2_MASS,d1
    cmpi.l #8,d1
    bgt    skipGetFat2
    addi.l #MASS_CHANGE,PLAYER2_MASS
skipGetFat2:
    move.l #MAX_Y,d6
foodCollisionDone:
    cmpi.l  #MAX_Y,d6
    blt     noDropFood
    clr.l   d1
    move.l  LAST_FOOD_DROP_TIME,d2
    move.l  LAST_UPDATE_TIME,d1
    sub.l   d2,d1
    cmpi.l  #FOOD_DROP_INTERVAL,d1
    blt     noDropFood
    
    ; Find a random x in between stage to drop
    move.l  LAST_UPDATE_TIME,LAST_FOOD_DROP_TIME
    move.l  #0,d6
    move.l  #0,(a4)
    move.l  #(STAGE_X_BEGIN-1)>>NUMBER_BITS_OF_FRACTIONAL_PART,d2
    move.l  #(STAGE_X_END-FOOD_WIDTH-1)>>NUMBER_BITS_OF_FRACTIONAL_PART,d3
    jsr     getRandomWordIntoD7
    lsl.l   #NUMBER_BITS_OF_FRACTIONAL_PART,d7
    move.l  d7,d5
    move.l  d5,FOOD_POS_X
noDropFood:
    move.l  d6,FOOD_POS_Y
    rts

    
************************************
* Update player
* INPUT: Put the address of player's x force, x velocity, current x position and previous x position to a0, a1, a2, a3

updatePlayer
    ; Update acceleration
    move.l (a2),d3
    move.l d3,(a3)
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
    move.l d5,d7
    move.l ROUNDS,d6
    muls   d6,d4
    add.l  d4,d5
    move.l d5,(a1)

    ; Update position s=s0+0.5(v1+v2)*t
    add.l  d5,d7
    asr.l  #1,d7
    muls   d6,d7
    add.l  d7,d3
    move.l d3,(a2)
    
    ; Check if it fall off the stage
    move.l #STAGE_X_BEGIN,d0
    move.l #STAGE_X_END,d1
    addi.l #(PLAYER_IMG_WIDTH/2)<<NUMBER_BITS_OF_FRACTIONAL_PART,d3
    cmp.l  d3,d0
    bgt    playerFreeFall
    cmp.l  d3,d1
    bgt    noFreeFall
playerFreeFall:
    jsr    freeFall
noFreeFall:
    rts
    
************************************      
* Free fall function
* INPUT: Put the address of object's y velocity, current y position and previous y position to a4, a5, a6
freeFall:
    move.l  (a5),d1
    move.l  d1,(a6)
    cmpi.l  #MAX_Y,d1
    bge     outOfScreen
    move.l  (a4),d0
    move.l  d0,d7
    move.l  #GRAVITY_FORCE,d5
    move.l  ROUNDS,d6
    mulu    d6,d5
    add.l   d5,d0
    
    ; Update position s=s0+0.5(v1+v2)*t
    add.l  d0,d7
    asr.l  #1,d7
    mulu   d6,d7
    add.l  d7,d1
    move.l d1,(a5)
    bra freeFallDone
outOfScreen:
    clr.l   d0
freeFallDone:
    move.l  d0,(a4)
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
* Draw wining screen
* INPUT: d7 in byte, win condition 
drawWining:
    cmpi.b #1,d7
    bne    p2Win
    move.l #P1WIN_IMG_DATA,-(sp)
    move.l #P1WIN_IMG_DATA_END,-(sp)
    move.l #0,-(sp)
    move.l #0,-(sp)
    move.l #0,-(sp)
    move.l #0,-(sp)
    move.l #BG_IMG_WIDTH,-(sp)
    move.l #BG_IMG_HEIGHT,-(sp)
    move.l #0,-(sp)
    jsr    drawImage
    add    #36,sp
    bra   p1Win
p2Win:
    move.l #P2WIN_IMG_DATA,-(sp)
    move.l #P2WIN_IMG_DATA_END,-(sp)
    move.l #0,-(sp)
    move.l #0,-(sp)
    move.l #0,-(sp)
    move.l #0,-(sp)
    move.l #BG_IMG_WIDTH,-(sp)
    move.l #BG_IMG_HEIGHT,-(sp)
    move.l #0,-(sp)
    jsr    drawImage
    add    #36,sp
p1Win:
    rts
************************************    
* Draw food image
drawFood:
    move.l FOOD_POS_X,d6
    move.l FOOD_PREVIOUS_POS_X,d4
    move.l FOOD_POS_Y,d7
    move.l FOOD_PREVIOUS_POS_Y,d5
    cmpi.l #MAX_Y,d7
    bge    noDrawFood
    
    move.l #FOOD_IMG_WIDTH,d2
    move.l #FOOD_IMG_HEIGHT,d3
    
    move.l d6,d0
    jsr    roundDown
    move.l d0,d6
    move.l d7,d0
    jsr    roundDown
    move.l d0,d7
    move.l d5,d0
    jsr    roundDown
    move.l d0,d5
    move.l d4,d0
    jsr    roundDown
    move.l d0,d4
    
    cmp.l  d5,d7
    bne    needDrawFood
    cmp.l  d4,d6
    beq    noDrawFood
needDrawFood: 
    jsr    invalIcon
    move.l #FOOD_IMG_DATA,-(sp)
    move.l #FOOD_IMG_DATA_END,-(sp)
    move.l d6,-(sp)
    move.l d7,-(sp)
    move.l #0,-(sp)
    move.l #0,-(sp)
    move.l #FOOD_IMG_WIDTH,-(sp)
    move.l #FOOD_IMG_HEIGHT,-(sp)
    move.l #TRANSPARENT_COLOR_GREEN,-(sp)
    jsr    drawImage
    add    #36,sp
noDrawFood:
    rts


************************************    
* Draw player image
drawPlayers:
    move.l PLAYER1_POS_X,d6
    move.l PLAYER1_POS_Y,d7
    move.l PLAYER1_PREVIOUS_POS_X,d4
    move.l PLAYER1_PREVIOUS_POS_Y,d5
    
    move.l #PLAYER_IMG_WIDTH,d2
    move.l #PLAYER_IMG_HEIGHT,d3
    
    move.l d6,d0
    jsr    roundDown
    move.l d0,d6
    move.l d7,d0
    jsr    roundDown
    move.l d0,d7
    move.l d5,d0
    jsr    roundDown
    move.l d0,d5
    move.l d4,d0
    jsr    roundDown
    move.l d0,d4
    
    cmp.l  d5,d7
    bne    needDrawPlayer1
    cmp.l  d4,d6
    beq    noDrawPlayer1
needDrawPlayer1:
    jsr    invalIcon
    move.l #PLAYER1_IMG_DATA,-(sp)
    move.l #PLAYER1_IMG_DATA_END,-(sp)
    move.l d6,-(sp)
    move.l d7,-(sp)
    move.l #0,-(sp)
    move.l #0,-(sp)
    move.l #PLAYER_IMG_WIDTH,-(sp)
    move.l #PLAYER_IMG_HEIGHT,-(sp)
    move.l #TRANSPARENT_COLOR_GREEN,-(sp)
    jsr    drawImage
    add    #36,sp
noDrawPlayer1:
    move.l PLAYER2_POS_X,d6
    move.l PLAYER2_POS_Y,d7
    move.l PLAYER2_PREVIOUS_POS_X,d4
    move.l PLAYER2_PREVIOUS_POS_Y,d5
    
    move.l #PLAYER_IMG_WIDTH,d2
    move.l #PLAYER_IMG_HEIGHT,d3
    
    move.l d6,d0
    jsr    roundDown
    move.l d0,d6
    move.l d7,d0
    jsr    roundDown
    move.l d0,d7
    move.l d5,d0
    jsr    roundDown
    move.l d0,d5
    move.l d4,d0
    jsr    roundDown
    move.l d0,d4
    
    cmp.l  d5,d7
    bne    needDrawPlayer2
    cmp.l  d4,d6
    beq    noDrawPlayer2
needDrawPlayer2:
    jsr    invalIcon
    move.l #PLAYER2_IMG_DATA,-(sp)
    move.l #PLAYER2_IMG_DATA_END,-(sp)
    move.l d6,-(sp)
    move.l d7,-(sp)
    move.l #0,-(sp)
    move.l #0,-(sp)
    move.l #PLAYER_IMG_WIDTH,-(sp)
    move.l #PLAYER_IMG_HEIGHT,-(sp)
    move.l #TRANSPARENT_COLOR_GREEN,-(sp)
    jsr    drawImage
    add    #36,sp
noDrawPlayer2:
    rts
    
************************************
* Repaint invalid rectangle of the background for player
* INPUT: Put previous x, previous y in d4 and d5, width, height in d2 and d3
invalIcon:
    move.l #BACKGROUND_IMG_DATA,-(sp)
    move.l #BACKGROUND_IMG_DATA_END,-(sp)
    move.l #0,-(sp)
    move.l #0,-(sp)
    move.l d4,-(sp)
    move.l d5,-(sp)
    move.l d2,-(sp)
    move.l d3,-(sp)
    move.l #0,-(sp)
    jsr    drawImage
    add    #36,sp
    rts

************************************
* Draw mass on the led board
drawMass:
    move.l #1,d5 ; Counter
    lea    LedTable,a0
    lea    LedFuncTable,a1
    ; Set the color
    move.l #PLAYER1_LED_OFFSET,d7
    move.l PLAYER1_MASS,d6
    bra    setPlayer1
setPlayer2:
    move.l #PLAYER2_LED_OFFSET,d7
    move.l PLAYER2_MASS,d6
setPlayer1:
    ; Turn off all
    move.l #$00DDDDDD,d1
    move.l #PEN_COLOR_TRAP_CODE,d0
    trap   #15
    move.l #FILL_COLOR_TRAP_CODE,d0
    trap   #15  
    jsr drawBar0
    jsr drawBar1
    jsr drawBar2
    jsr drawBar3
    jsr drawBar4
    jsr drawBar5
    jsr drawBar6
    
    ; Turn on
    move.l #0,d1
    move.l #PEN_COLOR_TRAP_CODE,d0
    trap   #15
    move.l #FILL_COLOR_TRAP_CODE,d0
    trap   #15
    
    lsl.l  #2,d6
    move.l (a0,d6),d6
    move.l #6,d4
drawNexBar:
    move.l d6,d3
    and.l  #1,d3
    beq    noInvoke
    move.l #6,d2
    sub.l  d4,d2
    lsl.l  #2,d2
    move.l (a1,d2),a2
    jsr    (a2)
noInvoke:
    lsr.l  #1,d6
    dbra d4,drawNexBar
    dbra d5,setPlayer2
    rts

************************************
* This functions take offset on d7
drawBar0:
    movem.l d0-d6,-(sp)
    move.l  d7,d1
    addi.w  #BAR_GAP,d1
    addi.w  #BAR_HEIGHT,d1
    move.l  #BAR_Y_OFFSET,d2
    move.l  d1,d3
    addi.w  #BAR_WIDTH,d3
    move.l  d2,d4
    addi.w  #BAR_HEIGHT,d4
    move.b  #DRAW_RECTANGLE_TRAP_CODE,d0
    trap    #15
    movem.l (sp)+,d0-d6
    rts
drawBar1:
    movem.l d0-d6,-(sp)
    move.l  d7,d1
    addi.w  #BAR_GAP,d1
    addi.w  #BAR_GAP,d1
    addi.w  #BAR_HEIGHT,d1
    addi.w  #BAR_WIDTH,d1
    move.l  #BAR_Y_OFFSET,d2
    addi.w  #BAR_GAP,d2
    addi.w  #BAR_HEIGHT,d2
    move.l  d1,d3
    addi.w  #BAR_HEIGHT,d3
    move.l  d2,d4
    addi.w  #BAR_WIDTH,d4
    move.b  #DRAW_RECTANGLE_TRAP_CODE,d0
    trap    #15
    movem.l (sp)+,d0-d6
    rts
drawBar2:
    movem.l d0-d6,-(sp)
    move.l  d7,d1
    addi.w  #BAR_GAP,d1
    addi.w  #BAR_GAP,d1
    addi.w  #BAR_HEIGHT,d1
    addi.w  #BAR_WIDTH,d1
    move.l  #BAR_Y_OFFSET,d2
    addi.w  #BAR_GAP,d2
    addi.w  #BAR_HEIGHT,d2
    addi.w  #BAR_GAP,d2
    addi.w  #BAR_GAP,d2
    addi.w  #BAR_HEIGHT,d2
    addi.w  #BAR_WIDTH,d2
    move.l  d1,d3
    addi.w  #BAR_HEIGHT,d3
    move.l  d2,d4
    addi.w  #BAR_WIDTH,d4
    move.b  #DRAW_RECTANGLE_TRAP_CODE,d0
    trap    #15
    movem.l (sp)+,d0-d6
    rts
drawBar3:
    movem.l d0-d6,-(sp)
    move.l  d7,d1
    addi.w  #BAR_GAP,d1
    addi.w  #BAR_HEIGHT,d1
    move.l  #BAR_Y_OFFSET,d2
    addi.w  #BAR_GAP,d2
    addi.w  #BAR_GAP,d2
    addi.w  #BAR_WIDTH,d2
    addi.w  #BAR_HEIGHT,d2
    addi.w  #BAR_GAP,d2
    addi.w  #BAR_GAP,d2
    addi.w  #BAR_WIDTH,d2
    addi.w  #BAR_HEIGHT,d2
    move.l  d1,d3
    addi.w  #BAR_WIDTH,d3
    move.l  d2,d4
    addi.w  #BAR_HEIGHT,d4
    move.b  #DRAW_RECTANGLE_TRAP_CODE,d0
    trap    #15
    movem.l (sp)+,d0-d6
    rts
drawBar4:
    movem.l d0-d6,-(sp)
    move.l  d7,d1
    addi.w  #BAR_GAP,d1
    addi.w  #BAR_HEIGHT,d1
    move.l  #BAR_Y_OFFSET,d2
    addi.w  #BAR_GAP,d2
    addi.w  #BAR_GAP,d2
    addi.w  #BAR_WIDTH,d2
    addi.w  #BAR_HEIGHT,d2
    move.l  d1,d3
    addi.w  #BAR_WIDTH,d3
    move.l  d2,d4
    addi.w  #BAR_HEIGHT,d4
    move.b  #DRAW_RECTANGLE_TRAP_CODE,d0
    trap    #15
    movem.l (sp)+,d0-d6
    rts
drawBar5:
    movem.l d0-d6,-(sp)
    move.l  d7,d1
    move.l  #BAR_Y_OFFSET,d2
    addi.w  #BAR_GAP,d2
    addi.w  #BAR_HEIGHT,d2
    move.l  d1,d3
    addi.w  #BAR_HEIGHT,d3
    move.l  d2,d4
    addi.w  #BAR_WIDTH,d4
    move.b  #DRAW_RECTANGLE_TRAP_CODE,d0
    trap    #15
    movem.l (sp)+,d0-d6
    rts
drawBar6:
    movem.l d0-d6,-(sp)
    move.l  d7,d1
    move.l  #BAR_Y_OFFSET,d2
    addi.w  #BAR_GAP,d2
    addi.w  #BAR_HEIGHT,d2
    addi.w  #BAR_GAP,d2
    addi.w  #BAR_GAP,d2
    addi.w  #BAR_HEIGHT,d2
    addi.w  #BAR_WIDTH,d2
    move.l  d1,d3
    addi.w  #BAR_HEIGHT,d3
    move.l  d2,d4
    addi.w  #BAR_WIDTH,d4
    move.b  #DRAW_RECTANGLE_TRAP_CODE,d0
    trap    #15
    movem.l (sp)+,d0-d6
    rts


* Variables
HAVE_HAD_NO_INPUT_P1          dc.b    1
HAVE_HAD_NO_INPUT_P2          dc.b    1

ALIGNMENT_PLAYER_DATA      ds.l    1
RANDOMVAL                  dc.l    0
LAST_UPDATE_TIME           dc.l    0
ROUNDS                     dc.l    0
LAST_FOOD_DROP_TIME        dc.l    0
PLAYER1_MASS               dc.l    1
PLAYER1_POS_X              dc.l    PLAYER1_START_X
PLAYER1_POS_Y              dc.l    PLAYER1_START_Y
PLAYER1_PREVIOUS_POS_X     dc.l    PLAYER1_START_X+(1<<NUMBER_BITS_OF_FRACTIONAL_PART) ;A trick to make the logic draw the very first player image
PLAYER1_PREVIOUS_POS_Y     dc.l    PLAYER1_START_Y
PLAYER1_VELOCITY_X         dc.l    0
PLAYER1_VELOCITY_Y         dc.l    0
PLAYER1_FORCE_X            dc.l    0
PLAYER2_MASS               dc.l    1
PLAYER2_POS_X              dc.l    PLAYER2_START_X
PLAYER2_POS_Y              dc.l    PLAYER2_START_Y
PLAYER2_PREVIOUS_POS_X     dc.l    PLAYER2_START_X+(1<<NUMBER_BITS_OF_FRACTIONAL_PART) ;A trick to make the logic draw the very first player image
PLAYER2_PREVIOUS_POS_Y     dc.l    PLAYER2_START_Y
PLAYER2_VELOCITY_X         dc.l    0
PLAYER2_VELOCITY_Y         dc.l    0
PLAYER2_FORCE_X            dc.l    0
FOOD_POS_X                 dc.l    (STAGE_X_BEGIN+STAGE_X_END)/2<<NUMBER_BITS_OF_FRACTIONAL_PART
FOOD_POS_Y                 dc.l    MAX_Y
FOOD_PREVIOUS_POS_X        dc.l    (STAGE_X_BEGIN+STAGE_X_END)/2<<NUMBER_BITS_OF_FRACTIONAL_PART
FOOD_PREVIOUS_POS_Y        dc.l    MAX_Y
FOOD_VELOCITY_Y            dc.l    0

LedTable
                           dc.l    $6f,$6,$5b,$1f,$36,$3d,$7d,$7,$7f,$3f
LedFuncTable
                           dc.l    drawBar0,drawBar1,drawBar2,drawBar3,drawBar4,drawBar5,drawBar6


ALIGNMENT_BACKGROUND       ds.l    0
BACKGROUND_IMG_DATA        INCBIN  "stage.bmp"
BACKGROUND_IMG_DATA_END    ds.b    0

ALIGNMENT_PLAYER1          ds.l    0
PLAYER1_IMG_DATA           INCBIN  "sumo1.bmp"
PLAYER1_IMG_DATA_END       ds.b    0

ALIGNMENT_PLAYER2          ds.l    0
PLAYER2_IMG_DATA           INCBIN  "sumo2.bmp"
PLAYER2_IMG_DATA_END       ds.b    0

ALIGNMENT_P1WIN            ds.l    0
P1WIN_IMG_DATA             INCBIN  "p1win.bmp"
P1WIN_IMG_DATA_END         ds.b    0

ALIGNMENT_P2WIN            ds.l    0
P2WIN_IMG_DATA             INCBIN  "p2win.bmp"
P2WIN_IMG_DATA_END         ds.b    0


ALIGNMENT_FOOD             ds.l    0
FOOD_IMG_DATA              INCBIN  "sushi.bmp"
FOOD_IMG_DATA_END          ds.b    0
    END    START        ; last line of source














*~Font name~Courier New~
*~Font size~10~
*~Tab type~1~
*~Tab size~4~
