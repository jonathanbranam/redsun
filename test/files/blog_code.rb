#class Traits < Flash::Display::Sprite
class Traits
=begin
	def can_call(v)
		@can_call
	end
	def pub_call=(v)
		@can_call = v
	end
	def pub_call
		@can_call
	end
	private :can_call
=end
	def test_private
		#can_call = 10
		self.can_call = 10
		up
		self.can_call = 10
	end
=begin
	private "can_call=".to_sym
	def can_call=(v)
		@can_call = v
	end
=end
	def locals
		# "typical" example without name clashing
		local_var = 10              #1 [:setlocal, 2]
		puts(local_var)             #2 [:getlocal, 2]
		local_var                   #3 has no effect and is skipped by compiler

		puts(method_call)           #4 [:send, :method_call, 0, nil, 24, nil]
		method_call                 #5 [:send, :method_call, 0, nil, 24, nil]
		method_call()               #6 [:send, :method_call, 0, nil, 8, nil]
	end
	def changing_meaning
		# In this example, we begin with a naked ref which calls the method
		puts(changes_to_var)        #1 [:send, :changes_to_var, 0, nil, 24, nil]
		changes_to_var              #2 [:send, :changes_to_var, 0, nil, 24, nil]

		# Next we create a local var with the same name
		changes_to_var = 10         #3 [:setlocal, 2]

		# And further naked references will access the local var
		puts(changes_to_var)        #4 [:getlocal, 2]
		changes_to_var              #5 has no effect and is skipped by compiler

		# Being explicit with parens is the only way to do a method call again
		changes_to_var()            #6 [:send, :changes_to_var, 0, nil, 8, nil]
	end
	def explicit_call_on_self
		# explicit send to self calls method
		self.explicit_call = 10     #1 [:putself], [:send, :explicit_call=, 1, nil, 8, nil]
		self.explicit_call          #2 [:putself], [:send, :explicit_call, 0, nil, 0, nil]
		self.explicit_call()        #3 [:putself], [:send, :explicit_call, 0, nil, 0, nil]

		# this is normal behavior, using a name sends method to nil
		puts(explicit_call)         #4 [:putnil], [:send, :explicit_call, 0, nil, 24, nil]

		# now we set a local var with same name as previous method
		explicit_call = 10          #5 [:setlocal, 2]

		# and a naked access is now compiled as a :getlocal
		puts(explicit_call)         #6 [:getlocal, 2]
		explicit_call               #7 has no effect and is skipped by compiler

		# adding parens forces a method call on nil
		# same behavior as statement #4 above, but now the parens are required
		explicit_call()             #8 [:putnil], [:send, :explicit_call, 0, nil, 8, nil]
	end
	def call_proc
		# Create a proc and stick it in local var
		proc_var = proc { |a,b| puts 'hi' }  # [:setlocal, 2]

		# no, that tries to call a method on nil called :proc_var
		proc_var()                  # [:send, :proc_var, 0, nil, 8, nil]

		# gets the value of the local var
		puts(proc_var)              # [:getlocal, 2]

		# This is how you call a proc
		proc_var.call               # [:getlocal, 2]
		                            # [:send, :call, 0, nil, 0, nil]

		# Or like this - b/c you can't overload the parens operator
		proc_var[1,2]               # [:getlocal, 2]
		                            # [:send, :[], 2, nil, 0, nil]

		# This also works, naturally
		proc_var.call(1,2)          # [:getlocal, 2]
		                            # [:send, :call, 2, nil, 0, nil]

	end
	def initialize()
		super

		trait_set.alpha = 0.5
		self.rect_size = 100
		another_one= 100
		whats_this
		@x = 0
		@y = 0
		trait_get.graphics.trait_call.line_style(1,1,1)
		trait_get.graphics.trait_call.draw_rect(@x,@y,rect_size,whats_this)

	end
	def rect_size=(i)
		@rect_size = i
	end
	def rect_size
		@rect_size
	end

end
=begin
Without def rect_size= :

[
  YARVInstructionSequence/SimpleDataFormat, 1, 1, 1,
  {:arg_size=>0, :local_size=>1, :stack_max=>2},
  <compiled>, <compiled>,
  top, [], 0, [],
  [
    1,
    [:putnil],
    label_1,
    [:getinlinecache, nil, :label_12],
    [:getconstant, :Flash],
    [:getconstant, :Display],
    [:getconstant, :Sprite],
    [:setinlinecache, :label_1],
    label_12,
    [defineclass, Traits,
    [
      YARVInstructionSequence/SimpleDataFormat, 1, 1, 1,
      {:arg_size=>0, :local_size=>1, :stack_max=>1},
      <class:Traits>, <compiled>,
      class, [], 0, [],
      [
        2,
        [:putnil],
        [definemethod, initialize,
        [
          YARVInstructionSequence/SimpleDataFormat, 1, 1, 1,
          {:arg_size=>0, :local_size=>2, :stack_max=>5},
          initialize, <compiled>,
          method, [:rect_size], 0, [],
          [
            3,
            [:putobject, false],
            [:invokesuper, 0, nil, 0],
            [:pop],
            4,
            [:putnil],
            [:send, :trait_set, 0, nil, 24, nil],
            [:putobject, 0.5],
            [:send, :alpha=, 1, nil, 0, nil],
            [:pop],
            5,
            [:putobject, 100],
            [:setlocal, 2],
            6,
            [:putobject, 0],
            [:setinstancevariable, :@x],
            7,
            [:putobject, 0],
            [:setinstancevariable, :@y],
            8,
            [:putnil],
            [:send, :trait_get, 0, nil, 24, nil],
            [:send, :graphics, 0, nil, 0, nil],
            [:send, :trait_call, 0, nil, 0, nil],
            [:putobject, 1],
            [:putobject, 1],
            [:putobject, 1],
            [:send, :line_style, 3, nil, 0, nil],
            [:pop],
            9,
            [:putnil],
            [:send, :trait_get, 0, nil, 24, nil],
            [:send, :graphics, 0, nil, 0, nil],
            [:send, :trait_call, 0, nil, 0, nil],
            [:getinstancevariable, :@x],
            [:getinstancevariable, :@y],
            [:getlocal, 2],
            [:getlocal, 2],
            [:send, :draw_rect, 4, nil, 0, nil],
            [:leave],
            ]
          ]
        ]
        [:putnil],
        [:leave],
        ]
      ]
    ]
    [:leave],
    ]
  ]



=end
