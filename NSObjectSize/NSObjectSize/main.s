	.section	__TEXT,__text,regular,pure_instructions
	.build_version macos, 10, 15	sdk_version 10, 15, 4
	.globl	_main                   ## -- Begin function main
	.p2align	4, 0x90
_main:                                  ## @main
	.cfi_startproc
## %bb.0:
	pushq	%rbp
	.cfi_def_cfa_offset 16
	.cfi_offset %rbp, -16
	movq	%rsp, %rbp
	.cfi_def_cfa_register %rbp
	subq	$32, %rsp
	movl	$0, -4(%rbp)
	movl	%edi, -8(%rbp)
	movq	%rsi, -16(%rbp)
	callq	_objc_autoreleasePoolPush
	movq	_OBJC_CLASSLIST_REFERENCES_$_(%rip), %rcx
	movq	%rcx, %rdi
	movq	%rax, -32(%rbp)         ## 8-byte Spill
	callq	_objc_alloc_init
	movq	%rax, -24(%rbp)
	movq	-24(%rbp), %rax
	movq	%rax, %rdi
	callq	_objc_opt_class
	movq	%rax, %rdi
	callq	_class_getInstanceSize
	leaq	L__unnamed_cfstring_(%rip), %rcx
	movq	%rcx, %rdi
	movq	%rax, %rsi
	movb	$0, %al
	callq	_NSLog
	movq	-24(%rbp), %rcx
	movq	%rcx, %rdi
	callq	_malloc_size
	leaq	L__unnamed_cfstring_(%rip), %rcx
	movq	%rcx, %rdi
	movq	%rax, %rsi
	movb	$0, %al
	callq	_NSLog
	xorl	%edx, %edx
	movl	%edx, %esi
	leaq	-24(%rbp), %rcx
	movq	%rcx, %rdi
	callq	_objc_storeStrong
	movq	-32(%rbp), %rdi         ## 8-byte Reload
	callq	_objc_autoreleasePoolPop
	xorl	%eax, %eax
	addq	$32, %rsp
	popq	%rbp
	retq
	.cfi_endproc
                                        ## -- End function
	.section	__TEXT,__objc_classname,cstring_literals
L_OBJC_CLASS_NAME_:                     ## @OBJC_CLASS_NAME_
	.asciz	"OCObject"

	.section	__DATA,__objc_const
	.p2align	3               ## @"_OBJC_METACLASS_RO_$_OCObject"
__OBJC_METACLASS_RO_$_OCObject:
	.long	129                     ## 0x81
	.long	40                      ## 0x28
	.long	40                      ## 0x28
	.space	4
	.quad	0
	.quad	L_OBJC_CLASS_NAME_
	.quad	0
	.quad	0
	.quad	0
	.quad	0
	.quad	0

	.section	__DATA,__objc_data
	.globl	_OBJC_METACLASS_$_OCObject ## @"OBJC_METACLASS_$_OCObject"
	.p2align	3
_OBJC_METACLASS_$_OCObject:
	.quad	_OBJC_METACLASS_$_NSObject
	.quad	_OBJC_METACLASS_$_NSObject
	.quad	__objc_empty_cache
	.quad	0
	.quad	__OBJC_METACLASS_RO_$_OCObject

	.section	__DATA,__objc_const
	.p2align	3               ## @"_OBJC_CLASS_RO_$_OCObject"
__OBJC_CLASS_RO_$_OCObject:
	.long	128                     ## 0x80
	.long	8                       ## 0x8
	.long	8                       ## 0x8
	.space	4
	.quad	0
	.quad	L_OBJC_CLASS_NAME_
	.quad	0
	.quad	0
	.quad	0
	.quad	0
	.quad	0

	.section	__DATA,__objc_data
	.globl	_OBJC_CLASS_$_OCObject  ## @"OBJC_CLASS_$_OCObject"
	.p2align	3
_OBJC_CLASS_$_OCObject:
	.quad	_OBJC_METACLASS_$_OCObject
	.quad	_OBJC_CLASS_$_NSObject
	.quad	__objc_empty_cache
	.quad	0
	.quad	__OBJC_CLASS_RO_$_OCObject

	.section	__DATA,__objc_classrefs,regular,no_dead_strip
	.p2align	3               ## @"OBJC_CLASSLIST_REFERENCES_$_"
_OBJC_CLASSLIST_REFERENCES_$_:
	.quad	_OBJC_CLASS_$_NSObject

	.section	__TEXT,__cstring,cstring_literals
L_.str:                                 ## @.str
	.asciz	"%zd"

	.section	__DATA,__cfstring
	.p2align	3               ## @_unnamed_cfstring_
L__unnamed_cfstring_:
	.quad	___CFConstantStringClassReference
	.long	1992                    ## 0x7c8
	.space	4
	.quad	L_.str
	.quad	3                       ## 0x3

	.section	__DATA,__objc_classlist,regular,no_dead_strip
	.p2align	3               ## @"OBJC_LABEL_CLASS_$"
_OBJC_LABEL_CLASS_$:
	.quad	_OBJC_CLASS_$_OCObject

	.section	__DATA,__objc_imageinfo,regular,no_dead_strip
L_OBJC_IMAGE_INFO:
	.long	0
	.long	64


.subsections_via_symbols
