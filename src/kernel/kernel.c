#include <stdbool.h>
#include <stddef.h>
#include <stdint.h>
#include <stdlib.h>
#include <paging.h>
#include <terminal.h>
#include <io.h>
#include <serial.h>

/* Check if the compiler thinks we are targeting the wrong operating system. */
#if defined(__linux__)
#error "You are not using a cross-compiler, you will most certainly run into trouble"
#endif

/* This tutorial will only work for the 32-bit ix86 targets. */
#if !defined(__i386__)
#error "This project needs to be compiled with a ix86-elf compiler"
#endif

static char direction;

void HandleKeyboard(char character, char released)
{
    terminal_putchar(character);
    
    /*if (released == 0x00)
    {
        terminal_writestring(" Pressed\n");
    }
    else
    {
        terminal_writestring(" Released\n");
    }

    if (released == 0x01)
    {
        if (character == 'w' || character == 'a' || character == 's' || character == 'd') {
            direction = character;
        }
    }*/
}

static int timer = 0;

void ProcessTimer(void)
{
    terminal_writestring("Timer Reached\n");

    if (timer > 10)
    {
        timer = 0;
    }


    ++timer;
}

void kernel_main(void)
{
    /* Initialize terminal interface */
    terminal_initialize();
    
    asm __volatile__ ("cli");

    extern void initIDT();
    initIDT();

    extern void loadIDT();
    loadIDT();

    asm __volatile__ ("sti");

    /* Identity map the first 4MB */
    /*uint32_t i;
    for (i = 0; i < 1024; ++i)
    {
        page_directory[i] = 0x00000002;
    }

    for (i = 0; i < 1024; ++i)
    {
        page_table[i] = (i * 0x1000) | 3;
    }
    page_directory[0] = ((uint32_t)page_table) | 3;
    paging_setpagedirectory(page_directory);
    paging_enable();*/

    /*char c = read_serial();
    while (c != '\n' && c != '\r')
    {
        terminal_putchar(c);
        write_serial(c);
        c = read_serial();
    }*/

    //terminal_writestring("Paging enabled\n");
    //serial_writestring("Paging enabled\r\n");

    //terminal_writestring("After\n");

    /*for (int i = 0; i < 50; ++i)
    {
        terminal_putentryat('c', vga_entry_color(VGA_COLOR_LIGHT_GREY, VGA_COLOR_BLACK), rand() % VGA_WIDTH, rand() % VGA_HEIGHT);
    }*/
    while (1) {

    }
}
