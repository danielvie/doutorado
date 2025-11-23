// Copyright 2025 ITA (Instituto Tecnologico de Aeronautica). Licensed under the MIT license.

#pragma once

// #include <Arduino.h>
// #include <NimBLEDevice.h>

#include <iostream>
#include <cstring>
#include <string>
#include <algorithm>

#include <cstdarg>
#include <esp_log.h>

#include "helper_common.h"

// #include "helper_matrix.h"
// #include "helper_printer.h"

// --- Global Variable Declarations ---
// The static buffer to store text. 'extern' indicates that this variable is defined elsewhere.
static const int NOTE_BUFFER_SIZE = 2048;
static const int NOTE_TEMP_BUFFER_SIZE = 256;

/* use example: 
    NoteData message_buffer(BLE_BUFFER_SIZE);
    note_buffer_clear(message_buffer);
    note_buffer_add_text(message_buffer, "\n\nMy Message\n");
    note_buffer_print_info(message_buffer);
*/




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

// --- Function Prototypes ---
// These are the declarations for the functions defined in buffer.cpp.
void note_clear(NoteData& buffer);
void note_add_text(NoteData& buffer, const char* format, ...);

void note_add_array_u32(NoteData& buffer, std::string name, uint32_t* data, size_t data_len);
void note_add_array_i32(NoteData& buffer, std::string name, int32_t* data, size_t data_len);
// void note_buffer_add_matrix(NoteData& buffer, MatrixData& M);

void note_print_info(NoteData& buffer);
void note_ble_send(NoteData &buffer, BLEMode mode = BLEMode::VERBOSE);