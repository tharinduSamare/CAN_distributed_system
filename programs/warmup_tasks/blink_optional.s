.global _main

_main:
    li s0, 0x000F0000   # LED base address
    li s2, 0            # loop counter
    li s3, 5            # loop counter top value
    li s4, 1            # wait counter top value: simulation
    # li s4, 0x1FC000     # wait counter top value: synthesis
    li s5, 3            # ON width
    li s6, 10           # off time between periods
    li s7, 8            # loop counter reverse top value

    loop:
        li s1, 0
        sw s1, 0(s0)
        call wait

        L2R_fill: # initial fill LEDs one by one
            slli s1, s1, 1
            addi s1, s1, 1
            sw s1, 0(s0)
            call wait

            addi s2, s2, 1
            ble s2, s5, L2R_fill
            li s2, 0

        shiftL: # shift on LEDs left
            slli s1, s1, 1
            sw s1, 0(s0)
            call wait

            addi s2, s2, 1
            ble s2, s3, shiftL
            li s2, 0

        addi s1, x0, 0
        R2L_fill: # fill LEDs
            srli s1, s1, 1
            xori s1, s1, 128
            sw s1, 0(s0)
            call wait

            addi s2, s2, 1
            ble s2, s5, R2L_fill
            li s2, 0

        shiftR:
            srli s1, s1, 1
            sw s1, 0(s0)
            call wait

            addi s2, s2, 1
            ble s2, s7, shiftR
            li s2, 0

        endWait:
            call wait

            addi s2, s2, 1
            ble s2, s6, endWait
            li s2, 0

        j loop

wait:
    li t1, 0
    inc_i:
        addi t1, t1, 1
        ble t1, s4, inc_i
    ret

.global _sw_isr
_sw_isr:
