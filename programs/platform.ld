MEMORY
{
  RAM (rwx) : ORIGIN = 0x00000040, LENGTH = 4096
}

SECTIONS
{
    . = ORIGIN(RAM);

    .vectortable : 
    {
        KEEP(boot/vectortable.o(.text))
    } > RAM :text

    . = 0x80;

    .boot :
    {
        KEEP(boot/boot.o(.text))
    } > RAM :text

    .text :
    {
        *(.text*)
        *(.rodata*)
    } > RAM :text

    .data :
    {
        *(.data*)
    } > RAM :data

    .bss :
    {
        *(.bss*)
        *(COMMON)
    } > RAM :data

    .sdata : {
        *(.sdata)
    } > RAM :data

    .sbss : {
        *(.sbss)
    } > RAM :data
}

PHDRS
{
    text PT_LOAD FLAGS(rx);
    data PT_LOAD FLAGS(rw);
}
