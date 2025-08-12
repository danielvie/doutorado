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

void note_buffer_add_text_f(const char* format, ...) {
    if (note_buffer_is_full) {
        std::cout << "Buffer is full. Cannot add new text." << std::endl;
        return;
    }

    // A temporary buffer to hold the formatted string.
    char temp_buffer[NOTE_TEMP_BUFFER_SIZE];
    
    va_list args;
    va_start(args, format);
    // Use vsnprintf for safety to prevent buffer overflow.
    vsnprintf(temp_buffer, sizeof(temp_buffer), format, args);
    va_end(args);

    // Call the original add_text function with the formatted string.
    note_buffer_add_text(temp_buffer);
}

void note_buffer_add_matrix(MatrixData& M) {
    if (!matrix_isvalid(M)) {
        note_buffer_add_text("Matrix is not valid!!\n");
        return;
    }

    note_buffer_add_text_f("M(%dx%d):\n", M.rows, M.cols);
    for (int i = 0; i < M.rows; ++i) {
        for (int j = 0; j < M.cols; ++j) {
            note_buffer_add_text_f("%.6f\t", M.values[i * M.cols + j]);
        }
        note_buffer_add_text("\n");
    }
    
    // note_buffer_add_text(ss.str());
}

void note_buffer_print_buffer() {
    for (size_t i = 0; i < NOTE_BUFFER_SIZE; ++i) {
        // Print character, or a period if it's a null terminator for visibility.
        if (note_buffer[i] == '\0') {
            Serial.print(".");
        } else {
            Serial.print(note_buffer[i]);
        }
    }

    Serial.print("\n");
    const float buffer_used = ((float)note_buffer_idx)/((float)NOTE_BUFFER_SIZE) * 100.0;
    Serial.printf("[buffer size: %d, idx: %d, used: %.1f%%]\n", NOTE_BUFFER_SIZE, note_buffer_idx, buffer_used);
    Serial.print("\n\n");
}

