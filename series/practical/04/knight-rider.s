/*
-----------------------------------------------------------
 Series 4 - Raspberry Pi Programming Part 1 - Running Light
 
 Group members:
 Michael Senn, Pascal Gerig
 
 Individualised code by:
 Worked on as a team, customizations included as comments.
 
 Exercise Version:
 1

 Notes:
 We provide hints and guidance in the comments below and
 strongly encourage you to follow the skeleton.
 However, you are free to change the code as you like.
 
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
	LDR R7, .PUD_UP
	// State of button 2
	LDR R8, .PUD_UP
	
	BL knightRiderLoop
	

/* Main loop:
 * - Send data to serial-to-parallel converter
 * - Sleep
 * - Adjust bit pattern to send
 * - Adjust direction if needed
 * - Adjust speed if either button pressed
 * - Repeat
 */
knightRiderLoop:
	BL send_data
	BL sleep
	
	BL shift_data
	BL update_direction

	BL check_faster_button
	BLEQ increase_speed
	
	BL check_slower_button
	BLEQ decrease_speed
	// Student 3 customization: Replace BLEQ above with BLEQ below.
	// BLEQ reset_speed
	
	BL knightRiderLoop


exit:
	MOV 	R7, #1				// System call 1, exit
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
// R0: Data pin
// R1: Clock pin
// R2: LSB (1) or MSB (0) first
send_data:
	STMDB SP!, {R0, R1, R2, R3, LR}
	
	BL latchLow
	
	LDR R0, .DATA_PIN
	LDR R1, .CLOCK_PIN
	LDR R2, .LSBFIRST
	MOV R3, R4
	// Student 2 customization:
	// Replace MOV above with MVN below.
	// MVN R3, R4
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


// Decrease speed of LED, up to a maximum of 1000ms delay between hops.
decrease_speed:
	CMP R6, #1000
	ADDLT R6, R6, #100
	
	MOV PC, LR


// Increase speed of LED, up to a minimum of 100ms delay between hops.
increase_speed:
	CMP R6, #100
	SUBGT R6, R6, #100
	
	MOV PC, LR


// Reset speed to default value of 500ms
reset_speed:
	MOV R6, #500
	
	MOV PC, LR


check_faster_button:
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


check_slower_button:
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

// Button pins
.BUTTON1_PIN:		.word	18
.BUTTON2_PIN:		.word	25

// Movement directions
.LEFT:	.word	0
.RIGHT:	.word	1

