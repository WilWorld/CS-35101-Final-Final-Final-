# regex.asm
# CS 35101 – Final Project
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
	
	j print_match # print results
	
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


 #dot+star TEST CASE 5
   match_dot_star:
   
    li $v0, 4
    la $a0, text_buffer
    syscall
    jr $ra
    #end of dot+star
    
    
    
    #range+star TEST CASE 6
    
    match_range_star:
    # range start = regex_buffer[1]
    lb $t1, 1($a1)

    # range end = regex_buffer[3]
    lb $t2, 3($a1)

    # Load first text char
    lb $t0, 0($a0)

mrs_loop:
    beqz $t0, mrs_done       # branch if end of text
    blt $t0, $t1, mrs_next   # if char < start of range go to next
    bgt $t0, $t2, mrs_next   # if char > end of range go to next

    # print character
    li $v0, 11
    move $a0, $t0
    syscall

    # seperator
    li $v0, 4
    la $a0, comma_space
    syscall

# next char in text
mrs_next:
    addi $a0, $a0, 1        
    lb $t0, 0($a0)
    j mrs_loop

mrs_done:
    jr $ra

#end of range+star

	

