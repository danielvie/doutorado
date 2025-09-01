#pragma once

#include <Arduino.h>
#include <NimBLEDevice.h>

#include <iostream>
#include <cstring>
#include <string>
#include <algorithm>

#include "helper_matrix.h"
#include "helper_printer.h"

// --- Global Variable Declarations ---
// The static buffer to store text. 'extern' indicates that this variable is defined elsewhere.
static const int NOTE_BUFFER_SIZE = 2048;
static const int NOTE_TEMP_BUFFER_SIZE = 256;

// extern char note_buffer[NOTE_BUFFER_MAX_SIZE];


struct NoteData {
    char* buffer;
    size_t size;
    size_t idx;
    bool is_full;
    
    // Default constructor with default size
    NoteData() : size(NOTE_BUFFER_SIZE), idx(0), is_full(false) {
        buffer = new char[size];
        std::fill(buffer, buffer + size, '\0');
    }
    
    // Constructor with custom size
    NoteData(size_t size) : size(size), idx(0), is_full(false) {
        buffer = new char[size];
        std::fill(buffer, buffer + size, '\0');
    }
    
    // Destructor to free memory
    ~NoteData() {
        delete[] buffer;
    }
    
    // Copy constructor
    NoteData(const NoteData& other) = delete;    

    // Assignment operator
    NoteData& operator=(const NoteData& other) = delete;
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
void note_buffer_clear(NoteData& buffer);
void note_buffer_add_text(NoteData& buffer, const std::string& text_to_add);
void note_buffer_add_text_f(NoteData& buffer, const char* format, ...);

void note_buffer_add_array_u32(NoteData& buffer, std::string name, uint32_t* data, size_t data_len);
void note_buffer_add_array_i32(NoteData& buffer, std::string name, int32_t* data, size_t data_len);
void note_buffer_add_matrix(NoteData& buffer, MatrixData& M);

void note_buffer_print_info(NoteData& buffer);
void note_buffer_ble_send(NoteData& buffer, NimBLECharacteristic* pCharacteristic);