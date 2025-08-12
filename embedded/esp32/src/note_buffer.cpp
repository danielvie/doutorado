#include "note_buffer.h"

// --- Global Variable Definitions ---
// These variables are defined here, and the 'extern' declarations in buffer.h refer to them.
char note_buffer[NOTE_BUFFER_SIZE];
size_t note_buffer_idx = 0;
bool note_buffer_is_full = false;

// --- Function Definitions ---
void note_buffer_clear() {
    std::fill(note_buffer, note_buffer + NOTE_BUFFER_SIZE, '\0');
    note_buffer_idx = 0;
    note_buffer_is_full = false;
}

void note_buffer_add_text(const std::string& text_to_add) {
    if (note_buffer_is_full) {
        return;
    }

    size_t text_length = text_to_add.length();
    size_t remaining_space = NOTE_BUFFER_SIZE - note_buffer_idx;

    if (text_length > remaining_space) {
        note_buffer_is_full = true;
        return;
    }
    
    // Copy the text into the buffer.
    for (size_t i = 0; i < text_length; ++i) {
        note_buffer[note_buffer_idx] = text_to_add[i];
        note_buffer_idx++;
    }
    
    // Add a null terminator after the text for easier printing.
    if (note_buffer_idx < NOTE_BUFFER_SIZE) {
        note_buffer[note_buffer_idx] = '\0';
    }
}

void note_buffer_print_buffer() {
    for (size_t i = 0; i < NOTE_BUFFER_SIZE; ++i) {
        // Print character, or a period if it's a null terminator for visibility.
        if (note_buffer[i] == '\0') {
            std::cout << ".";
        } else {
            std::cout << note_buffer[i];
        }
    }
    std::cout << "\n\n";
}
