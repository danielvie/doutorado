#include "helper_note.h"

// --- Global Variable Definitions ---
// These variables are defined here, and the 'extern' declarations in buffer.h refer to them.

// --- Function Definitions ---
void note_buffer_clear(NoteData& buffer) {
    std::fill(buffer.buffer, buffer.buffer + buffer.size, '\0');
    buffer.idx = 0;
    buffer.is_full = false;
}

void note_buffer_add_text(NoteData& buffer, const std::string& text_to_add) {
    if (buffer.is_full) {
        return;
    }

    size_t text_length = text_to_add.length();
    size_t remaining_space = buffer.size - buffer.idx;

    if (text_length > remaining_space) {
        buffer.is_full = true;
        return;
    }
    
    // Copy the text into the buffer.
    for (size_t i = 0; i < text_length; ++i) {
        buffer.buffer[buffer.idx] = text_to_add[i];
        buffer.idx++;
    }
    
    // Add a null terminator after the text for easier printing.
    if (buffer.idx < buffer.size) {
        buffer.buffer[buffer.idx] = '\0';
    }
}

void note_buffer_add_text_f(NoteData& buffer, const char* format, ...) {
    if (buffer.is_full) {
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
    note_buffer_add_text(buffer, temp_buffer);
}

void note_buffer_add_array_u32(NoteData& buffer, std::string name, uint32_t* data, size_t data_len) {
    note_buffer_add_text_f(buffer, "%s: [", name.c_str());
    for (size_t i = 0; i < data_len - 1; i++) {
        note_buffer_add_text_f(buffer, "%d,", data[i]);
    }
    note_buffer_add_text_f(buffer, "%d];\n", data[data_len-1]);
}

void note_buffer_add_array_i32(NoteData& buffer, std::string name, int32_t* data, size_t data_len) {
    note_buffer_add_text_f(buffer, "%s: [", name.c_str());
    for (size_t i = 0; i < data_len - 1; i++) {
        note_buffer_add_text_f(buffer, "%d,", data[i]);
    }
    note_buffer_add_text_f(buffer, "%d];\n", data[data_len-1]);
}

void note_buffer_add_matrix(NoteData& buffer, MatrixData& M) {
    if (!matrix_isvalid(M)) {
        note_buffer_add_text(buffer, "Matrix is not valid!!\n");
        return;
    }

    note_buffer_add_text(buffer, "[\n");
    for (int i = 0; i < M.rows; ++i) {
        for (int j = 0; j < M.cols; ++j) {
            if (M.values[i * M.cols + j] > 0) {
                note_buffer_add_text(buffer, " ");
            }
            note_buffer_add_text_f(buffer, "%.7f\t", M.values[i * M.cols + j]);
        }
        note_buffer_add_text(buffer, "\n");
    }
    note_buffer_add_text(buffer, "];\n");
}

void note_buffer_print_info(NoteData& buffer) {
    for (size_t i = 0; i < buffer.size; ++i) {
        // Print character, or a period if it's a null terminator for visibility.
        if (buffer.buffer[i] == '\0') {
            helper::printf(".");
        } else {
            helper::printf("%c", buffer.buffer[i]);
        }
    }

    helper::printf("\n");
    const float buffer_used = ((float)buffer.idx)/((float)buffer.size) * 100.0;

    helper::printf("[buffer size: %d, idx: %d, used: %.1f%%]\n", buffer.size, buffer.idx, buffer_used);
    helper::printf("\n\n");
}

void note_buffer_ble_send(NoteData& buffer, NimBLECharacteristic* pCharacteristic) {
    pCharacteristic->setValue((uint8_t *)buffer.buffer, strlen(buffer.buffer));
    pCharacteristic->notify();
}