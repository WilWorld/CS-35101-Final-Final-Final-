# regex.asm
# CS 35101 � Final Project
# Wil N
#
# TODO
#  - I/O handling
#  - Program flow
#  - Calling parser + matcher
#  - Final output formatting

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
# main (duh)
main:
	j get_regex	# Get regex from user
	
# Prompts user and reads the regex string into regex_buffer
get_regex:
    li $v0, 4
    la $a0, regex_prompt
    syscall
    
    li $v0, 8
    la $a0, regex_buffer
    li $a1, 256
    syscall
    
    j get_text # get evaluation text
    
# Prompts user and reads the evaluation text into text_buffer
get_text:
	li $v0, 4
	la $a0, text_prompt
	syscall
	
	li $v0, 8
	la $a0, text_buffer
	li $a1, 512
	syscall
	
	j flag_check
	
# Prints all matches stored in match_buffer
print_match:
	li $v0, 4
	la $a0, output_prompt
	syscall
	
	# DEBUGGING, checking the buffers
	li $v0, 4
	la $a0, text_buffer
	syscall
	
	la $a0, regex_buffer
	syscall
	#
	
	# Exit program exit
    li $v0, 10
    syscall
    
# USING FOR DEBUG STUFF
debuggin:

dispatcher:
	la $t0, regex_buffer
	lb $t1, 0($t0)
	
	li $s1, '.'
	beq $s1, $t1, dot_start
	
	li $s1, '['
	beq $s1, $t1, range_start
	
	j match_literal #test case 1
	
	
dot_start:
	addiu $t0, $t0, 1
	lb $t1, 0($t0)
	
	li $s1, '*'
	beq $t1, $s1, match_dot_star #test case 5
	
	j match_dot #test case 4
	
range_start:
	addiu $t0, $t0, 1
	lb $t1, 0($t0)
	
	beqz $t9, match_single_char #No flags were set, it should look something like "[bruh]" test case 2
	li $s1, '^'
	beq $s1, $t1, match_negated_range #test case 7
		
	li $s1, 0x7
	and $s2, $t9, $s1
	beq $s1, $s2, match_range_star_escape #test cases 8 and 9
	
	li $s1, 0x6
	and $s2, $t9, $s1
	beq $s1, $s2, match_range_star #test case 6
	
	li $s1, 0x2
	and $s2, $t9, $s1
	beq $s1, $s2, match_single_char_star #test case 3
	
flag_check:
	la $t0, regex_buffer
	lb $t1, 0($t0)
	li $t9, 0
	j flag_loop
	
flag_loop:
	beqz $t1, dispatcher
	li $s1, '\\'
	beq $s1, $t1, escape_found
	
	li $s1, '*'
	beq $s1, $t1, star_found
	
	li $s1, '-'
	beq $s1, $t1, range_found
	
	addiu, $t0, $t0, 1
	lb $t1, 0($t0)
	j flag_loop
escape_found:
	ori $t9, $t9, 0x1
	j flag_loop
star_found:
	ori $t9, $t9, 0x2
	j flag_loop
range_found:
	ori $t9, $t9, 0x4
	j flag_loop

match_literal:
	la $t0, text_buffer
	la $s0, regex_buffer

ml_outer_loop:
	lb   $t1, 0($t0)     # load buffer char
	beq  $t1, $zero, ml_print_matches   # reached end of buffer

    # start comparing pattern
	move $t2, $t0        # t2 = current buffer position
	move $t3, $s0        # t3 = pattern pointer

ml_inner_loop:
	lb   $t4, 0($t2)     # char from buffer
	lb   $t5, 0($t3)     # char from pattern

	li $t8, '\n'
	beq  $t5, '\n', ml_match_found     # end of pattern → matched all chars
	beq  $t4, $zero, ml_continue_outer   # buffer ended too early
	bne  $t4, $t5, ml_continue_outer     # mismatch

	addi $t2, $t2, 1     # advance buffer char
	addi $t3, $t3, 1     # advance pattern char
	j    ml_inner_loop

ml_continue_outer:
	addi $t0, $t0, 1     # move to next buffer index
	j    ml_outer_loop

ml_match_found:
	addi $t6, $t6, 1
	addi $t0, $t0, 1 
	j ml_outer_loop
ml_print_matches:
	beqz $t6, ml_done_printing
	
	li $v0, 4
	la $a0, regex_buffer
	syscall
	
	sub $t6, $t6, 1
	beqz $t6, ml_done_printing
	
	j ml_print_matches
	
ml_done_printing:
	j exit

match_dot_star:
match_dot:
match_single_char:
match_negated_range:
match_range_star_escape:
match_range_star:
match_single_char_star:
exit:
	li $v0, 10
	syscall
