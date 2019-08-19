#include <paging.h>
void paging_setpagedirectory(uint32_t* pageDirectory)
{
    asm volatile ("mov %0, %%cr3"
                :
                :"r"((uint32_t)pageDirectory)
                :);
}

void paging_enable()
{
    asm volatile ("mov %%cr0, %%eax\n\t"
                "or $0x80000000, %%eax\n\t"
                "mov %%eax, %%cr0"
                :
                :
                : "eax");
}
