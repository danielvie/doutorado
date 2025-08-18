#include "helper_note.h"

// --- Global Variable Definitions ---
// These variables are defined here, and the 'extern' declarations in buffer.h refer to them.

// char note_buffer[NOTE_BUFFER_MAX_SIZE];
// size_t note_buffer_idx = 0;
// bool note_buffer_is_full = false;

// --- Function Definitions ---
void note_buffer_clear(NoteData& data) {
    std::fill(data.buffer, data.buffer + data.buffer_size, '\0');
    data.idx = 0;
    data.is_full = false;
}

void note_buffer_add_text(NoteData& data, const std::string& text_to_add) {
    if (data.is_full) {
        return;
    }

    size_t text_length = text_to_add.length();
    size_t remaining_space = data.buffer_size - data.idx;

    if (text_length > remaining_space) {
        data.is_full = true;
        return;
    }
    
    // Copy the text into the buffer.
    for (size_t i = 0; i < text_length; ++i) {
        data.buffer[data.idx] = text_to_add[i];
        data.idx++;
    }
    
    // Add a null terminator after the text for easier printing.
    if (data.idx < data.buffer_size) {
        data.buffer[data.idx] = '\0';
    }
}

void note_buffer_add_text_f(NoteData& data, const char* format, ...) {
    if (data.is_full) {
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
    note_buffer_add_text(data, temp_buffer);
}

void note_buffer_add_matrix(NoteData& data, MatrixData& M) {
    if (!matrix_isvalid(M)) {
        note_buffer_add_text(data, "Matrix is not valid!!\n");
        return;
    }

    note_buffer_add_text(data, "[");
    for (int i = 0; i < M.rows; ++i) {
        for (int j = 0; j < M.cols; ++j) {
            if (M.values[i * M.cols + j] > 0) {
                note_buffer_add_text(data, " ");
            }
            note_buffer_add_text_f(data, "%.7f\t", M.values[i * M.cols + j]);
        }
        note_buffer_add_text(data, "\n");
    }
    note_buffer_add_text(data, "];\n");
    
    // note_buffer_add_text(ss.str());
}

void note_buffer_print_buffer(NoteData& data) {
    for (size_t i = 0; i < data.buffer_size; ++i) {
        // Print character, or a period if it's a null terminator for visibility.
        if (data.buffer[i] == '\0') {
            printf(".");
        } else {
            printf("%c", data.buffer[i]);
        }
    }

    printf("\n");
    const float buffer_used = ((float)data.idx)/((float)data.buffer_size) * 100.0;
    printf("[buffer size: %lld, idx: %lld, used: %.1f%%]\n", data.buffer_size, data.idx, buffer_used);
    printf("\n\n");
}