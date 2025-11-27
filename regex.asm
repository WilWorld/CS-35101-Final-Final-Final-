# regex.asm
# CS 35101 – Final Project
# Wil N
#
.data
    regex_prompt:      .asciiz "Enter regular expression: "
    text_prompt:       .asciiz "Enter text to evaluate: "
    output_prompt:     .asciiz "Matches:\n"

    # Buffers
    regex_buffer:      .space 256
    text_buffer:       .space 512

    # Print formatting
    comma_space:       .asciiz ", "
    newline:           .asciiz "\n"

.text
.globl main

# main program
main:
    j get_regex      # get regex from user

# Get regex input
get_regex:
    li $v0, 4
    la $a0, regex_prompt
    syscall

    li $v0, 8
    la $a0, regex_buffer
    li $a1, 256
    syscall

    j get_text       # get text input

# Get text input
get_text:
    li $v0, 4
    la $a0, text_prompt
    syscall

    li $v0, 8
    la $a0, text_buffer
    li $a1, 512
    syscall

    j print_match    # evaluate and print matches

# Print matches
print_match:
    li $v0, 4
    la $a0, output_prompt
    syscall

    # call regex evaluator
    la $a0, text_buffer
    la $a1, regex_buffer
    jal regex_evaluator

    # print newline at end
    li $v0, 4
    la $a0, newline
    syscall

    # exit
    li $v0, 10
    syscall

# Regex evaluator (dispatcher)
# a0 = text_buffer, a1 = regex_buffer
regex_evaluator:
    lb $t0, 0($a1)        # first char of regex

    li $t1, 46             # '.' ASCII
    beq $t0, $t1, match_dot

    li $t3, 91             # '[' ASCII
    beq $t0, $t3, match_range

    jr $ra                 # unsupported pattern, return

# DOT or DOT-STAR
match_dot:
    lb $t1, 1($a1)         # check next char
    li $t2, 42              # '*' ASCII
    beq $t1, $t2, match_dot_star

    # single dot match: print first char only
    lb $t0, 0($a0)
    beqz $t0, md_done
    li $v0, 11
    move $a0, $t0
    syscall
    j md_done

match_dot_star:
    move $s0, $a0           # s0 = pointer to text
md_loop:
    lb $t0, 0($s0)
    beqz $t0, md_done       # end of string
    li $v0, 11
    move $a0, $t0
    syscall

    # print separator
    li $v0, 4
    la $a0, comma_space
    syscall

    addi $s0, $s0, 1
    j md_loop
md_done:
    jr $ra

# RANGE-STAR [a-z]*
match_range:
    lb $t1, 1($a1)          # range start
    lb $t2, 3($a1)          # range end

    move $s0, $a0           # s0 = pointer to text
mr_loop:
    lb $t0, 0($s0)
    beqz $t0, mr_done        # end of text
    blt $t0, $t1, mr_next
    bgt $t0, $t2, mr_next

    # print char
    li $v0, 11
    move $a0, $t0
    syscall

    # print separator
    li $v0, 4
    la $a0, comma_space
    syscall

mr_next:
    addi $s0, $s0, 1
    j mr_loop
mr_done:
    jr $ra



 # start negated range star (test case 7)
match_negated_range:
    lb $t1, 2($a1)        # range start 
    lb $t2, 4($a1)        # range end

    move $s0, $a0         # pointer into text

mnr_loop:
    lb $t0, 0($s0)
    beqz $t0, mnr_done    # end of text

    # If in range, skip 
    bge $t0, $t1, check_end
    j print_negated
check_end:
    ble $t0, $t2, mnr_skip
    # else print 
print_negated:

    # print char
    li $v0, 11
    move $a0, $t0
    syscall

    # print separator
    li $v0, 4
    la $a0, comma_space
    syscall

    j mnr_next

mnr_skip:
    # do nothing
mnr_next:
    addi $s0, $s0, 1
    j mnr_loop

mnr_done:
    jr $ra
    
    #end negated range star




