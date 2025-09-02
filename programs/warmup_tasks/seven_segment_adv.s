.global _main

_main:
    li s0, 0x000F0020   # seven segment base address
    li s1, 0
    sw s1, 0(s0)
    sw s1, 4(s0)
    li s3, 0x0100010F          # loop counter top value
    #li s4, 1            # wait counter top value: simulation
    li s4, 0x8FC000     # wait counter top value: synthesis
    #li s5, 0x10101010 

    loop:  
        li s2, 0x01000100            # loop counter

        fun:
            sw s2, 8(s0) 
            addi s2, s2, 1
            call wait
            ble s2, s3, fun 
        li s2, 0x01010100
        sw s2, 8(s0)
        call wait
        j loop
        

wait:
    li t1, 0
    inc_i:
        addi t1, t1, 1
        ble t1, s4, inc_i

    ret

.global _sw_isr
_sw_isr:

