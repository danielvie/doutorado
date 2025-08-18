#include <iostream>
#include <cstring>
#include <string>

#include "helper_note.h"

// --- Main Function (Example Usage) ---
int main() {

    // Test with default buffer size (2048)
    std::cout << "=== Testing with default buffer size ===" << std::endl;
    NoteData buffer_default;
    note_buffer_clear(buffer_default);
    note_buffer_add_text(buffer_default, "Default buffer (2048 bytes)");
    note_buffer_print_buffer(buffer_default);

    // Test with custom buffer size (1024)
    std::cout << "=== Testing with custom buffer size (1024) ===" << std::endl;
    NoteData buffer_custom(1024);
    note_buffer_clear(buffer_custom);
    note_buffer_add_text(buffer_custom, "Custom buffer (1024 bytes)");
    note_buffer_print_buffer(buffer_custom);

    // Test with small buffer size (100)
    std::cout << "=== Testing with small buffer size (100) ===" << std::endl;
    NoteData buffer_small(100);
    note_buffer_clear(buffer_small);
    note_buffer_add_text(buffer_small, "Small buffer (100 bytes) - let's try to fill it with some longer text to see what happens");
    note_buffer_print_buffer(buffer_small);
    
    // Try to add more text to the small buffer (should fail)
    note_buffer_add_text(buffer_small, " This should not fit!");
    note_buffer_print_buffer(buffer_small);

    return 0;
}
