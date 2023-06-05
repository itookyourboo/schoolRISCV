# RISC-V simple counter program
#
# Stanislav Zhelnio, 2020
#
            .text

start:      li a0, 255                  # limit = 255
            mv a1, zero                 # a = 0
            mv a2, zero                 # b = 0
            mv a3, zero                 # result = 0

                                        # while True:
count1:     addi a1, a1, 10             #   a += 10
            blt a0, a1, reset1          #   if limit < a:
            beq zero, zero, count2      #
reset1:     mv a1, zero                 #       a = 0

count2:     addi a2, a2, 20             #   b += 20
            blt a0, a2, reset2          #   if limit < b:
            beq zero, zero, eval        #   
reset2:     mv a2, zero                 #       b = 0

eval:       xor a3, a1, a2              #   result = cbrt(a + cbtr(b))
            beq zero, zero, count1      # 
