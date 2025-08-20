#include <iostream>

int main() {

    uint32_t count = 0;
    uint32_t nrun = 1;
    
    for (size_t i = 0; i < 15; i++) {
        count = (count + 1) % nrun;
        
        printf("(%02llu) -> count: %02u, nrun: %02u\n", i, count, nrun);
        
        if (count == 0) {
            printf("i should do something\n\n");
        }
    }

    return 0;
}
