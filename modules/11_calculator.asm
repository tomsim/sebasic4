; --- THE FLOATING-POINT CALCULATOR -------------------------------------------

; THE TABLE OF CONSTANTS
org 0x03337
constants:
	defb	0x00, 0x00, 0x00, 0x00, 0x00	; zero
	defb	0x00, 0x00, 0x01, 0x00, 0x00	; one
	defb	0x80, 0x00, 0x00, 0x00, 0x00	; half
	defb	0x81, 0x49, 0x0f, 0xda, 0xa2	; pi/2
	defb	0x00, 0x00, 0x0a, 0x00, 0x00	; ten

; THE TABLE OF ADDRESSES
org 0x03350
tbl_addrs:
	defw	x80_fjpt				; jump-true
	defw	x80_fxch				; exchange
	defw	x80_fdel				; delete
	defw	x80_fsub				; subtract
	defw	x80_fmul				; multiply
	defw	x80_fdiv				; division
	defw	x80_ftop				; to-power
	defw	x80_fbor				; binary or
	defw	x80_fband				; binary and
	defw	x80_fcp					; >=
	defw	x80_fcp					; <=
	defw	x80_fcp					; <>
	defw	x80_fcp					; >
	defw	x80_fcp					; <
	defw	x80_fcp					; =
	defw	x80_fadd				; addition
	defw	x80_fbands				; binary and string
	defw	x80_fcp					; $ >=
	defw	x80_fcp					; $ <=
	defw	x80_fcp					; $ <>
	defw	x80_fcp					; $ >
	defw	x80_fcp					; $ <
	defw	x80_fcp					; $ =
	defw	x80_fcat				; $ addition
	defw	x80_fval				; val$
	defw	x80_fusrs				; usr-$
	defw	x80_fread				; read-in
	defw	x80_fneg				; negate
	defw	x80_fasc				; code
	defw	x80_fval				; val
	defw	x80_flen				; length
	defw	x80_fsin				; sin
	defw	x80_fcos				; cos
	defw	x80_ftan				; tan
	defw	x80_fasin				; arcsin
	defw	x80_facos				; arccos
	defw	x80_fatan				; arctan
	defw	x80_flogn				; natural log
	defw	x80_fexp				; exponent
	defw	x80_fint				; integer
	defw	x80_fsqrt				; square root
	defw	x80_fsgn				; signUM
	defw	x80_fabs				; absolute
	defw	x80_fpeek				; peek
	defw	x80_fin					; in
	defw	x80_fusr				; usr-#
	defw	x80_fstrs				; str$
	defw	x80_fchrs				; chr$
	defw	x80_fnot				; not
	defw	x80_fmove				; duplicate
	defw	x80_fmod				; n modulo m
	defw	x80_fjp					; jump
	defw	x80_fstk				; stack data
	defw	x80_fdjnz				; djnz
	defw	x80_fcp.lz				; <0
	defw	x80_fcp.gz				; >0
	defw	x80_fce					; exit calc
	defw	x80_fget				; get argument
	defw	x80_ftrn				; truncate
	defw	x80_fsgl				; single
	defw	x80_fhexs				; hexadecimal
	defw	x80_frstk				; re-stack
	defw	x80_fsgen				; series generator
	defw	x80_fstkc				; stack constant
	defw	x80_fst					; store in memory
	defw	x80_fgt					; get from memory

; THE 'CALCULATE' SUBROUTINE
org 0x33d4
calculate:
	call	stk_pntrs				; HL to last value on calculator stack

org 0x33d7
gen_ent_1:
	ld		a, b					; offset or parameter
	ld		(breg),a				; to breg

org 0x33db
gen_ent_2:
	exx								; store subroutine
	ex		(sp), hl				; return address
	exx								; in HL'

org 0x33de
re_entry:
	ld		(stkend), de			; set to stack end
	exx								; use alternate register set
	ld		a, (hl)					; get literal
	inc		hl						; HL' points to next literal

org 0x33e5
scan_ent:
	push	hl						; stack it
	and		a						; test A
	jp		p, first_3d				; jump with 0 to 61
	ld		d, a					; literal to D
	and		%01100000				; preserve bit 5 and 6
	rrca							; shift
	rrca							; right
	rrca							; into 
	rrca							; bit 1 and 2
	add		a, 124					; offsets 62-65
	ld		l, a					; L holds doubled offset
	ld		a, d					; get parameter
	and		%00011111				; from bits 0 to 4
	jr		ent_table				; address routine

org 0x33f9
first_3d:
	cp		24						; unary operation?
	jr		nc, double_a			; jump if so
	exx								; main register set
	call	stk_ptrs_2				; get pointers to operands
	exx								; alternate register set

org 0x3402
double_a:
	rlca							; two bytes per entry
	ld		l, a					; so double offset

org 0x3404
ent_table:
	ld		de, tbl_addrs			; base address
	ld		h, 0					; offset now in HL
	add		hl, de					; calculate address
	ld		e, (hl)					; get address
	inc		hl						; of routine
	ld		d, (hl)					; in DE
	ld		hl, re_entry			; stack re-entry
	ex		(sp), hl				; address
	push	de						; stack routine address 
	exx								; main register set
	ld		bc, (stkend_h)			; breg to B

; THE 'DELETE' SUBROUTINE
x80_fdel:
org 0x3417
	ret								; indirect jump to subroutine

; THE 'SINGLE OPERATION' SUBROUTINE
org 0x3418
x80_fsgl:
	pop		af						; drop re-entry address
	ld		a, (breg)				; offset to A
	exx								; alternate register set
	jr		scan_ent				; immediate jump

; THE 'TEST 5-SPACES' SUBROUTINE
org 0x341f
test_5_sp:
	push	de						; stack DE
	push	hl						; stack HL
	ld		bc, 5					; 5 bytes
	call	test_room				; test for space
	pop		hl						; unstack HL
	pop		de						; unstack DE
	ret								; end of subroutine

; THE 'STACK NUMBER' SUBROUTINE
org 0x342a
stack_num:
	ld		de, (stkend)			; get destination address
	call	x80_fmove				; move number
	ld		(stkend), de			; reset stack end
	ret								; end of subroutine

; THE 'MOVE A FLOATING-POINT NUMBER' SUBROUTINE
x80_fmove:
org 0x3436
	call	test_5_sp				; test for space
	ldir							; copy five bytes
	ret								; end of subroutine

; THE 'STACK LITERALS' SUBROUTINE
org 0x343c
x80_fstk:
	ld		h, d					; DE
	ld		l, e					; to HL

org 0x343e
stk_const:
	call	test_5_sp				; test for space
	exx								; alternate register set
	push	hl						; stack pointer to next literal
	exx								; main register set
	ex		(sp), hl				; swap result and next literal pointers
	ld		a, (hl)					; first literal to A
	and		%11000000				; divide by 64
	rlca							; to give values
	rlca							; 0 to 3
	ld		c, a					; value to C
	inc		c						; incremented (1 to 4)
	ld		a, (hl)					; get literal again
	and		%00111111				; modulo 64
	jr		nz, form_exp			; jump if remainder not zero
	inc		hl						; else get next literal
	ld		a, (hl)					; and leave unreduced

org 0x3453
form_exp:
	add		a, 80					; add 80 to get exponent
	ld		(de), a					; put it on calculator stack
	ld		a, 5					; get number
	sub		c						; of literals
	inc		hl						; next literal
	inc		de						; next position in calculator stack
	ldir							; copy literals
	ex		(sp), hl				; restore result and next literal pointers
	exx								; alternate register set
	pop		hl						; unstack next literal to HL'
	exx								; main register set
	ld		b, a					; zero bytes to B
	xor		a						; LD A, 0

org 0x3463
stk_zeros:
	dec		b						; reduce count
	ret		z						; return if done
	ld		(de), a					; stack a zero
	inc		de						; next position in calculator stack
	jr		stk_zeros				; loop until done

; THE 'MEMORY LOCATION' SUBROUTINE
org 0x3469
loc_mem:
	ld		c, a					; parameter to C
	rlca							; multiply
	rlca							; by 
	add		a, c					; five
	ld		c, a					; result
	ld		b, 0					; to BC
	add		hl, bc					; get base address
	ret								; end of subroutine

; THE 'GET FROM MEMORY AREA' SUBROYTINE
org 0x3472
x80_fgt:
	ld		hl, (mem)				; get pointer to memory area

org 0x3475
x80_fgt_2:
	push	de						; stack result pointer
	call	loc_mem					; get base address
	call	x80_fmove				; move five bytes
	pop		hl						; unstack result pointer
	ret								; end of subroutine

; THE 'STACK A CONSTANT' SUBROUTINE
org 0x347e
x80_fstkc:
	ld		hl, constants			; address of table of constants
	jr		x80_fgt_2				; indirect exit to stack constant

; THE 'STORE IN MEMORY AREA' SUBROUTINE
org 0x3483
x80_fst:
	push	hl						; stack result pointer
	ex		de, hl					; source to DE
	ld		hl, (mem)				; pointer to memory area to HL
	call	loc_mem					; get base address
	ex		de, hl					; exchange pointers
	ld		c, 5					; five bytes
	ldir							; copy
	ex		de, hl					; exchange pointers
	pop		hl						; unstack result pointer
	ret								; end of subroutine

; THE 'EXCHANGE' SUBROUTINE
org 0x3493
x80_fxch:
	ld		b, 5					; five bytes

org 0x3495
swap_byte:
	ld		a, (de)					; get each byte of second
	ld		c, a					; and first
	ld		a, (hl)					; numbers
	ld		(de), a					; first number to (DE)
	ld		(hl), c					; second number to (HL)
	inc		hl						; consider next
	inc		de						; pair of bytes
	djnz	swap_byte				; exchange five bytes
	ret								; end of subroutine

; THE 'SERIES GENERATOR' SUBROUTINE
org 0x349f
x80_fsgen:
	ld		b, a					; parameter to B
	call	gen_ent_1				; enter calc and set counter
	fmove							; z, z
	fadd							; 2 * z
	fst		0						; 2 * z		mem-0 holds 2 * z
	fdel							; -
	fstk0							; 0
	fst		2						; 0			mem-2 holds 0

org 0x34a9
g_loop:
	fmove							; b(r), b(r)
	fgt		0						; b(r), b(r), 2 * z
	fmul							; b(r), 2 * b(r) * z
	fgt		2						; b(r), 2 * b(r) * z, b(r - 1)
	fst		1						; 			mem-1 holds b(r - 1)
	fsub							; b(r), 2 * b(r) * z - b(r - 1)
	fce								; exit calculator
	call	x80_fstk				; b(r), 2 * b(r) * z - b(r - 1), a(r + 1)
	call	gen_ent_2				; re-enter calc without disturbing breg
	fadd							; b(r), 2 * b(r) * z - b(r - 1) + a(r + 1)
	fxch							; 2 * b(r) * z - b(r - 1) + a(r + 1), b(r)
	fst		2						; 			mem-2 holds b(r)
	fdel							; 2 * b(r) * z - b(r - 1) + a(r + 1) =
	fdjnz	g_loop					; b(r + 1)
	fgt		1						; b(n), b(n - 2)
	fsub							; b(n) - b(n - 2)
	fce								; exit calculator
	ret								; end of subroutine

; THE 'ABSOLUTE MAGNITUTDE' FUNCTION
org 0x34c0
x80_fabs:
	ld		b, 0xff					; B to 0xff
	jr		neg_test				; immediate jump

; THE 'UNARY MINUS' OPERATION
org 0x34c4
x80_fneg:
	call	test_zero				; zero?
	ret		c						; return if so
	ld		b, 0					; signal negate

org 0x34ca
neg_test:
	ld		a, (hl)					; get first byte
	and		a						; zero?
	jr		z, int_case				; jump if so
	inc		hl						; next byte
	ld		a, b					; 0xff = abs, 0x00 = negate
	and		%10000000				; 0x80 = abs, 0x00 = negate
	or		(hl)					; set bit 7 if abs
	rla								; reset
	ccf								; bit 7 of second byte
	rra								; for abs
	ld		(hl), a					; store second byte
	dec		hl						; point to first byte
	ret								; end of subroutine

org 0x34d9
int_case:
	push	de						; stack stack end
	push	hl						; stack pointer to number
	call	int_fetch				; get sign in C and number in DE
	pop		hl						; unstack pointer to number
	ld		a, c					; 0xff = abs, 0x00 = negate
	or		b						; 0x80 = abs, 0x00 = negate
	cpl								; 0x00 = abs, ? = negate
	jr		x80_fsgn_2				; indirect exit

; THE 'SIGNUM' FUNCTION
org 0x34e4
x80_fsgn:
	call	test_zero				; zero?
	ret		c						; return if so
	push	de						; stack stkend
	ld		de, 1					; one
	inc		hl						; point to second byte of x
	rl		(hl)					; bit 7 to carry flag
	dec		hl						; point to destination
	sbc		a, a					; zero for positive, 0xff for negative

org 0x34f1
x80_fsgn_2:
	ld		c, a					; store it in C
	call	int_store				; store result on stack
	pop		de						; unstack stkend
	ret								; end of subroutine

; THE 'IN' FUNCTION
org 0x34f7
x80_fin:
	call	find_int2				; last value to BC
	in		a, (c)					; get signal
	jr		in_pk_stk				; stack result

; THE 'PEEK' FUNCTION
org 0x34fe
x80_fpeek:
	call	find_int2				; get address in BC
	ld		a, (bc)					; get byte

org 0x3502
in_pk_stk:
	jp		stack_a					; indirect exit

; THE 'USR' FUNCTION
org 0x3505
x80_fusr:
	call	find_int2				; get address in BC
	ld		hl, stack_bc			; stack
	push	hl						; routine address
	push	bc						; stack address
	ret								; end of subroutine

; THE 'USR-STRING' FUNCTION
org 0x350e
x80_fusrs:
	call	stk_fetch				; get parameter of string x$
	dec		bc						; reduce length by one
	ld		a, c					; test
	or		b						; for zero
	jr		nz, report_a			; error if it was not one
	ld		a, (de)					; get code
	call	alpha					; is it a letter?
	jr		c, usr_range			; jump if so
	sub		144						; UDGs 0 to 20
	jr		c, report_a				; error if out of range
	inc		a						; counter next instruction

org 0x3521
usr_range:
	dec		a						; range 0 to 20
	add		a, a					; multiply
	add		a, a					; by
	add		a, a					; eight
	cp		0xa8					; in range?
	jr		nc, report_a			; error if not
	ld		bc, (udg)				; address of first UDG to BC
	add		a, c					; add
	ld		c, a					; offset
	jr		nc, usr_stack			; jump if no carry
	inc		b						; else complete address

org 0x3532
usr_stack:
	jp		stack_bc				; immediate jump

org 0x3535
report_a:
	rst		error					; error
	defb	Bad_argument			; bad argument

; THE 'TEST ZERO' SUBROUTINE
org 0x3537
test_zero:
	push	bc						; stack BC
	push	hl						; stack HL
	ld		c, a					; store value in c
	ld		a, (hl)					; get first byte
	inc		hl						; point to second byte
	or		(hl)					; OR with first
	inc		hl						; point to third byte
	or		(hl)					; OR with third
	inc		hl						; point to fourth byte
	or		(hl)					; OR with fourth
	ld		a, c					; restore A
	pop		hl						; unstack HL
	pop		bc						; unstack BC
	ret		nz						; carry reset if sum not zero
	scf								; set carry for zero
	ret								; end of subroutine

; THE 'GREATER THAN ZERO' OPERATION
org 0x3547
x80_fcp.gz:
	call	test_zero				; zero?
	ret		c						; return if so
	ld		a, 0xff					; sign byte
	jr		sign_to_c				; immediate jump

; THE 'NOT' FUNCTION
org 0x354f
x80_fnot:
	call	test_zero				; zero? 
	jr		fp_0_or_1				; immediate jump

; THE 'LESS THAN ZERO' OPERATION
org 0x3554
x80_fcp.lz:
	xor		a						; LD A, 0

org 0x3555
sign_to_c:
	inc		hl						; point to sign
	xor		(hl)					; carry reset if positive, set if negative
	dec		hl						; restore result pointer
	rlca							; opposite effect from x80_fcp.gz

; THE 'ZERO OR ONE' SUBROUTINE
org 0x3559
fp_0_or_1:
	push	hl						; stack result pointer
	ld		a, 0					; clear A, leave carry flag alone
	ld		(hl), a					; zero first byte
	inc		hl						; point to next byte
	ld		(hl), a					; zero second byte
	inc		hl						; point to next byte
	rla								; carry flag to A
	ld		(hl), a					; set third byte to one or zero
	rra								; restore A to zero
	inc		hl						; point to next byte
	ld		(hl), a					; zero fourth byte
	inc		hl						; point to next byte
	ld		(hl), a					; zero fifth byte
	pop		hl						; unstack result pointer
	ret								; end of subroutine

; THE 'OR' OPERATION
org 0x3569
x80_fbor:
	ex		de, hl					; HL points to second number
	call	test_zero				; zero?
	ex		de, hl					; restore pointers
	ret		c						; return if zero
	scf								; set carry flag
	jr		fp_0_or_1				; immediate jump

; THE 'NUMBER AND NUMBER' OPERATION
org 0x3572
x80_fband:
	ex		de, hl					; HL points to second number
	call	test_zero				; zero?
	ex		de, hl					; restore pointers
	ret		nc						; return if not zero
	and		a						; reset carry flag
	jr		fp_0_or_1				; immediate jump

; THE ' STRING AND NUMBER' OPERATION
org 0x357b
x80_fbands:
	ex		de, hl					; HL = number, DE = $
	call	test_zero				; zero?
	ex		de, hl					; restore pointers
	ret		nc						; return if not zero
	dec		de						; point to fifth string byte
	xor		a						; LD A, 0
	ld		(de), a					; zero high byte of length
	dec		de						; point to fourth string byte
	ld		(de), a					; zero low byte of length
	inc		de						; restore
	inc		de						; pointer
	ret								; end of subroutine

; THE 'COMPARISON' OPERATIONS
org 0x3589
x80_fcp:
	ld		a, b					; offset to A
	bit		2, a					; >= 4?
	jr		nz, ex_or_not			; jump if not
	dec		a						; reduce range

org 0x358f
ex_or_not:
	rrca							; set carry for >= and <
	jr		nc, nu_or_str			; jump if carry flag not set
	push	af						; stack AF
	push	hl						; stack HL
	call	x80_fxch				; exchange
	pop		de						; unstack DE
	ex		de, hl					; swap HL with DE
	pop		af						; unstack AF

org 0x359a
nu_or_str:
	rrca							; update carry flag
	push	af						; stack it
	bit		2, a					; string comparison?
	jr		nz, strings				; jump if so
	call	x80_fsub				; subtraction
	jr		end_tests				; end of subroutine

org 0x35a5
strings:
	call	stk_fetch				; length and start address of second string
	push	de						; stack
	push	bc						; them
	call	stk_fetch				; first string
	pop		hl						; unstack second string length

org 0x35ae
byte_comp:
	ld		a, l					; is second
	or		h						; string null?
	ex		(sp), hl				; 
	ld		a, b					; 
	jr		nz, sec_plus			; jump if not null
	or		c						; both null?

org 0x35b5
secnd_low:
	pop		bc						; unstack BC
	jr		z, both_null			; jump if so
	pop		af						; restore carry flag
	ccf								; and complement
	jr		str_test				; immediate jump

org 0x35bc
both_null:
	pop		af						; restore carry flag
	jr		str_test				; immediate jump

org 0x35bf
sec_plus:
	or		c						; first less?
	jr		z, frst_less			; jump if so
	ld		a, (de)					; compare
	sub		(hl)					; next byte
	jr		c, frst_less			; jump if first byte less
	jr		nz, secnd_low			; jump if second byte less
	dec		bc						; bytes equal
	inc		de						; reduce
	inc		hl						; lengths
	ex		(sp), hl				; and jump
	dec		hl						; to compare
	jr		byte_comp				; next byte

org 0x35cf
frst_less:
	pop		bc						; unstack BC
	pop		af						; unstack AF
	and		a						; clear carry flag

org 0x35d2
str_test:
	push	af						; stack carry flag
	fwait							; x
	fstk0							; x, 0
	fce								; exit calculator

org 0x35d6
end_tests:
	pop		af						; unstack carry flag
	push	af						; restack carry flag
	call	c, x80_fnot				; jump if set
	pop		af						; unstack carry flag
	push	af						; restack carry flag
	call	nc, x80_fcp.gz			; jump if not set
	pop		af						; unstack carry flag
	rrca							; rotate into carry
	call	nc, x80_fnot			; jump if not set
	ret								; end of subroutine

; THE 'STRING CONCATENATION' OPERATION
org 0x35e6
x80_fcat:
	call	stk_fetch				; get parameters of
	push	de						; second string
	push	bc						; and stack them
	call	stk_fetch				; get parameters of fisrt string
	pop		hl						; unstack length to HL
	push	hl						; and restack
	push	de						; stack paramters
	push	bc						; of fisrt string
	add		hl, bc					; find total length
	ld		b, h					; and store
	ld		c, l					; in BC
	rst		bc_spaces				; make space
	call	stk_sto_str				; parameters to calculator stack
	pop		bc						; unstack first
	pop		hl						; string parameters
	ld		a, c					; test for
	or		b						; null
	jr		z, other_str			; jump if so
	ldir							; else copy to workspace

org 0x3601
other_str:
	pop		bc						; unstack second
	pop		hl						; string parameters
	ld		a, c					; test for
	or		b						; null
	jr		z, stk_pntrs			; jump if so
	ldir							; else copy to workspace

; THE 'STK-PNTRS' SUBROUTINE
org 0x3609
stk_pntrs:
	ld		hl, (stkend)			; stack end to HL

org 0x360c
stk_ptrs_2:
	ld		d, h					; DE points to second
	ld		e, l					; operand
	dec		hl						; make
	dec		hl						; HL
	dec		hl						; point
	dec		hl						; to first
	dec		hl						; operand
	ret								; end of subroutine

; THE 'CHR$' FUNCTION
org 0x3614
x80_fchrs:
	call	fp_to_a					; last value to A
	jr		c, report_bd			; error if greater than 255
	jr		nz, report_bd			; or negative
	call	bc_1_space				; make one space
	ld		(de), a					; value to workspace
	jr		x80_fstrs_1				; exit via x80-fstrs-1

org 0x3621
report_bd:
	rst		error					; error
	defb	Integer_out_of_range	; out of range

; THE 'VAL' AND 'VAL$' FUNCTION
org 0x3623
x80_fval:
	rst		get_char				; get current value of ch-add
	push	hl						; stack it
	ld		a, b					; offset to A
	add		a, 227					; carry set for VAL, reset for VAL$
	sbc		a, a					; bit 6 set for VAL, reset for VAL$
	push	af						; stack flag
	call	stk_fetch				; get parameters
	push	de						; stack start address
	inc		bc						; increase length by one
	rst		bc_spaces				; make space
	pop		hl						; unstack start address
	ld		(ch_add), de			; pointer to ch-add
	push	de						; stack it
	ldir							; copy the string to the workspace
	ex		de, hl					; swap pointers
	dec		hl						; last byte of string
	ld		(hl), ctrl_enter		; replace with carriage return
	res		7, (iy + _flags)		; reset syntax flag
	call	scanning				; check syntax
	cp		ctrl_enter				; end of expression?
	jr		nz, v_rport_c			; error if not
	pop		hl						; unstack start address
	pop		af						; unstack flag
	xor		(iy + _flags)			; test bit 6
	and		%01000000				; against syntax scan

org 0x364e
v_rport_c:
	jp		nz, report_c			; error if no match
	ld		(ch_add), hl			; start address to ch-add
	set		7, (iy + _flags)		; set line execution flag
	call	scanning				; use string as next expression
	pop		hl						; get last value
	ld		(ch_add), hl			; and restore ch-add
	jr		stk_pntrs				; exit and reset pointers

; THE 'STR$' FUNCTION
x80_fstrs:
org 0x3661
.ifdef ROM1
	ld		a, (attr_t)				; preserve temporary
	ex		af, af'					;'attribute
.endif
	call	bc_1_space				; make one space
	ld		(k_cur), hl				; set cursor address
	push	hl						; stack it
	ld		hl, (curchl)			; get current channel
	push	hl						; stack it
	ld		a, 0xff					; channel R
	call	chan_open				; open it
	call	print_fp				; print last value
	pop		hl						; unstack current channel
	call	chan_flag				; restore flags
.ifdef ROM1
	ex		af, af'					;'restore
	ld		(attr_t), a				; temporary attribute
.endif
	pop		de						; unstack start of string
	ld		hl, (k_cur)				; get cursor address
	and		a						; calculate
	sbc		hl, de					; length
	ld		b, h					; store in
	ld		c, l					; BC
.ifdef ROM0
org 0x3681
	defs	8, 255					; unused locations (ROM 0)
.endif

org 0x3689
x80_fstrs_1:
	call	stk_sto_str				; parameters to calculator stack
	ex		de, hl					; reset pointers
	ret								; end of subroutine

; THE 'READ-IN' SUBROUTINE
org 0x368e
x80_fread:
	ld		hl, (curchl)			; get current channel
	push	hl						; stack it
	call	str_alter_1				; open new channel if valid
	call	in_chan_k				; keyboard?
	jr		nz, x80_fread_2			; jump if not
	halt							; read keyboard

org 0x369b
x80_fread_2:
	call	input_ad				; accept input
	ld		bc, 0					; default length zero
	jr		nc, r_i_store			; jump if no signal
	inc		c						; increase length
	rst		bc_spaces				; make one space
	ld		(de), a					; put string in space

org 0x36a6
r_i_store:
	call	stk_sto_str				; get parameters to calculator stack
	pop		hl						; restore curchl
	call	chan_flag				; restore flags
	jp		stk_pntrs				; exit and set pointers

; THE 'CODE' FUNCTION
org 0x36b0
x80_fasc:
	call	stk_fetch				; get string parameters
	ld		a, c					; test for
	or		b						; zero
	jr		z, stk_code				; jump with null string
	ld		a, (de)					; code of first character to A

org 0x36b8
stk_code:
	jp		stack_a					; exit and return value

; THE 'LEN' FUNCTION
org 0x36bb
x80_flen:
	call	stk_fetch				; get string parameters
	jp		stack_bc				; exit and return length

; THE 'DECREASE THE COUNTER' SUBROUTINE
org 0x36c1
x80_fdjnz:
	exx								; alternate register set
	push	hl						; stack literal pointer
	ld		hl, breg				; get breg (counter)
	dec		(hl)					; reduce it
	pop		hl						; unstack literal pointer
	jr		nz, jump_2				; jump if not zero
	inc		hl						; next literal
	exx								; main register set
	ret								; end of subroutine

; THE 'JUMP' SUBROUTINE
org 0x36cd
x80_fjp:
	exx								; alternate register set

org 0x36ce
jump_2:
	ld		e, (hl)					; size of relative jump
	ld		a, e					; copy to E
	rla								; set carry with negative
	sbc		a, a					; A to zero, or 255 for negative or 
	ld		d, a					; copy to D
	add		hl, de					; new next literal pointer
	exx								; main register set
	ret								; end of subroutine

; THE 'JUMP ON TRUE' SUBROUTINE
org 0x36d6
x80_fjpt:
	inc		de						; point to
	inc		de						; third byte
	ld		a, (de)					; copy to A
	dec		de						; point to
	dec		de						; first byte
	and		a						; zero?
	jr		nz, x80_fjp				; jump if not
	exx								; alternate register set
	inc		hl						; skip jump length
	exx								; main register set
	ret								; end of subroutine

; THE 'END-CALC' SUBROUTINE
org 0x36e2
x80_fce:
	pop		af						; drop return address
	exx								; alternate register set
	ex		(sp), hl				; stack address in HL'
	exx								; main register set
	ret								; exit via HL'

; THE 'MODULUS' SUBROUTINE
org 0x36e7
x80_fmod:
	fwait							; n
	fst		1						; n, m					mem-1 = m
	fdel							; n
	fmove							; n, n
	fgt		1						; n, n, m
	fdiv							; n, n/m
	fint							; n, int (n/m)
	fgt		1						; n, int (n/m), m
	fxch							; n, m, int (n/m)
	fst		1						; n, m, int (n/m)		mem-1 = int (n/m)
	fmul							; n, m * int (n/m)
	fsub							; n - m * int (n/m)
	fgt		1						; n - m * int (n/m), int (n/m)
	fce								; exit calculator
	ret								; end of subroutine

; THE 'INT' FUNCTION
org 0x36f6
x80_fint:
	fwait							; x
	fmove							; x, x
	fcp		.lz						; x, (1/0)
	fjpt	x_neg					; x
	ftrn							; i(x)
	fce								; exit calculator
	ret								; exit function

org 0x36fe
x_neg:
	fmove							; x, x
	ftrn							; x, i (x)
	fst		0						; x, i (x)				mem-0 = i (x)
	fsub							; x-i (x)
	fgt		0						; x-i (x), i (x)
	fxch							; i (x), (1/0)
	fnot							; i (x)
	fjpt	exit					; i (x)
	fstk1							; i (x), 1
	fsub							; i (x) - 1

org 0x3709
exit:
	fce								; i (x) or i (x) - 1
	ret								; end of function

; THE 'EXPONENTIAL' FUNCTION
org 0x370b
x80_fexp:
	fwait							; x
	fstk							; x, 1/log 2
	defb	0xf1					; exponent
	defb	0x38, 0xaa, 0x3b, 0x29	; mantissa
	fmul							; x/log 2 = y
	fmove							; y, y
	fint							; y, int y = n
	fst		3						; y, n					mem-3 = n
	fsub							; y - n = w
	fmove							; w, w
	fadd							; 2 * w
	fstk1							; 2 * w, 1
	fsub							; 2 * w - 1 = z
	defb	0x88					; series generator
	defb	0x13					; exponent
	defb	0x36					; mantissa
	defb	0x58					; exponent
	defb	0x65, 0x66				; mantissa
	defb	0x9d					; exponent
	defb	0x78, 0x65, 0x40		; mantissa
	defb	0xa2					; exponent
	defb	0x60, 0x32, 0xc9		; mantissa
	defb	0xe7					; exponent
	defb	0x21, 0xf7, 0xaf, 0x24	; mantissa
	defb	0xeb					; exponent
	defb	0x2f, 0xb0, 0xb0, 0x14	; mantissa
	defb	0xee					; exponent
	defb	0x7e, 0xbb, 0x94, 0x58	; mantissa
	defb	0xf1					; exponent
	defb	0x3a, 0x7e, 0xf8, 0xcf	; mantissa
	fgt		3						; 2 * w, n
	fce								; exit calculator
	call	fp_to_a					; abs (n) mod 256 to A
	jr		nz, n_negtv				; jump if n negative
	jr		c, report_6b			; error if abs (n) > 255
	add		a, (hl)					; add abs (n) to exponent
	jr		nc, result_ok			; jump if e not > 255

org 0x3749
report_6b:
	rst		error					; error
	defb	Number_too_large		; overflow

org 0x374b
n_negtv:
	jr		c, rslt_zero			; zero if n < -255
	sub		(hl)					; subtract abs (n)
	jr		nc, rslt_zero			; zero if e < zero
	neg								; -e to +e

org 0x3752
result_ok:
	ld		(hl), a					; store exponent
	ret								; exit

org 0x3754
rslt_zero:
	fwait							; make
	fdel							; last value
	fstk0							; zero
	fce								; exit calculator
	ret								; end of function

; THE 'NATURAL LOGARITHM' FUNCTION
org 0x3759
x80_flogn:
	fwait							; x
	frstk							; full floating point form
	fmove							; x, x
	fcp		.gz						; x, (1/0)
	fjpt	valid					; x
	fce								; exit calculator

org 0x3760
report_ab:
	rst		error					; error
	defb	Bad_argument			; argument

org 0x3762
valid:
	fce								; exit calculator
	ld		a, (hl)					; exponent to A
	ld		(hl), end_marker		; x to x'
	call	stack_a					; x', e
	fwait							; x', e
	fstk							; x', e, 128
	defb	0x38					; exponent
	defb	0x00					; mantissa
	fsub							; x', e'
	fxch							; e', x'
	fmove							; e, x', x'
	fstk							; e', x', x', 0.8
	defb	0xf0					; exponent
	defb	0x4c, 0xcc, 0xcc, 0xcd	; mantissa
	fsub							; e', x', x' - 0.8
	fcp		.gz						; e', x', (1/0)
	fjpt	gre_8					; e', x'
	fxch							; x', e'
	fstk1							; x, e', 1
	fsub							; x, e' - 1
	fxch							; e' - 1, x\
	fce								; exit calculator
	inc		(hl)					; 2 * x'
	fwait							; e' - 1, 2 * x'

org 0x3781
gre_8:
	fxch							; 2 * x', e' - 1
	fstk							; x', e', log 2
	defb	0xf0					; exponent
	defb	0x31, 0x72, 0x17, 0xf8	; mantissa
	fmul							; x', e' * log 2 = y1
									; 2 * x', (e' -1 ) * log 2 = y2
	fxch							; y1, x'		x' large
									; y2, 2 * x'	x' small
	fstk.5							; y1, x', 0.5
									; y2, 2 * x', 0.5
	fsub							; y1, x' - 0.5
									; y2, 2 * x' - 0.5
	fstk.5							; y1, x' - 0.5, 0.5 
									; y2, 2 * x' - 0.5, 0.5
	fsub							; y1, x' - 1
									; y2, 2 * x' - 1
	fmove							; y, x' - 1, x' - 1
									; y2, 2 * x' - 1, 2 * x' - 1
	fstk							; y1, x' - 1, x' - 1, 2.5
									; y2, 2 * x' - 1, 2 * x' - 1, 2.5
	defb	0x32					; exponent
	defb	0x20					; mantissa
	fmul							; y1, x' - 1, 2.5 * x' - 2.5
									; y2, 2 * x' - 1, 5 * x' - 2.5
	fstk.5							; y1, x' - 1, 2.5 * x' - 2.5, 0.5
									; y2, 2 * x' - 1, 5 * x' - 2.5, 0.5
	fsub							; y1, x' - 1, 2.5 * x' - 3 = z
									; y2, 2 * x' - 1, 5 * x' - 3 = z
	defb	0x8c					; series generator
	defb	0x11					; exponent
	defb	0xac					; mantissa
	defb	0x14					; exponent
	defb	0x09					; mantissa
	defb	0x56					; exponent
	defb	0xda, 0xa5				; mantissa
	defb	0x59					; exponent
	defb	0x30, 0xc5				; mantissa
	defb	0x5c					; exponent
	defb	0x90, 0xaa				; mantissa
	defb	0x9e					; exponent
	defb	0x70, 0x6f, 0x61		; mantissa
	defb	0xa1					; exponent
	defb	0xcb, 0xda, 0x96		; mantissa
	defb	0xa4					; exponent
	defb	0x31, 0x9f, 0xb4		; mantissa
	defb	0xe7					; exponent
	defb	0xa0, 0xfe, 0x5c, 0xfc	; mantissa
	defb	0xea					; exponent
	defb	0x1b, 0x43, 0xca, 0x36	; mantissa
	defb	0xed					; exponent
	defb	0xa7, 0x9c, 0x7e, 0x5e	; mantissa
	defb	0xf0					; exponent
	defb	0x6e, 0x23, 0x80, 0x93	; mantissa
	fmul							; y1 = log (2** e'), log x'
									; y2 = log (2** (e' - 1)), log (2 * x')
	fadd							; log (2** e') * x')			= log x
									; log (2** (e' - 1) * 2 * x')	= log x
	fce								; exit calculator
	ret								; log x

; THE 'REDUCE ARGUMENT' SUBROUTINE
org 0x37c7
x80_fget:
	fwait							; x
	fstk							; x, 1/(2 * pi)
	defb	0xee					; exponent
	defb	0x22, 0xf9, 0x83, 0x6e	; mantissa
	fmul							; x/(2 * pi)
	fmove							; x/(2 * pi), x/(2 * pi)
	fstk.5							; x/(2 * pi), x/(2 * pi), 0.5
	fadd							; x/(2 * pi), x/(2 * pi) + 0.5
	fint							; x/(2 * pi), int (x/(2 * pi) + 0.5)
	fsub							; x/(2 * pi) - int (x/(2 * pi) + 0.5) = y 
	fmove							; y, y
	fadd							; 2 * y
	fmove							; 2 * y, 2 * y
	fadd							; 4 * y
	fmove							; 4 * y, 4 * y
	fabs							; 4 * y, abs (4 * y)
	fstk1							; 4 * y, abs (4 * y), 1
	fsub							; 4 * y, abs (4 * y) - 1 = z
	fmove							; 4 * y, z, z
	fcp		.gz						; 4 * y, z, (1/0)
	fst		0						; mem-0 = test result
	fjpt	zplus					; 4 * y, z
	fdel							; 4 * y
	fce								; 4 * y = v	(case 1)
	ret								; exit

org 0x37e4
zplus:
	fstk1							; 4 * y, z, 1
	fsub							; 4 * y, z - 1
	fxch							; z - 1, 4 * y
	fcp		.lz						; z - 1, (1/0)
	fjpt	yneg					; z - 1
	fneg							; 1 - z

org 0x37eb
yneg:
	fce								; 1 - z = v (case 2)
	ret								; z - 1 = v (case 3)

; THE 'COSINE' FUNCTION
org 0x37ed
x80_fcos:
	fwait							; x
	fget							; v
	fabs							; abs v
	fstk1							; abs v, 1
	fsub							; abs v - 1
	fgt		0						; abs v - 1, (1/0)
	fjpt	c_ent					; abs v - 1 = w
	fneg							; 1 - abs v
	fjp		c_ent					; 1 - abs v = w

; THE 'SINE' FUNCTION
org 0x37f8
x80_fsin:
	fwait							; x
	fget							; w

org 0x37fa
c_ent:
	fmove							; w, w
	fmove							; w, w, w
	fmul							; w, w, w * w
	fmove							; w, 2 * w * w, 1
	fadd							; w, 2 * w * w
	fstk1							; w, 2 * w * w, 1
	fsub							; w, 2 * w * w - 1 = z
	defb	0x86					; series-06
	defb	0x14					; exponent
	defb	0xe6					; mantissa
	defb	0x5c					; exponent
	defb	0x1f, 0x0b				; mantissa
	defb	0xa3					; exponent
	defb	0x8f, 0x38, 0xee		; mantissa
	defb	0xe9					; exponent
	defb	0x15, 0x63, 0xbb, 0x23	; mantissa
	defb	0xee					; exponent
	defb	0x92, 0x0d, 0xcd, 0xed	; mantissa
	defb	0xf1					; exponent
	defb	0x23, 0x5d, 0x1b, 0xea	; mantissa
	fmul							; sin (pi*w/2) = sin x (or = cos x)
	fce								; sin x (or cos x)
	ret								; end of subroutine

; THE 'TANGENT' FUNCTION
org 0x381d
x80_ftan:
	fwait							; x
	fmove							; x, x
	fsin							; x, sin x
	fxch							; sin x, cos x
	fcos							; sin x/cos x = tan x
	fdiv							; test for overflow
	fce								; tan x
	ret								; end of subroutine

; THE 'ARCTANGENT' FUNCTION
org 0x3825
x80_fatan:
	call	x80_frstk				; get floating point form of x
	ld		a, (hl)					; get exponent
	cp		0x81					; y = x?
	jr		c, small				; jump if so
	fwait							; x
	fstk1							; x, 1
	fneg							; x, -1
	fxch							; -1, x
	fdiv							; -1/x
	fmove							; -1/x, -1/x
	fcp		.lz						; -1/x, (1/0)
	fstkpix.5						; -1/x, pi/2, (1/0) 
	fxch							; -1/x, pi/2
	fjpt	cases					; jump if y = -1/x w = pi/2
	fneg							; -1/2, =pi/2
	fjp		cases					; jump if y = -1/x w = -pi/2

org 0x383b
small:
	fwait							; y
	fstk0							; y, 0

org 0x383d
cases:
	fxch							; w, y
	fmove							; w, y, y
	fmove							; w, y, y, y
	fmul							; w, y, y * y
	fmove							; w, y, y * y, y * y
	fadd							; w, y, 2 * y * y
	fstk1							; w, y, 2 * y * y, 1
	fsub							; w, y, 2 * y * y - 1 = z
	defb	0x8c					; series-0c
	defb	0x10					; exponent
	defb	0xb2					; mantissa
	defb	0x13					; exponent
	defb	0x0e					; mantissa
	defb	0x55					; exponent
	defb	0xe4, 0x8d				; mantissa
	defb	0x58					; exponent
	defb	0x39, 0xbc				; mantissa
	defb	0x5b					; exponent
	defb	0x98, 0xfd				; mantissa
	defb	0x9e					; exponent
	defb	0x00, 0x36, 0x75		; mantissa
	defb	0xa0					; exponent
	defb	0xdb, 0xe8, 0xb4		; mantissa
	defb	0x63					; exponent
	defb	0x42, 0xc4				; mantissa
	defb	0xe6					; exponent
	defb	0xb5, 0x09, 0x36, 0xbe	; mantissa
	defb	0xe9					; exponent
	defb	0x36, 0x73, 0x1b, 0x5d	; mantissa
	defb	0xec					; exponent
	defb	0xd8, 0xde, 0x63, 0xbe	; mantissa
	defb	0xf0					; exponent
	defb	0x61, 0xa1, 0xb3, 0x0c	; mantissa
	fmul							; w, atn x			case 1
									; w, atn (-1/x) 	case 2 and 3
	fadd							; atn x
	fce								; exit calculator
	ret								; end of subroutine

; THE 'ARCSINE' FUNCTION
org 0x3876
x80_fasin:
	fwait							; x
	fmove							; x, x
	fmove							; x, x, x
	fmul							; x, x * x
	fstk1							; x, x * x, 1
	fsub							; x, x * x - 1
	fneg							; x, 1 - x * x
	fsqrt							; x, sqr (1 - x * x)
	fstk1							; x, sqr (1 - x * x), 1
	fadd							; x, 1 + sqr (1 - x * x)
	fdiv							; x/(1 + sqr (1 - x * x)) = tan
	fatan							; y/2
	fmove							; y/2, y/2
	fadd							; y = asn x
	fce								; exit calculator
	ret								; end of subroutine

; THE 'ARCCOSINE' FUNCTION
org 0x3886
x80_facos:
	fwait							; x
	fasin							; asn x
	fstkpix.5						; asn x, pi/2
	fsub							; asn x - pi/2
	fneg							; pi/2 - asn x = acs x
	fce								; exit calculator
	ret								; end of subroutineend of subroutine

;THE 'SQUARE ROOT' FUNCTION
org 0x388d
x80_fsqrt:
	fwait							; x
	frstk							; full floating point form
	fst		0						; store in mem-0
	fce								; exit calculator
	ld		a, (hl)					; value to A
	and		a						; test against zero
	ret		z						; return if so
	add		a, 128					; set carry if greater or equal to 128
	rra								; divide by two
	ld		(hl), a					; replace value
	inc		hl						; next location
	ld		a, (hl)					; get sign bit
	rla								; rotate left
	jp		c, report_ab			; error with negative number
	ld		(hl), 127				; mantissa starts at about one
	ld		b, 5					; set counter

org 0x38a2
squrlp:
	fwait							; x
	fmove							; x, x
	fgt		0						; x, x, n
	fxch							; x, n, x
	fdiv							; x, n/x
	fadd							; x + n/x
	fce								; exit calculator
	dec		(hl)					; halve value
	djnz	squrlp					; loop until found
	ret								; end of subroutine

; THE 'EXPONENTIATION' OPERATION
org 0x38ad
x80_ftop:
	fwait							; x
	fxch							; y, x
	fmove							; y, x, x
	fnot							; y, x, (1/0)
	fjpt	xis0					; y, x
	flogn							; y, log x
	fmul							; y * log x
	fce								; exit calculator
	jp		x80_fexp				; form exp (y * log x)

org 0x38b9
xis0:
	fdel							; y
	fmove							; y, y
	fnot							; y, (1/0)
	fjpt	one						; y
	fstk0							; y, 0
	fxch							; 0, y
	fcp		.gz						; 0, (1/0)
	fjpt	last					; 0
	fstk1							; 0, 1
	fxch							; 1, 0
	fdiv							; divide by zero gives arithmetic overflow

org 0x38c6
one:
	fdel							; -
	fstk1							; 1

org 0x38c8
last:
	fce								; exit calculator
	ret								; end of subroutine

; THE 'HEX$' FUNCTION
org 0x38ca
x80_fhexs:
	call	fp_to_bc				; get value
	jp		c, report_bd			; error if
	jp		nz, report_bd			; out of range
	push	bc						; stack it
	ld		bc, 4					; make four
	rst		bc_spaces				; spaces
	pop		hl						; unstack value
	push	de						; stack pointer
	ld		a, h					; get value
	call	x80_fhexs_2				; convert to string
	ld		a, l					; get value
	call	x80_fhexs_2				; convert to string
	pop		de						; restore pointer
	call	stk_sto_str				; put on calculator stack
	jp		stk_pntrs				; exit and restore pointers

org 0x38e9
x80_fhexs_2:
	ld		h, a					; store value in H
	rlca							; move high
	rlca							; nibble
	rlca							; to low
	rlca							; nibble
	call	x80_fhexs_3				; do first part
	ld		a, h					; restore low nibble

org 0x38f2
x80_fhexs_3:
	and		%00001111				; clear high nibble
	cp		0x0a					; A to F?
	jr		c, x80_fhexs_4			; jump if not
	add		a, 7					; offset to ASCII 'A'

org 0x38fa
x80_fhexs_4:
	add		a, '0'					; offset to ASCII zero
	ld		(de), a					; store character
	inc		de						; next position
	ret								; end of subroutine

; -----------------------------------------------------------------------------

org 0x38ff
	defs	2, 255					; IM2 vector
