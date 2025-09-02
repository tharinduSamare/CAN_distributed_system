# initialize machine trap-vector register
# register layout:
#   [31:2]: base address, which we will set to 0
#   [ 1:0]: mode, which we will set to "vectored"
li t1, 1
csrw mtvec, t1

# enable interrupts in the mie csr
# we are mostly concerned with the "fast interrupts",
# which are mapped to [30:15] in the mie csr
li t1, 0x00030000 # IRQ[0]: buttons, IRQ[1]: CAN_wrapper
csrw mie, t1

# globally enable interrupts in the mstatus csr
li t1, 0x8
csrr t2, mstatus
or t2, t1, t2
csrw mstatus, t2

# Set SP near top of 1KB RAM (IMEMSZ = 1024)
li sp, 0x00000FF0

# jump to main routine 
j _main
