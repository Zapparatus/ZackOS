#include <terminal.h>

static inline uint16_t vga_entry(unsigned char uc, uint8_t color)
{
    return (uint16_t) uc | (uint16_t) color << 8;
}

void update_cursor(int x, int y)
{
    uint16_t pos = y * VGA_WIDTH + x;

    outb(0x3D4, 0x0F);
    outb(0x3D5, (uint8_t) (pos & 0xFF));
    outb(0x3D4, 0x0E);
    outb(0x3D5, (uint8_t) ((pos >> 8) & 0xFF));
}

void terminal_initialize(void)
{
    terminal_row = 0;
    terminal_column = 0;
    terminal_color = vga_entry_color(VGA_COLOR_LIGHT_GREY, VGA_COLOR_BLACK);
    terminal_buffer = (uint16_t*) 0xB8000;
    for (size_t y = 0; y < VGA_HEIGHT; y++) {
        for (size_t x = 0; x < VGA_WIDTH; x++) {
            const size_t index = y * VGA_WIDTH + x;
            terminal_buffer[index] = vga_entry(' ', terminal_color);
        }
    }

    update_cursor(0, 0);
}

void terminal_setcolor(uint8_t color)
{
    terminal_color = color;
}

void terminal_putentryat(char c, uint8_t color, size_t x, size_t y)
{
    if (c == '\n') {
        ++terminal_row;
        terminal_column = 0;
        return;
    }
    const size_t index = y * VGA_WIDTH + x;
    terminal_buffer[index] = vga_entry(c, color);
}

void terminal_putchar(char c)
{
    if (c == '\n') {
        ++terminal_row;
        terminal_column = 0;
        update_cursor(terminal_column, terminal_row);
        return;
    }
    terminal_putentryat(c, terminal_color, terminal_column, terminal_row);
    if (++terminal_column == VGA_WIDTH) {
        terminal_column = 0;
        if (++terminal_row == VGA_HEIGHT)
            terminal_row = 0;
    }
    update_cursor(terminal_column, terminal_row);
}

void terminal_write(const char* data, size_t size)
{
    for (size_t i = 0; i < size; i++)
        terminal_putchar(data[i]);
}

void terminal_writestring(const char* data)
{
    terminal_write(data, strlen(data));

    terminal_handlescrolling();
}

void terminal_handlescrolling()
{
    if (terminal_row >= VGA_HEIGHT)
    {
        memcpy((void*) terminal_buffer, (void*) terminal_buffer + sizeof(uint16_t) * VGA_WIDTH, VGA_WIDTH * (VGA_HEIGHT - 1) * sizeof(uint16_t));

        memset((void*) terminal_buffer + sizeof(uint16_t) * VGA_WIDTH * (VGA_HEIGHT - 1), 0x00, sizeof(uint16_t) * VGA_WIDTH);

        terminal_row = VGA_HEIGHT - 2;
        
        update_cursor(terminal_column, terminal_row);
    }
}