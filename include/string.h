#include <stddef.h>
#include <stdint.h>

size_t strlen(const char* str);

void memcpy(void* source, void* destination, uint32_t size);
void memset(void* ptr, int value, size_t size);