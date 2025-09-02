.global _main

_main:
    li s0, 0x000F0000   # LED base address
    li s2, 0            # loop counter
    li s3, 8            # loop counter top value
    li s4, 1            # wait counter top value: simulation
    # li s4, 0x1FC000     # wait counter top value: synthesis
    li s5, 0x0000F0010  # SW base address

    loop:
        li s1, 0
        sw s1, 0(s0)
        call read_sw
        call wait

        fill:
            slli s1, s1, 1
            addi s1, s1, 1
            sw s1, 0(s0)
            call repeated_wait

            addi s2, s2, 1
            ble s2, s3, fill
            li s2, 0

        flush:
            slli s1, s1, 1
            sw s1, 0(s0)
            call repeated_wait

            addi s2, s2, 1
            ble s2, s3, flush
            li s2, 0
            j loop

wait:
    li t1, 0
    inc_i:
        addi t1, t1, 1
        ble t1, s4, inc_i
    ret

read_sw:
    lw t2, 0(s5)
    li t4, 0x0000FFFF
    and t2, t2, t4 # select only 16 LSB which represent switch values
    ret

repeated_wait:
    mv t5, ra
    li t3, 0
    inc_ii:
        call wait
        addi t3, t3, 1
        ble t3, t2, inc_ii
    mv ra, t5
    ret


.global _sw_isr
_sw_isr:
