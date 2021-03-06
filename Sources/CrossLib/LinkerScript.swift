

let linkerScriptTemplate = """
/* Linker script to configure memory regions. */
MEMORY
{
    FLASH (rx) : ORIGIN = 0x08000000, LENGTH = 2048K
    CCMRAM (rw): ORIGIN = 0x10000000, LENGTH = 64K
    RAM  (rwx) : ORIGIN = 0x20000000, LENGTH = 192K
}

/* Library configurations */
/*GROUP(libgcc.a libc.a libm.a libnosys.a)*/

/* Linker script to place sections and symbol values. Should be used together
 * with other linker script that defines memory regions FLASH and RAM.
 * It references following symbols, which must be defined in code:
 *   Reset_Handler : Entry of reset handler
 *
 * It defines following symbols, which code can use without definition:
 *   __exidx_start
 *   __exidx_end
 *   __copy_table_start__
 *   __copy_table_end__
 *   __zero_table_start__
 *   __zero_table_end__
 *   __etext
 *   __data_start__
 *   __preinit_array_start
 *   __preinit_array_end
 *   __init_array_start
 *   __init_array_end
 *   __fini_array_start
 *   __fini_array_end
 *   __data_end__
 *   __bss_start__
 *   __bss_end__
 *   __end__
 *   end
 *   __HeapBase
 *   __HeapLimit
 *   __StackLimit
 *   __StackTop
 *   __stack
 *   __Vectors_End
 *   __Vectors_Size
 */
ENTRY(Reset_Handler)

SECTIONS
{

    .text :
    {
        KEEP(*(.vectors))
        __Vectors_End = .;
        __Vectors_Size = __Vectors_End - __Vectors;
        __end__ = .;

        *(.text*)

        KEEP(*(.init))
        KEEP(*(.fini))

        /* .ctors */
        *crtbegin.o(.ctors)
        *crtbegin?.o(.ctors)
        *(EXCLUDE_FILE(*crtend?.o *crtend.o) .ctors)
        *(SORT(.ctors.*))
        *(.ctors)

        /* .dtors */
        *crtbegin.o(.dtors)
        *crtbegin?.o(.dtors)
        *(EXCLUDE_FILE(*crtend?.o *crtend.o) .dtors)
        *(SORT(.dtors.*))
        *(.dtors)

        *(.rodata*)
    } > FLASH


    __exidx_start = .;
    __exidx_end = .;

    /DISCARD/ : {
        *(.ARM.exidx* .gnu.linkonce.armexidx.*)
        *(.ARM.extab* .gnu.linkonce.armextab.*)
        *(.eh_frame*)
    }

    /* To copy multiple ROM to RAM sections,
     * uncomment .copy.table section and,
     * define __STARTUP_COPY_MULTIPLE in startup_ARMCMx.S */
    .copy.table :
    {
        . = ALIGN(4);
        __copy_table_start__ = .;
        LONG (__etext)
        LONG (__data_start__)
        LONG (__data_end__ - __data_start__)
        LONG (__edata)
        LONG (__swift_start__)
        LONG (__swift_end__ - __swift_start__)
        LONG (__sdata)
        LONG (__swift_type_start__)
        LONG (__swift_type_end__ - __swift_type_start__)
        __copy_table_end__ = .;
    } > FLASH

    /* To clear multiple BSS sections,
     * uncomment .zero.table section and,
     * define __STARTUP_CLEAR_BSS_MULTIPLE in startup_ARMCMx.S */
    /*
    .zero.table :
    {
        . = ALIGN(4);
        __zero_table_start__ = .;
        LONG (__bss_start__)
        LONG (__bss_end__ - __bss_start__)
        LONG (__bss2_start__)
        LONG (__bss2_end__ - __bss2_start__)
        __zero_table_end__ = .;
    } > FLASH
    */

    __etext = .;

    .data : AT (__etext)
    {
        __data_start__ = .;
        *(vtable)
        *(.data*)

        . = ALIGN(4);
        /* preinit data */
        PROVIDE_HIDDEN (__preinit_array_start = .);
        KEEP(*(.preinit_array))
        PROVIDE_HIDDEN (__preinit_array_end = .);

        . = ALIGN(4);
        /* init data */
        PROVIDE_HIDDEN (__init_array_start = .);
        KEEP(*(SORT(.init_array.*)))
        KEEP(*(.init_array))
        PROVIDE_HIDDEN (__init_array_end = .);


        . = ALIGN(4);
        /* finit data */
        PROVIDE_HIDDEN (__fini_array_start = .);
        KEEP(*(SORT(.fini_array.*)))
        KEEP(*(.fini_array))
        PROVIDE_HIDDEN (__fini_array_end = .);

        . = ALIGN(4);
        /* All data end */
        __data_end__ = .;

    } > RAM

    __edata = __etext + (__data_end__ - __data_start__);

    .swift : AT (__edata)
    {
        __swift_start__ = .;

        . = ALIGN(4);
        __start_swift5_typeref = .;
        *(swift5_typeref*)
        __stop_swift5_typeref = .;

        . = ALIGN(4);
        __start_swift5_reflstr = .;
        *(swift5_reflstr)
        __stop_swift5_reflstr = .;

        . = ALIGN(4);
        __start_swift5_fieldmd = .;
        *(swift5_fieldmd)
        __stop_swift5_fieldmd = .;

        . = ALIGN(4);
        __start_swift5_assocty = .;
        *(swift5_assocty)
        __stop_swift5_assocty = .;

        . = ALIGN(4);
        __start_swift5_replace = .;
        *(swift5_replace)
        __stop_swift5_replace = .;

        . = ALIGN(4);
        __start_swift5_capture = .;
        *(swift5_capture)
        __stop_swift5_capture = .;

        . = ALIGN(4);
        __start_swift5_builtin = .;
        *(swift5_builtin)
        __stop_swift5_builtin = .;

        . = ALIGN(4);
        __start_swift5_replac2 = .;
        *(swift5_replac2)
        __stop_swift5_replac2 = .;

        *(.got*)

        __swift_end__ = .;
    } > CCMRAM

    __sdata = __edata + (__swift_end__ - __swift_start__);
    .swift_type : AT(__sdata) {
        __swift_type_start__ = .;

        . = ALIGN(4);
        __start_swift5_type_metadata = .;
        *(swift5_type_metadata*)
        __stop_swift5_type_metadata = .;

        . = ALIGN(4);
        __start_swift5_protocols = .;
        *(swift5_protocols*)
        __stop_swift5_protocols = .;

        . = ALIGN(4);
        __start_swift5_protocol_conformances = .;
        *(swift5_protocol_conformances*)
        __stop_swift5_protocol_conformances = .;

        __swift_type_end__ = .;
    } > CCMRAM

    .bss :
    {
        . = ALIGN(4);
        __bss_start__ = .;
        *(.bss*)
        *(COMMON)
        . = ALIGN(4);
        __bss_end__ = .;
    } > RAM

    .heap (COPY):
    {
        __HeapBase = .;
        __end__ = .;
        end = __end__;
        KEEP(*(.heap*))
        __HeapLimit = .;
    } > RAM

    /* .stack_dummy section doesn't contains any symbols. It is only
     * used for linker to calculate size of stack sections, and assign
     * values to stack symbols later */
    .stack_dummy (COPY):
    {
        KEEP(*(.stack*))
    } > RAM

    /* Set stack top to end of RAM, and stack limit move down by
     * size of stack_dummy section */
    __StackTop = ORIGIN(RAM) + LENGTH(RAM);
    __StackLimit = __StackTop - SIZEOF(.stack_dummy);
    PROVIDE(__stack = __StackTop);

    /* Check if data + heap + stack exceeds RAM limit */
    ASSERT(__StackLimit >= __HeapLimit, "region RAM overflowed with stack")
}
"""
