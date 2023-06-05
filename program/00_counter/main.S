# RISC-V simple counter program
#
# Stanislav Zhelnio, 2020
#
            .text

start:      mv a0, zero
            li a1, 20
count:      addi a0, a0, 1
            blt a0, a1, count
reset:      mv a0, zero
            beq zero, zero, count
