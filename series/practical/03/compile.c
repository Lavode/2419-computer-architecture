/*
 *
 * author(s):   Pascal Gerig
 *              Michael Senn
 * modified:    2010-01-07
 *
 */

#include <stdlib.h>
#include <stdio.h>
#include "memory.h"
#include "mips.h"
#include "compiler.h"

int main ( int argc, char* argv[] ) {
	if (argc != 3) {
		printf("Usage: %s <expression> <file>\n", argv[0]);
		return EXIT_FAILURE;
	}

	char* expression = argv[1];
	char* outfile    = argv[2];

	// Ugly-as-sin hack to have the requird Postfix notation in the output.
	printf("Input:    %s\n", expression);
	printf("Postfix: ");
	verbose = TRUE;
	compiler(expression, outfile);
	verbose = FALSE;
	printf("\n");

	printf("MIPS binary saved to %s\n", outfile);

	return EXIT_SUCCESS;
}
