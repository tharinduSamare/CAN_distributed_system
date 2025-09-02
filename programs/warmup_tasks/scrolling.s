.global _main

_main:
    li s0, 0x000F0040   # scrolling base address
    li s1, 0x00000000
    sw s1, 0(s0)
    li s3, 0x2FAF080 # scrolling speed counter value
    # li s1, 0x10
    sw s3, 4(s0)


    # li s4, 300            # wait counter top value: simulation
    li s4, 0x2FAF080     # wait counter top value: synthesis
    # li s5, 0x10101010 

    loop:  
        sw s3, 4(s0)
        li s1, 0x01010000           #write this data 
        sw s1, 0(s0)
        li s1, 0x01030000            
        sw s1, 0(s0)
        li s1, 0x01020000            
        sw s1, 0(s0)
        li s1, 0x01040000            
        sw s1, 0(s0)
        li s1, 0x01050000            
        sw s1, 0(s0)
        li s1, 0x01070000            
        sw s1, 0(s0)
        li s1, 0x01060000            
        sw s1, 0(s0)
        li s1, 0x01080000            
        sw s1, 0(s0)
        li s1, 0x01090000           #write this data 
        sw s1, 0(s0)
        li s1, 0x010b0000            
        sw s1, 0(s0)
        li s1, 0x010a0000            
        sw s1, 0(s0)
        li s1, 0x010c0000            
        sw s1, 0(s0)
        li s1, 0x010d0000            
        sw s1, 0(s0)
        li s1, 0x010f0000            
        sw s1, 0(s0)
        li s1, 0x010e0000            
        sw s1, 0(s0)
        li s1, 0x01000000            
        sw s1, 0(s0)

        li s1, 0x00000001       # on   
        sw s1, 0(s0)
        call wait
        call wait
        call wait
        call wait
        call wait
        call wait

        li s1, 0x00000100 # clear           
        sw s1, 0(s0)
        call wait
        li s1, 0x00000001       # off     
        sw s1, 0(s0)
        ; call wait


        li s1, 0x010f0000           # write this data deadbeef
        sw s1, 0(s0)
        li s1, 0x010e0000            
        sw s1, 0(s0)
        li s1, 0x010e0000            
        sw s1, 0(s0)
        li s1, 0x010b0000            
        sw s1, 0(s0)
        li s1, 0x010d0000            
        sw s1, 0(s0)
        li s1, 0x010a0000            
        sw s1, 0(s0)
        li s1, 0x010e0000            
        sw s1, 0(s0)
        li s1, 0x010d0000            
        sw s1, 0(s0)

        srli s1, s3 , 1
        sw s1, 4(s0)

        li s1, 0x00000001       # on   
        sw s1, 0(s0)
        call wait
        call wait
        call wait

        li s1, 0x00000100 # clear           
        sw s1, 0(s0)
        call wait

        li s1, 0x01010000            
        sw s1, 0(s0)

        call wait
        call wait

        li s1, 0x00000100 # clear           
        sw s1, 0(s0)

        li s1, 0x01020000            
        sw s1, 0(s0)
        li s1, 0x01030000            
        sw s1, 0(s0)

        call wait
        call wait

        li s1, 0x00000100 # clear           
        sw s1, 0(s0)
        
        li s1, 0x01000000            
        sw s1, 0(s0)
        li s1, 0x01000000            
        sw s1, 0(s0)
        li s1, 0x01000000            
        sw s1, 0(s0)
        li s1, 0x01000000            
        sw s1, 0(s0)
        li s1, 0x01000000            
        sw s1, 0(s0)

        call wait
        call wait
        li s1, 0x00000001       # off  
        sw s1, 0(s0)
        li s1, 0x00000100 # clear           
        sw s1, 0(s0)


    exit:    
    j loop
        

wait:
    li t1, 0
    inc_i:
        addi t1, t1, 1
        ble t1, s4, inc_i

    ret

.global _sw_isr
_sw_isr:

