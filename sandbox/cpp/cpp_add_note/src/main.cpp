#include <iostream>
#include <cstring>
#include <string>

#include "helper_note.h"

// --- Main Function (Example Usage) ---
int main() {

    NoteData buffer;

    // 1. Clear the buffer to start fresh.
    note_buffer_clear(buffer);

    // note_buffer_print_buffer(buffer);

    // // 2. Add some text that fits well within the buffer.
    // note_buffer_add_text(buffer, "Hello, World!");
    // note_buffer_print_buffer(buffer);

    // // 3. Add a string that almost fills the buffer.
    // note_buffer_add_text(buffer, " bla\n");
    // std::string long_string(NOTE_BUFFER_SIZE - 20, 'X');
    // note_buffer_add_text(buffer, long_string);
    // note_buffer_print_buffer(buffer);
    
    // // 4. Try to add a small string that will not fit. This should fail.
    // note_buffer_add_text(buffer, "This should not be added.");
    // note_buffer_print_buffer(buffer);

    // // 5. Try to add a different string after the buffer is full. This should also fail.
    // note_buffer_add_text(buffer, "Another try.");
    // note_buffer_print_buffer(buffer);

    // // 6. Clear the buffer to start again.
    // note_buffer_clear(buffer);
    // note_buffer_print_buffer(buffer);

    return 0;
}
