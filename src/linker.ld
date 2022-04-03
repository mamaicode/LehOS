/*our linker script, when will link our object files this will ensure the origin start at 1mb */
ENTRY(_start) /* program entry point  */
OUTPUT_FORMAT(binary) /* we will output as flat binary file we dont need to load headers */
SECTIONS
{
    . = 1M; /*our kernel will be loaded into 1mb in memory. sections will start at 1mb in memory */
    .text :
    {
        *(.text)  /* our text section */
    }

    .rodata :
    {
        *(.rodata)  /* defining our read only data */
    }

    .data :
    {
        *(.data)  /* defining data section */
    }

    .bss :
    {
        *(COMMON)   /*defining our bss section */
        *(.bss) 
    }
}