fib:
    /* Fibonacci*/
    /* Initialize x1 and x2 */
    add  x1, x0, x0
    addi x2, x0, 1
    /* 10 iterations */
    addi x4, x0, 10
loop:
    /* temp = x1 + x2 */
    add  x3, x1, x2
    /* x1 = x2 */
    add  x1, x0, x2
    /* x2 = temp */
    add  x2, x0, x3
    /* x4-- */
    addi x4, x4, -1
    /* branch if x4 not 0 */
    bne  x4, x0, loop
    /* move result to ra */
    add x1, x0, x3
