#include <stdint.h>

uint32_t page_directory[1024] __attribute__((aligned(0x1000)));
uint32_t page_table[1024] __attribute__((aligned(0x1000)));

void paging_setpagedirectory(uint32_t* pageDirectory);
void paging_enable();
