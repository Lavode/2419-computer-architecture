/*
-----------------------------------------------------------
 Series 5 - Raspberry Pi Programming Part 1 - Paddle Ball
 
 Group members:
 Michael Senn, Pascal Gerig
 
 Individualised code by:
 Worked on as a team, customizations included as comments.
 
 Exercise Version:
 1
 
-----------------------------------------------------------
*/

.global main
.func main

main:
	// This will setup the wiringPi library.
	// In case something goes wrong, we exit the program
	BL	wiringPiSetupGpio		
	CMP	R0, #-1			
	BEQ	exit
	
	// Ensure we start with:
	// - an empty display
	// - the beeper turned off
	MOV R4, #0
	BL send_data
	BL quiet


configurePins:
	// Set the data pin to 'output' mode
	LDR	R0, .DATA_PIN
	LDR	R1, .OUTPUT
	BL	pinMode

	// Set the latch pin to 'output' mode
	LDR R0, .LATCH_PIN
	LDR R1, .OUTPUT
	BL pinMode


	// Set the clock pin to 'output' mode
	LDR R0, .CLOCK_PIN
	LDR R1, .OUTPUT
	BL pinMode

	// Set the pins of BUTTON 1 and BUTTON 2 to 'input' mode 
	LDR R0, .BUTTON1_PIN
	LDR R1, .INPUT
	BL pinMode
	
	LDR R0, .BUTTON2_PIN
	LDR R1, .INPUT
	BL pinMode
	
	// Set buzzer pin to 'output' mode
	LDR R0, .BUZZER_PIN
	LDR R1, .OUTPUT
	BL pinMode


	// Set resistors to pull-up mode
	LDR	R0, .BUTTON1_PIN
	LDR	R1, .PUD_UP
	BL	pullUpDnControl

	LDR	R0, .BUTTON2_PIN
	LDR	R1, .PUD_UP
	BL	pullUpDnControl
	

start:
	// Data to shift out
	MOV R4, #1
	
	// Direction to shift data
	LDR R5, .LEFT
	
	// Sleep duration in ms
	MOV R6, #500
	
	// State of button 1
	LDR R7, .PUD_DOWN
	// State of button 2
	LDR R8, .PUD_DOWN
	
	// Score
	MOV R9, #0
	
wait_for_game_start:
	BL check_game_start_button
	BNE wait_for_game_start
	
	BL knightRiderLoop
	

/* Main loop:
 * - Sleep
 * - Adjust bit pattern to send
 * - Adjust direction if needed
 * - Send data to serial-to-parallel converter
 * - Check if 'ball' reached end of LED strip
 * - Check if game over
 * - Repeat
 */
knightRiderLoop:
	BL sleep
	
	BL shift_data
	BL update_direction
	
	BL send_data
	
	BL check_if_end_reached
	BLNE not_at_end
	
	// Comparison flag lost inbetween. As `check_if_end_reached` is a 
	// trivial method, we don't bother to cache the result.
	BL check_if_end_reached	
	BLEQ at_end	
	
	BL check_if_game_over
	BLEQ game_over

	BL knightRiderLoop


exit:
	MOV 	R7, #1			// System call 1, exit
	SWI 	0				// Perform system call



// Send LOW to latch pin
latchLow:
	STMDB SP!, {R0, R1, LR}
	
	LDR R0, .LATCH_PIN
	LDR R1, .LOW
	BL digitalWrite
	
	LDMIA SP!, {R0, R1, PC}
	
	
// Send HIGH to latch pin
latchHigh:
	STMDB SP!, {R0, R1, LR}
	
	LDR R0, .LATCH_PIN
	LDR R1, .HIGH
	BL digitalWrite
	
	LDMIA SP!, {R0, R1, PC}


// Send data stored in R4 to LED via serial-to-parallel converter
send_data:
	STMDB SP!, {R0, R1, R2, R3, LR}
	
	BL latchLow
	
	LDR R0, .DATA_PIN
	LDR R1, .CLOCK_PIN
	LDR R2, .LSBFIRST
	MOV R3, R4
	BL shiftOut
	
	BL latchHigh
	
	LDMIA SP!, {R0, R1, R2, R3, PC}


// Adjust bit pattern stored in R4 ('moving' the LED)
shift_data:
	// If moving left, shift data left
	CMP R5, #0
	LSLEQ R4, R4, #1
	
	// If moving right, shift data right
	CMP R5, #1
	LSREQ R4, R4, #1
	
	MOV PC, LR


// Reverse direction to move if either end of the LED strip reached
update_direction:
	// Reached left end -> start moving right
	CMP R4, #128
	LDREQ R5, .RIGHT
	
	// Reached right end -> start moving left
	CMP R4, #1
	LDREQ R5, .LEFT

	MOV PC, LR


// Sleep by R6 ms
sleep:
	STMDB SP!, {R0, LR}
	
	MOV R0, R6
	BL delay
	
	LDMIA SP!, {R0, PC}


// Increase speed of LED by SPEED_INCREASE_PER_ROUND up to a minimum of 
// SPEED_GAMEOVER_LIMIT delay between hops.
increase_speed:
	STMDB SP!, {R4, R5, LR}
	
	LDR R4, .SPEED_INCREASE_PER_ROUND
	LDR R5, .SPEED_GAMEOVER_LIMIT
	
	CMP R6, R5
	SUBGT R6, R6, R4
	
	LDMIA SP!, {R4, R5, PC}


// Check if button to score a point was pressed and set comparison flags.
check_if_button_pressed:
	STMDB SP!, {R0, R1, R2, LR}

	LDR R0, .BUTTON1_PIN
	MOV R1, #100
	// Pass old button state
	MOV R2, R7
	BL waitForButton
	// Store new button state
	MOV R7, R1
	// If button was pressed
	CMP R0, #1
	
	LDMIA SP!, {R0, R1, R2, PC}


// Check if button to start the game was pressed, and set comparison flags.
check_game_start_button:
	STMDB SP!, {R0, R1, R2, LR}

	LDR R0, .BUTTON2_PIN
	MOV R1, #100
	// Pass old button state
	MOV R2, R8
	BL waitForButton
	// Store new button state
	MOV R8, R1
	// If button was pressed
	CMP R0, #1
	
	LDMIA SP!, {R0, R1, R2, PC}


// Enable tweeter for 100ms
beep:
	STMDB SP!, {R0, R1, LR}

	BL loud
	
	MOV R0, #100
	BL delay
	
	BL quiet
	
	LDMIA SP!, {R0, R1, PC}
	

// Enable tweeter
loud:
	STMDB SP!, {R0, R1, LR}

	LDR R0, .BUZZER_PIN
	LDR R1, .HIGH
	BL digitalWrite
	
	LDMIA SP!, {R0, R1, PC}
	

// Disable tweeter
quiet:
	STMDB SP!, {R0, R1, LR}

	LDR R0, .BUZZER_PIN
	LDR R1, .LOW
	BL digitalWrite
	
	LDMIA SP!, {R0, R1, PC}


// Check if left or right end of LED strip reached.
check_if_end_reached:
	// Reached left end
	CMP R4, #128
	// Reached right end
	CMPNE R4, #1
	
	MOV PC, LR


// Game over if delay is <= SPEED_GAMEOVER_LIMIT
check_if_game_over:
	STMDB SP!, {R4, LR}

	LDR R4, .SPEED_GAMEOVER_LIMIT
	CMP R6, R4
	
	LDMIA SP!, {R4, PC}

// Show binary-encoded score on LED strip.
show_score:
	STMDB SP!, {LR}
	
	MOV R4, R9
	// Student 3 customization: Comment `MOV` above, uncomment `MVN` 
	// below.
	// MVN R4, R9
	BL send_data
	
	LDMIA SP!, {PC}
		

// Increase player's score
increase_score:
	STMDB SP!, {LR}

	ADD R9, R9, #1
	
	LDMIA SP!, {PC}


/* LED is not at end of strip:
 * - Beep if button is pressed
 */
not_at_end:
	STMDB SP!, {LR}

	// Student 2 customization: Comment the `BL` and `BLEQ` lines below.
	BL check_if_button_pressed
	BLEQ beep
	
	LDMIA SP!, {PC}
	
	
/* LED is at end of strip:
 * - Increase speed
 * - Beep if button is not pressed
 * - Increase score if button is pressed
 */
at_end:
	STMDB SP!, {R10, LR}
	
	BL increase_speed
	
	// Store whether button was pressed. Required as the comparison 
	// flags will be lost within one of the subequent method calls, 
	// so we can not use chained BLEQs.
	LDR R10, .BUTTON_DEPRESSED
	BL check_if_button_pressed
	LDREQ R10, .BUTTON_PRESSED
	
	// Beep if not pressed
	CMP R10, #0
	// Student 2 customization: Comment `CMP` above, uncomment `CMP` 
	// below.
	// CMP R10, #1
	BLEQ beep
	
	// Increase score if pressed
	CMP R10, #1
	BLEQ increase_score
	
	LDMIA SP!, {R10, PC}
	

game_over:
	STMDB SP!, {LR}
	
	BL show_score
	BL start
	
	LDMIA SP!, {PC}


waitForButton:
	/* 
	-----------------------------------------------------------------
	 Input arguments:
	 R0:	buttonPin
	 R1: 	timeout (millis)
	 R2: 	previous button state

	 Output:
	 R0:	1 if button pressed (falling edge), 0 otherwise
	 R1:	state of button (High/Low)
	-----------------------------------------------------------------
	*/
	STMDB SP!, {R2-R10, LR}

	MOV	R5, R0 		// R5: buttonPin
	MOV	R6, R1		// R6: timeout 
	MOV	R9, R2		// R9: (previous) button state
	MOV	R10, #0		// R10: button pressed or not

	@ get start time
	BL	millis
	MOV	R7, R0 		// R7: start time
	
	waitingLoopForButton:
	
		// read button pin state
		MOV	R0, R5
		BL	digitalRead
	
		// Check if edge is falling (1 -> 0)
		SUB	R1, R9, R0
		MOV	R9, R0			// previous = current
		CMP	R1, #1
		MOVEQ	R10, #1
	
		// compute elapsed time
		BL	millis
		SUB	R0, R0, R7
		
		// check if elapsed time < time out
		CMP	R0, R6
		BMI	waitingLoopForButton
		B	returnButtonPress

	returnButtonPress:
	MOV	R0, R10				// return 1 if button pressed within time window
	MOV	R1, R9
	LDMIA SP!, {R2-R10, PC}




// Constants for high- and low signals on the pins
.HIGH:			.word	1
.LOW:			.word	0

// The mode of the pin can be set to input or output.
.OUTPUT:		.word	1
.INPUT:			.word 	0

// For buttons (pull up / pull down)
.PUD_OFF:		.word	0
.PUD_DOWN:		.word	1
.PUD_UP:		.word	2

// For serial to parallel converter (74HC595 chip)
.LSBFIRST:		.word	0		// Least significant bit first
.MSBFIRST:		.word 	1		// Most significant bit first

.DATA_PIN:		.word	17 		// DS Pin of 74HC595 (Pin14)
.LATCH_PIN:		.word	27		// ST_CP Pin of 74HC595 (Pin12)	
.CLOCK_PIN:		.word	22		// CH_CP Pin of 74HC595 (Pin11)

.BUZZER_PIN: 	.word	24 // Pin of Buzzer

// Button pins
.BUTTON1_PIN:		.word	18
.BUTTON2_PIN:		.word	25

// Movement directions
.LEFT:	.word	0
.RIGHT:	.word	1

.BUTTON_PRESSED:	.word	1
.BUTTON_DEPRESSED:	.word	0


// Number of ms by which to decrease the waiting delay per round
.SPEED_INCREASE_PER_ROUND:	.word	50
// Delay in ms which indicates that the game is over
.SPEED_GAMEOVER_LIMIT:		.word	100

