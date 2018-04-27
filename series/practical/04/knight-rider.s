/*
-----------------------------------------------------------
 Series 4 - Raspberry Pi Programming Part 1 - Running Light
 
 Group members:
 firstname lastname; firstname lastname; firstname lastname
 
 Individualised code by:
 firstname lastname
 
 Exercise Version:
 ** denote the exercise version here (1, 2 or 3) **

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
	/* to be implemented by student */


	// Set the clock pin to 'output' mode
	/* to be implemented by student */

	// Set the pins of BUTTON 1 and BUTTON 2 to 'input' mode 
	/* to be implemented by student */


	LDR	R0, .BUTTON1_PIN
	LDR	R1, .PUD_UP
	BL	pullUpDnControl

	LDR	R0, .BUTTON2_PIN
	LDR	R1, .PUD_UP
	BL	pullUpDnControl
	

start:
	/* 
	Implement the main logic for the running light here and in the loop below.
	Depending on your implementation, you will probably need to initialise
	- a register to hold the state of the LED bar
	- a register to save the time delay for the LED
	- registers to save the state of the two buttons
	- a register for a counter variable
	- and/or other (temporary) registers as you wish.
	*/


knightRiderLoop:
	/* 
	Implement this loop to make the light move.
	As described in the appendix of the exercise sheet, 
	you can use the shiftOut subroutine to send serial data.
	To do so
	1. Set the latch pin to low
	2. Send the data with shiftOut
	3. Set the latch pin to high
	*/


	// Set latch pin low (read serial data)
	/* to be implemented by student */
	
	// Send serial data (shiftOut)
	/* to be implemented by student */

	// Set latch pin high (write serial data to parallel output)
	/* to be implemented by student */
	
	
	
	// Detect button presses and increase/decrease the delay
	// Use the 'waitForButton' subroutine for each button
	/* to be implemented by student */
	

	/* Other logic goes here, like updating variables, branching to the loop label, etc. */
	/* to be implemented by student */
	

	
exit:
	MOV 	R7, #1				// System call 1, exit
	SWI 	0				// Perform system call


/*
-------------------------------------------------------------------------
 SUBROUTINES
-------------------------------------------------------------------------

If you wish, you can define your own subroutines here.
Make sure you save the registers on the stack to avoid conflicts.
Here is an example: 

foo: 
	STMDB SP!, {R3, R4, LR}
	// ... do something here with registers R3 and R4 ...
	LDMIA SP!, {R3, R4, PC} // end of foo subroutine, restore registers and jump


*/ 

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

