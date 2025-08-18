#pragma once

#include <iostream>
#include <cstring>
#include <string>
#include <algorithm>
#include <cstdarg>
#include <cstdio>

#include "helper_matrix.h"

// --- Global Variable Declarations ---
// The static buffer to store text. 'extern' indicates that this variable is defined elsewhere.
static const int NOTE_BUFFER_SIZE = 2048;
static const int NOTE_TEMP_BUFFER_SIZE = 256;

// extern char note_buffer[NOTE_BUFFER_MAX_SIZE];


struct NoteData {
    char buffer[NOTE_TEMP_BUFFER_SIZE];
    size_t idx;
    bool is_full;
};

    // char note_buffer[NOTE_BUFFER_MAX_SIZE];
    // size_t note_buffer_idx = 0;
    // bool note_buffer_is_full = false;


// A static index to keep track of the current position to write to.
// extern size_t note_buffer_idx;

// An auxiliary variable to track if the buffer is full.
// extern bool note_buffer_is_full;

// --- Function Prototypes ---
// These are the declarations for the functions defined in buffer.cpp.
void note_buffer_clear(NoteData& data);
void note_buffer_add_text(NoteData& data, const std::string& text_to_add);
void note_buffer_add_text_f(NoteData& data, const char* format, ...);

void note_buffer_add_matrix(NoteData& data, MatrixData& M);

void note_buffer_print_buffer(NoteData& data);