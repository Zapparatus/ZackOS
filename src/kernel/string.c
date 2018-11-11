#include <string.h>

size_t strlen(const char* str)
{
    size_t len = 0;
    while (str[len])
    {
        len++;
    }
    return len;
}

void memcpy(void* destination, void* source, size_t num)
{
	void* end = source + num;

	while (source < end)
	{
		uint8_t data = *((uint8_t*) source);
		*((uint8_t*) destination) = data;

		++source;
		++destination;
	}
}

void memset(void* ptr, int value, size_t num)
{
	void* end = ptr + num;

	while (ptr < end)
	{
		*((uint8_t*) ptr) = (uint8_t) value;

		++ptr;
	}
}