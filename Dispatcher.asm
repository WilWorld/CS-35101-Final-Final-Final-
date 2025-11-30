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
	
	addiu $t0, $t0, 1
	lb $t1, 0($t0)
	j flag_loop
escape_found:
	ori $t9, $t9, 0x1
    addiu $t0, $t0, 1
    lb    $t1, 0($t0)
	j flag_loop
star_found:
	ori $t9, $t9, 0x2
    addiu $t0, $t0, 1
    lb    $t1, 0($t0)
	j flag_loop
range_found:
	ori $t9, $t9, 0x4
    addiu $t0, $t0, 1
    lb    $t1, 0($t0)
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




#TEST CASE 4
match_dot:
   
    la $s0, text_buffer

md_loop:
    
    lb $t0, 0($s0) #load char

    
    beqz $t0, md_done #null term=done

    # Skip newline
    li $t1, '\n'
    beq $t0, $t1, md_skip

    # Print 
    move $a0, $t0
    li $v0, 11
    syscall

   
    li $v0, 4
    la $a0, comma_space
    syscall

md_skip:
    # Continue
    addiu $s0, $s0, 1
    j md_loop

md_done:
  
    j exit


#TEST CASE 2
match_single_char:
    la $s0, text_buffer      
    la $s1, regex_buffer     

msc_find_open:
    lb $t0, 0($s1)
    beqz $t0, msc_done
    li $t1, '['
    beq $t0, $t1, msc_after_open
    addiu $s1, $s1, 1
    j msc_find_open

msc_after_open:
    addiu $s1, $s1, 1        # s1 at first char in class

msc_text_loop:
    lb $t2, 0($s0)           # t2 current text char
    beqz $t2, msc_done

    move $t3, $s1            # t3 pointer into char class

msc_check_loop:
    lb $t4, 0($t3)           # t4=current class char
    li $t5, ']'
    beq $t4, $t5, msc_no_match
    beq $t4, $t2, msc_print

    addiu $t3, $t3, 1
    j msc_check_loop

msc_print:
    move $a0, $t2
    li $v0, 11
    syscall

    li $v0, 4
    la $a0, comma_space
    syscall

msc_no_match:
    addiu $s0, $s0, 1
    j msc_text_loop

msc_done:
    j exit

#TEST CASE 5

match_dot_star:
    la $s0, text_buffer     

mds_loop:
    lb $t0, 0($s0)
    beqz $t0, mds_done       # end 

    li $t1, '\n'             # ignore newline 
    beq $t0, $t1, mds_skip

    move $a0, $t0            # print
    li $v0, 11
    syscall

    li $v0, 4                
    la $a0, comma_space
    syscall

mds_skip:
    addiu $s0, $s0, 1
    j mds_loop

mds_done:
    j exit


#TEST CASE 7

match_negated_range:
    la $s0, text_buffer       
    la $s1, regex_buffer      

   
    addiu $s1, $s1, 2         # skip [ ^

    
    lb $t1, 0($s1)            # range-start

    # Skip to '-'
    addiu $s1, $s1, 1
    lb $t2, 0($s1)            # -

    # Load end 
    addiu $s1, $s1, 1
    lb $t3, 0($s1)            # range-end

nr_main_loop:
    lb $t4, 0($s0)            
    beqz $t4, nr_done         # check end

    # skip newline
    li $t5, '\n'
    beq $t4, $t5, nr_next

    # Check not in range
    blt $t4, $t1, nr_collect_start
    bgt $t4, $t3, nr_collect_start

    # skip if in negated range
    j nr_next

nr_collect_start:
    # start of continuous unit
    move $t6, $s0            # start pointer

nr_collect_loop:
    lb $t4, 0($s0)
    beqz $t4, nr_print_group

    li $t5, '\n'
    beq $t4, $t5, nr_print_group

    # Check if not in range
    blt $t4, $t1, nr_consume
    bgt $t4, $t3, nr_consume

    #  stop grouping if char is inside range
    j nr_print_group

nr_consume:
    addiu $s0, $s0, 1
    j nr_collect_loop

# Print grouped substring
nr_print_group:
    
nr_print_loop:
    beq $t6, $s0, nr_group_done

    lb $a0, 0($t6)
    li $v0, 11
    syscall

    addiu $t6, $t6, 1
    j nr_print_loop

nr_group_done:
    li $v0, 4
    la $a0, comma_space
    syscall

    j nr_main_loop

nr_next:
    addiu $s0, $s0, 1
    j nr_main_loop

nr_done:
    j exit



match_range_star_escape:
match_range_star:
match_single_char_star:
exit:
	li $v0, 10
	syscall
