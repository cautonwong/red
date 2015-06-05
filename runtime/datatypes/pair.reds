Red/System [
	Title:   "Pair! datatype runtime functions"
	Author:  "Nenad Rakocevic"
	File: 	 %pair.reds
	Tabs:	 4
	Rights:  "Copyright (C) 2011-2015 Nenad Rakocevic. All rights reserved."
	License: {
		Distributed under the Boost Software License, Version 1.0.
		See https://github.com/red/red/blob/master/BSL-License.txt
	}
]

pair: context [
	verbose: 0
	
	do-math: func [
		type	  [integer!]
		return:	  [red-pair!]
		/local
			left  [red-pair!]
			right [red-pair!]
			int	  [red-integer!]
			x	  [integer!]
			y	  [integer!]
	][
		left: as red-pair! stack/arguments
		right: left + 1
		
		assert TYPE_OF(left) = TYPE_PAIR
		assert any [
			TYPE_OF(right) = TYPE_PAIR
			TYPE_OF(right) = TYPE_INTEGER
		]
		
		switch TYPE_OF(right) [
			TYPE_PAIR 	 [
				x: right/x
				y: right/y
			]
			TYPE_INTEGER [
				int: as red-integer! right
				x: int/value
				y: x
			]
			default [
				print-line "*** Math Error: unsupported right operand for pair operation"
			]
		]
		
		switch type [
			OP_ADD [left/x: left/x + x  left/y: left/y + y]
			OP_SUB [left/x: left/x - x  left/y: left/y - y]
			OP_MUL [left/x: left/x * x  left/y: left/y * y]
			OP_DIV [left/x: left/x / x  left/y: left/y / y]
			OP_REM [left/x: left/x % x  left/y: left/y % y]
			OP_AND [left/x: left/x and x  left/y: left/y and y]
			OP_OR  [left/x: left/x or  x  left/y: left/y or  y]
			OP_XOR [left/x: left/x xor x  left/y: left/y xor y]
		]
		left
	]

	make-in: func [
		parent 	[red-block!]
		x 		[integer!]
		y 		[integer!]
		/local
			pair [red-pair!]
	][
		#if debug? = yes [if verbose > 0 [print-line "pair/make-in"]]
		
		pair: as red-pair! ALLOC_TAIL(parent)
		pair/header: TYPE_PAIR
		pair/x: x
		pair/y: y
	]
	
	push: func [
		value	[integer!]
		value2  [integer!]
		return: [red-pair!]
		/local
			pair [red-pair!]
	][
		#if debug? = yes [if verbose > 0 [print-line "pair/push"]]
		
		pair: as red-pair! stack/push*
		pair/header: TYPE_PAIR
		pair/x: value
		pair/y: value2
		pair
	]

	;-- Actions --
	
	make: func [
		proto	 [red-value!]
		spec	 [red-value!]
		return:	 [red-pair!]
		/local
			int	 [red-integer!]
			int2 [red-integer!]
	][
		#if debug? = yes [if verbose > 0 [print-line "pair/make"]]

		switch TYPE_OF(spec) [
			TYPE_INTEGER [
				int: as red-integer! spec
				push int/value int/value
			]
			default [
				int: as red-integer! block/rs-head as red-block! spec
				int2: int + 1
				if any [
					2 <> block/rs-length? as red-block! spec
					TYPE_OF(int)  <> TYPE_INTEGER
					TYPE_OF(int2) <> TYPE_INTEGER
				][
					print-line "*** MAKE Error: pair expects a block with two integers"
				]
				push int/value int2/value
			]
		]
	]
	
	form: func [
		pair	[red-pair!]
		buffer	[red-string!]
		arg		[red-value!]
		part 	[integer!]
		return: [integer!]
		/local
			formed [c-string!]
	][
		#if debug? = yes [if verbose > 0 [print-line "pair/form"]]

		formed: integer/form-signed pair/x
		string/concatenate-literal buffer formed
		part: part - length? formed						;@@ optimize by removing length?
		
		string/append-char GET_BUFFER(buffer) as-integer #"x"
		
		formed: integer/form-signed pair/y
		string/concatenate-literal buffer formed
		part - 1 - length? formed						;@@ optimize by removing length?
	]
	
	mold: func [
		pair	[red-pair!]
		buffer	[red-string!]
		only?	[logic!]
		all?	[logic!]
		flat?	[logic!]
		arg		[red-value!]
		part 	[integer!]
		indent	[integer!]		
		return: [integer!]
	][
		#if debug? = yes [if verbose > 0 [print-line "pair/mold"]]

		form pair buffer arg part
	]
	
	eval-path: func [
		parent	[red-pair!]								;-- implicit type casting
		element	[red-value!]
		set?	[logic!]
		return:	[red-value!]
		/local
			int	  [red-integer!]
			w	  [red-word!]
			value [integer!]
	][
		switch TYPE_OF(element) [
			TYPE_INTEGER [
				int: as red-integer! element
				value: int/value
				if all [value <> 1 value <> 2][
					fire [TO_ERROR(script invalid-path) stack/arguments element]
				]
			]
			TYPE_WORD [
				w: as red-word! element
				value: symbol/resolve w/symbol
				if all [value <> words/x value <> words/y][
					fire [TO_ERROR(script invalid-path) stack/arguments element]
				]
				value: either value = words/x [1][2]
			]
			default [
				fire [TO_ERROR(script invalid-path) stack/arguments element]
			]
		]
		either set? [
			int: as red-integer! stack/arguments
			either value = 1 [parent/x: int/value][parent/y: int/value]
			as red-value! int
		][
			integer/push either value = 1 [parent/x][parent/y]
		]
	]
	
	compare: func [
		left	[red-pair!]								;-- first operand
		right	[red-pair!]								;-- second operand
		op		[integer!]								;-- type of comparison
		return:	[integer!]
		/local
			diff [integer!]
	][
		#if debug? = yes [if verbose > 0 [print-line "pair/compare"]]

		diff: left/y - right/y
		if zero? diff [diff: left/x - right/x]
		SIGN_COMPARE_RESULT(diff 0)
	]
	
	remainder: func [return: [red-value!]][
		#if debug? = yes [if verbose > 0 [print-line "pair/remainder"]]
		as red-value! do-math OP_REM
	]
	
	absolute: func [
		return: [red-pair!]
		/local
			pair [red-pair!]
	][
		#if debug? = yes [if verbose > 0 [print-line "pair/absolute"]]

		pair: as red-pair! stack/arguments
		pair/x: integer/abs pair/x
		pair/y: integer/abs pair/y
		pair
	]
	
	add: func [return: [red-value!]][
		#if debug? = yes [if verbose > 0 [print-line "pair/add"]]
		as red-value! do-math OP_ADD
	]
	
	divide: func [return: [red-value!]][
		#if debug? = yes [if verbose > 0 [print-line "pair/divide"]]
		as red-value! do-math OP_DIV
	]
		
	multiply: func [return:	[red-value!]][
		#if debug? = yes [if verbose > 0 [print-line "pair/multiply"]]
		as red-value! do-math OP_MUL
	]
	
	subtract: func [return:	[red-value!]][
		#if debug? = yes [if verbose > 0 [print-line "pair/subtract"]]
		as red-value! do-math OP_SUB
	]
	
	and~: func [return:	[red-value!]][
		#if debug? = yes [if verbose > 0 [print-line "pair/and~"]]
		as red-value! do-math OP_AND
	]

	or~: func [return: [red-value!]][
		#if debug? = yes [if verbose > 0 [print-line "pair/or~"]]
		as red-value! do-math OP_OR
	]

	xor~: func [return:	[red-value!]][
		#if debug? = yes [if verbose > 0 [print-line "pair/xor~"]]
		as red-value! do-math OP_XOR
	]
	
	negate: func [
		return: [red-integer!]
		/local
			int [red-integer!]
	][
		int: as red-integer! stack/arguments
		int/value: 0 - int/value
		int 											;-- re-use argument slot for return value
	]
	
	pick: func [
		pair	[red-pair!]
		index	[integer!]
		boxed	[red-value!]
		return:	[red-value!]
	][
		#if debug? = yes [if verbose > 0 [print-line "pair/pick"]]

		if all [index <> 1 index <> 2][fire [TO_ERROR(script out-of-range) boxed]]
		as red-value! integer/push either index = 1 [pair/x][pair/y]
	]
	
	reverse: func [
		pair	[red-pair!]
		part	[red-value!]
		return:	[red-value!]
		/local
			tmp [integer!]
	][
		#if debug? = yes [if verbose > 0 [print-line "pair/reverse"]]
	
		tmp: pair/x
		pair/x: pair/y
		pair/y: tmp
		as red-value! pair
	]
	
	init: does [
		datatype/register [
			TYPE_PAIR
			TYPE_VALUE
			"pair!"
			;-- General actions --
			:make
			null			;random
			null			;reflect
			null			;to
			:form
			:mold
			:eval-path
			null			;set-path
			:compare
			;-- Scalar actions --
			:absolute
			:add
			:divide
			:multiply
			:negate
			null			;power
			:remainder
			null			;round
			:subtract
			null			;even?
			null			;odd?
			;-- Bitwise actions --
			:and~
			null			;complement
			:or~
			:xor~
			;-- Series actions --
			null			;append
			null			;at
			null			;back
			null			;change
			null			;clear
			null			;copy
			null			;find
			null			;head
			null			;head?
			null			;index?
			null			;insert
			null			;length?
			null			;next
			:pick
			null			;poke
			null			;remove
			:reverse
			null			;select
			null			;sort
			null			;skip
			null			;swap
			null			;tail
			null			;tail?
			null			;take
			null			;trim
			;-- I/O actions --
			null			;create
			null			;close
			null			;delete
			null			;modify
			null			;open
			null			;open?
			null			;query
			null			;read
			null			;rename
			null			;update
			null			;write
		]
	]
]