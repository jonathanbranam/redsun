class EmptySwf < Flash::Display::Sprite
	def initialize
		super()
	end
end

=begin
[
	"YARVInstructionSequence/SimpleDataFormat", 1, 1, 1,
	{:arg_size=>0, :local_size=>1, :stack_max=>2},
	"<compiled>", "<compiled>",
	:top, [], 0, [],
	[
		1,
		[:putnil],
		:label_1,
		[:getinlinecache, nil, :label_12],
		[:getconstant, :Flash],
		[:getconstant, :Display],
		[:getconstant, :Sprite],
		[:setinlinecache, :label_1],
		:label_12,
		[
			:defineclass, :EmptySwf,
			[
				"YARVInstructionSequence/SimpleDataFormat", 1, 1, 1,
				{:arg_size=>0, :local_size=>1, :stack_max=>1},
				"<class:EmptySwf>", "<compiled>",
				:class, [], 0, [],
				[
					2,
					[:putnil],
					[:definemethod, :initialize,
						[
							"YARVInstructionSequence/SimpleDataFormat", 1, 1, 1,
							{:arg_size=>0, :local_size=>1, :stack_max=>1},
							"initialize", "<compiled>",
							:method, [], 0, [],
							[
								3,
								[:putobject, true],
								[:invokesuper, 0, nil, 0],
								[:leave]
							]
						],
						0
					],
					[:putnil],
					[:leave]
				]
			],
			0
		],
		[:leave]
	]
]
=end

