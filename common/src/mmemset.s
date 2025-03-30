
  @ tells the assembler to use the unified instruction set
  .syntax unified
  @ this directive selects the thumb (16-bit) instruction set
  .thumb
  @ this directive specifies the following symbol is a thumb-encoded function
  .thumb_func
  @ align the next variable or instruction on a 2-byte boundary
  .balign 2
  @ make the symbol visible to the linker
  .global memset_
  @ marks the symbol as being a function name
  .type memset_, STT_FUNC
memset_:
@ r0 = memory block starting address
@ r1 = 8-bit value to set every byte to
@ r2 = number of bytes to set
@ returns the starting address in r0
  cmp   r2, #0                    @ if there are 0 bytes to move
  beq   no_pop_exit               @ exit
  push  {r4}
  mov   r3, r0    @ copy address into r3

  lsls  r4, r3, #30         @ look at the 2 least-significant bits
  beq   memory_is_aligned   @ if they are 0, memory is already aligned

align_memory:               @ align memory to 4-byte boundary
  strb  r1, [r3], #1
  subs  r2, r2, #1
  beq   exit
  lsls  r4, r3, #30         @ look at the 2 least-significant bits
  bne   align_memory        @ if not aligned, repeat
  @ at this point, we are word-aligned and r2 is at least 1

memory_is_aligned:
  cmp   r2, #3
  bls   byte_copy         @ if there are 3 or fewer bytes left, byte copy

@ duplicate r1 byte into all 4 bytes of r1
  ands  r1, r1, #0xff
  lsls  r4, r1, #8
  orrs  r1, r1, r4
  lsls  r4, r1, #16
  orrs  r1, r1, r4

  bics  r4, r2, #15       @ store the upper 28 bits in r4
  beq   word_copy         @ if there are 15 or fewer bytes left, word copy

@ word-aligned and 16+ bytes to copy
  push  {r5, r6, r7}
  mov   r5, r1
  mov   r6, r1
  mov   r7, r1

quad_word_copy:
  stm   r3!, {r1, r5, r6, r7}
  subs  r4, #16
  bne   quad_word_copy

  pop  {r5, r6, r7}
  ands  r2, r2, #15
  beq   exit

  bics  r4, r2, #3       @ store the upper 30 bits in r4
  beq   byte_copy         @ if there are 3 or fewer bytes left, byte copy

word_copy:
  strb  r1, [r3], #4
  subs  r4, #4
  bne   word_copy

  ands  r2, r2, #3
  beq   exit

byte_copy:
  strb  r1, [r3], #1
  subs  r2, r2, #1
  bne   byte_copy

exit:
  pop   {r4}        @ restore previous value of r4
no_pop_exit:
  bx    lr                  @ exit function

  .size memset_, . - memset_

