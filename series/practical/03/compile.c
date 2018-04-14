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

	compiler(argv[1], argv[2]);
	return EXIT_SUCCESS;
}
