#include <iostream>
#include <cstring>
#include <string>

// --- Global Variables ---
// The static buffer to store text.
static const int NOTE_BUFFER_SIZE = 1024;
static char note_buffer[NOTE_BUFFER_SIZE];

// A static index to keep track of the current position to write to.
static size_t note_buffer_idx = 0;

// An auxiliary variable to track if the buffer is full.
static bool note_buffer_is_full = false;

// --- Function Prototypes ---
void note_clear_buffer();
void note_add_text(const std::string& text_to_add);
void note_print_buffer();

// --- Function Definitions ---
void note_clear_buffer() {
    // Fill the buffer with null terminators to clear it completely.
    std::fill(note_buffer, note_buffer + NOTE_BUFFER_SIZE, '\0');
    note_buffer_idx = 0;
    note_buffer_is_full = false;
}

void note_add_text(const std::string& text_to_add) {
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

void note_print_buffer() {
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

// --- Main Function (Example Usage) ---
int main() {
    // 1. Clear the buffer to start fresh.
    note_clear_buffer();
    note_print_buffer();

    // 2. Add some text that fits well within the buffer.
    note_add_text("Hello, World!");
    note_print_buffer();

    // 3. Add a string that almost fills the buffer.
    note_add_text(" bla\n");
    std::string long_string(NOTE_BUFFER_SIZE - 20, 'X');
    note_add_text(long_string);
    note_print_buffer();
    
    // 4. Try to add a small string that will not fit. This should fail.
    note_add_text("This should not be added.");
    note_print_buffer();

    // 5. Try to add a different string after the buffer is full. This should also fail.
    note_add_text("Another try.");
    note_print_buffer();

    // 6. Clear the buffer to start again.
    note_clear_buffer();
    note_print_buffer();

    return 0;
}
