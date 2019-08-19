#include <io.h>
#include <stddef.h>
#include <string.h>

#define PORT 0x3f8 /* COM1 */

void init_serial();

int serial_received();
 
char read_serial();

int is_transmit_empty();
 
void write_serial(char a);

void serial_writestring(const char* data);