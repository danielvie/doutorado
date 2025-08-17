#pragma once

#include "Arduino.h"

#include <iostream>
#include <cstring>
#include <string>
#include <algorithm>

#include "matrix_math.h"

// --- Global Variable Declarations ---
// The static buffer to store text. 'extern' indicates that this variable is defined elsewhere.
static const int NOTE_BUFFER_SIZE = 2048;
static const int NOTE_TEMP_BUFFER_SIZE = 256;
extern char note_buffer[NOTE_BUFFER_SIZE];

// A static index to keep track of the current position to write to.
extern size_t note_buffer_idx;

// An auxiliary variable to track if the buffer is full.
extern bool note_buffer_is_full;

// --- Function Prototypes ---
// These are the declarations for the functions defined in buffer.cpp.
void note_buffer_clear();
void note_buffer_add_text(const std::string& text_to_add);
void note_buffer_add_text_f(const char* format, ...);

void note_buffer_add_matrix(MatrixData& M);

void note_buffer_print_buffer();