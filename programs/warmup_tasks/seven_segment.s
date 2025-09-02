.global _main

_main:
    li s0, 0x000F0020   # seven segment base address
    li s1, 0
    sw s1, 0(s0)
    sw s1, 4(s0)
    li s3, 0x1F          # loop counter top value
    #li s4, 1            # wait counter top value: simulation
    li s4, 0x8FC000     # wait counter top value: synthesis
    #li s5, 0x10101010 
/*
    loop:  
        li s2, 0x10            # loop counter

        fun:
            sb s2, 0(s0)  
            sb s2, 1(s0)
            sb s2, 2(s0)
            sb s2, 3(s0)
            sb s2, 4(s0)
            sb s2, 5(s0)
            sb s2, 6(s0)
            sb s2, 7(s0)
            addi s2, s2, 1
            call wait
            ble s2, s3, fun 
            call wait
            j loop
*/
    li s2, 0x10
    loop :
        addi s2, s2, 1 
        sb s2, 0(s0) 
        call wait
        addi s2, s2, 1 
        sb s2, 1(s0)
        call wait
        addi s2, s2, 1
        sb s2, 2(s0)
        call wait
        addi s2, s2, 1
        sb s2, 3(s0)
        call wait
        addi s2, s2, 1
        sb s2, 4(s0)
        call wait
        addi s2, s2, 1
        sb s2, 5(s0)
        call wait
        addi s2, s2, 1
        sb s2, 6(s0)
        call wait
        addi s2, s2, 1
        sb s2, 7(s0) 
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

