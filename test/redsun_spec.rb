#!/usr/bin/env ruby

require 'redsun'
require 'load_files'

describe "new generation" do
  before :each do
    @tx = RedSun::Translate.new()
  end
  def frame_get_prop_op(op, sym)
    op.class.should == RedSun::ABC::GetProperty
    op.index.nil?.should == false
    op.property.nil?.should == false
    op.property.name.should == sym
    op.property.ns.name.should == :""
  end
  def frame_call_prop_op(op, sym)
    op.class.should == RedSun::ABC::CallPropVoid
    op.index.nil?.should == false
    op.property.nil?.should == false
    op.property.kind.should == RedSun::ABC::Multiname::MultinameQName
    op.property.name.should == sym
    op.property.ns.name.should == :""
  end
  it "should tx putnil to RubyFrame call" do
    r = @tx.push_insn([], [:putnil], [])
    r[0].class.should == RedSun::ABC::GetLocal1
    frame_call_prop_op(r[1], :putnil)
    r.length.should == 2
  end
  it "should tx no instruction operands" do
    r = @tx.push_insn_ops([], [:putnil])
    r.length.should == 0
  end
  it "should tx send instruction operands" do
    r = @tx.push_insn_ops([], [:send, :puts, 1, nil, 8, nil])
    r[0].class.should == RedSun::ABC::PushString
    r[0].string.should == :puts
    r[1].class.should == RedSun::ABC::PushByte
    r[1].value.should == 1
    r[2].class.should == RedSun::ABC::GetLocal1
    frame_get_prop_op(r[3], :Qnil)
    r[4].class.should == RedSun::ABC::PushByte
    r[4].value.should == 8
    r[5].class.should == RedSun::ABC::GetLocal1
    frame_get_prop_op(r[6], :Qnil)
    r.length.should == 7
  end
  it "should tx send to RubyFrame call with operands" do
    r = @tx.push_insn([], [:send, :puts, 1, nil, 8, nil], [])
    r[0].class.should == RedSun::ABC::GetLocal1
    r[1].class.should == RedSun::ABC::PushString
    r[1].string.should == :puts
    r[2].class.should == RedSun::ABC::PushByte
    r[2].value.should == 1
    r[3].class.should == RedSun::ABC::GetLocal1
    frame_get_prop_op(r[4], :Qnil)
    r[5].class.should == RedSun::ABC::PushByte
    r[5].value.should == 8
    r[6].class.should == RedSun::ABC::GetLocal1
    frame_get_prop_op(r[7], :Qnil)
    frame_call_prop_op(r[8], :send)
    r.length.should == 9
  end
end

describe RedSun::ABC::ABCFile do
  before(:each) do
    @empty_data = "10002e000000000d0011456d7074795377662f456d70747953776608456d7074795377660d666c6173682e646973706c6179065370726974653d473a5c776f726b5c65636c697073655c61727469636c65735c44796e616d6963416374696f6e5363726970745c7372633b3b456d7074795377662e6173064f626a6563740c666c6173682e6576656e74730f4576656e74446973706174636865720d446973706c61794f626a65637411496e7465726163746976654f626a65637416446973706c61794f626a656374436f6e7461696e6572051601160418031608000807010307020507010707040907020a07020b07020c0300000100000002000000010000010102090300010000000102010104010003000101080903d030470000010101090a0ef106f007d030f008d04900f00947000002020101082bd030f106f0056500600330600430600530600630600730600230600258001d1d1d1d1d1d6801f106f003470000".pack_as_hex
  end
  #describe "(read/write empty swf abc_data)" do
    it "should work" do
      f = RedSun::ABC::ABCFile.new
      f.read_from_str @empty_data

      str = f.to_s

      stride = 16
      0.step(str.length, stride) do |i|
        str[i..i+stride].unpack_as_hex.should == @empty_data[i..i+stride].unpack_as_hex
      end
      str.should == @empty_data
    end
  #end

  #describe "(read empty swf abc_data constant pool)" do
    before(:each) do
      @f = RedSun::ABC::ABCFile.new
      @f.read_from_str @empty_data
    end

    it "should parse methods" do
      @f.abc_methods.length.should == 3

      method = @f.abc_methods[0]
      method.name_index.should == 1
      method.param_types.length.should == 0
      method.return_type_index.should == 0
      method.body.method_index.should == 0

      method = @f.abc_methods[1]
      method.name_index.should == 2
      method.name.should == "EmptySwf/EmptySwf".to_sym
      method.param_types.length.should == 0
      method.return_type_index.should == 0
      method.body.method_index.should == 1

      method = @f.abc_methods[2]
      method.name_index.should == 1
      method.param_types.length.should == 0
      method.return_type_index.should == 0
      method.body.method_index.should == 2

    end

    it "should parse method bodies" do
      @f.method_bodies.length.should == 3

      body = @f.method_bodies[0]
      body.method_index.should == 0
      body.max_stack.should == 1
      body.local_count.should == 1
      body.init_scope_depth.should == 8
      body.max_scope_depth.should == 9
      body.code.codes.length.should == 3
      body.exceptions.length.should == 0
      body.traits.length.should == 0

      body = @f.method_bodies[1]
      body.method_index.should == 1
      body.max_stack.should == 1
      body.local_count.should == 1
      body.init_scope_depth.should == 9
      body.max_scope_depth.should == 10
      body.code.codes.length.should == 9
      body.exceptions.length.should == 0
      body.traits.length.should == 0

      body = @f.method_bodies[2]
      body.method_index.should == 2
      body.max_stack.should == 2
      body.local_count.should == 1
      body.init_scope_depth.should == 1
      body.max_scope_depth.should == 8
      body.code.codes.length.should == 29
      body.exceptions.length.should == 0
      body.traits.length.should == 0

    end

    it "should parse method bodies" do
      @f.instances.length.should == 1
      @f.classes.length.should == 1

      inst = @f.instances[0]
      cls = @f.classes[0]

      inst.name_index.should == 1
      inst.name.kind == RedSun::ABC::Multiname::MultinameQName
      inst.name.name_index.should == 3
      inst.name.name.should == "EmptySwf".to_sym
      inst.name.ns.name_index.should == 1
      inst.name.ns.name.should == "".to_sym

      inst.super_name_index.should == 2
      inst.super_name.kind == RedSun::ABC::Multiname::MultinameQName
      inst.super_name.name_index.should == 5
      inst.super_name.name.should == "Sprite".to_sym
      inst.super_name.ns.name_index.should == 4
      inst.super_name.ns.name.should == "flash.display".to_sym

      inst.protected_namespace_index.should == 3
      inst.protected_namespace.name.should == "EmptySwf".to_sym
      inst.protected_namespace.kind.should == 24

      inst.flags.should == RedSun::ABC::Instance::Sealed | RedSun::ABC::Instance::ProtectedNamespace
      inst.interfaces.length.should == 0

      inst.iinit_index.should == 1
      inst.iinit.name_index.should == 2
      inst.iinit.name.should == "EmptySwf/EmptySwf".to_sym
      inst.iinit.body.method_index.should == 1
      inst.traits.length.should == 0
    end

    it "should parse constant pool" do
      cp = @f.constant_pool
      cp.ints.length.should == 1
      cp.uints.length.should == 1
      cp.doubles.length.should == 1

      cp.strings.length.should == 13
      cp.strings[1].should == "".to_sym
      cp.strings[2].should == "EmptySwf/EmptySwf".to_sym
      cp.strings[3].should == "EmptySwf".to_sym
      cp.strings[4].should == "flash.display".to_sym
      cp.strings[5].should == "Sprite".to_sym
      cp.strings[12].should == "DisplayObjectContainer".to_sym

      cp.namespaces.length.should == 5
      cp.namespaces[1].kind == 22
      cp.namespaces[1].name_index == 1
      cp.namespaces[1].name == ""
      cp.namespaces[2].kind == 22
      cp.namespaces[2].name_index == 4
      cp.namespaces[2].name == "flash.display".to_sym
      cp.namespaces[3].kind == 24
      cp.namespaces[3].name_index == 3
      cp.namespaces[3].name == "EmptySwf".to_sym
      cp.namespaces[4].kind == 22
      cp.namespaces[4].name_index == 8
      cp.namespaces[4].name == "flash.events".to_sym

      cp.ns_sets.length.should == 1

      cp.multinames.length.should == 8
      cp.multinames.each do |m|
        m.kind.should == RedSun::ABC::Multiname::MultinameQName if m.kind
      end
      cp.multinames[1].name_index.should == 3
      cp.multinames[1].name.should == "EmptySwf".to_sym
      cp.multinames[1].ns_index.should == 1
      cp.multinames[1].ns.name_index.should == 1
      cp.multinames[1].ns.name.should == "".to_sym

      cp.multinames[2].name_index.should == 5
      cp.multinames[2].name.should == "Sprite".to_sym
      cp.multinames[2].ns_index.should == 2
      cp.multinames[2].ns.name_index.should == 4
      cp.multinames[2].ns.name.should == "flash.display".to_sym

      cp.multinames[7].name_index.should == 12
      cp.multinames[7].name.should == "DisplayObjectContainer".to_sym
      cp.multinames[7].ns_index.should == 2
      cp.multinames[7].ns.name_index.should == 4
      cp.multinames[7].ns.name.should == "flash.display".to_sym

    end
  #end
end

describe RedSun::ABC::ConstantPool do
  it "should find no constants " do
    data = "00000000000000".pack_as_hex
    cp = RedSun::ABC::ConstantPool.new RedSun::StringSwfIO.new(data)
    cp.ints.length.should == 1
    cp.ints[0].should == nil

    cp.uints.length.should == 1
    cp.uints[0].should == nil

    cp.doubles.length.should == 1
    cp.doubles[0].should == nil

    cp.strings.length.should == 1
    cp.strings[0].should == nil

    cp.namespaces.length.should == 1
    cp.namespaces[0].should == nil

    cp.ns_sets.length.should == 1
    cp.ns_sets[0].should == nil

    cp.multinames.length.should == 1
    cp.multinames[0].class.should == RedSun::ABC::Multiname

  end

  it "should read ints" do
    data = "0500017F7E000000000000".pack_as_hex
    cp = RedSun::ABC::ConstantPool.new RedSun::StringSwfIO.new(data)

    cp.ints.length.should == 5
    cp.ints.length.should == 5
    cp.ints[0].should == nil
    cp.ints[1].should == 0
    cp.ints[2].should == 1
    cp.ints[3].should == -1
    cp.ints[4].should == -2
  end

  it "should read uints" do
    data = "000500017F7E0000000000".pack_as_hex
    cp = RedSun::ABC::ConstantPool.new RedSun::StringSwfIO.new(data)

    cp.ints.length.should == 1

    cp.uints.length.should == 5
    cp.uints.length.should == 5
    cp.uints[0].should == nil
    cp.uints[1].should == 0
    cp.uints[2].should == 1
    cp.uints[3].should == 127
    cp.uints[4].should == 126
  end

  it "should read doubles" do
    data = "000002010203040506070800000000".pack_as_hex
    cp = RedSun::ABC::ConstantPool.new RedSun::StringSwfIO.new(data)

    cp.ints.length.should == 1
    cp.uints.length.should == 1

    cp.doubles.length.should == 2
    cp.doubles[0].should == nil
    cp.doubles[1].should == 0x0403020108070605
  end

  it "should read strings" do
    data = "000000".pack_as_hex+
      "040001".pack_as_hex+"A"+
      "06".pack_as_hex + "hello!" +
      "000000".pack_as_hex
    cp = RedSun::ABC::ConstantPool.new RedSun::StringSwfIO.new(data)
    cp.ints.length.should == 1
    cp.uints.length.should == 1
    cp.doubles.length.should == 1

    cp.strings.length.should == 4
    cp.strings[0].should == nil
    cp.strings[1].should == "".to_sym
    cp.strings[2].should == "A".to_sym
    cp.strings[3].should == "hello!".to_sym
  end

  it "should read empty string" do
    data = "0000000200000000".pack_as_hex
    cp = RedSun::ABC::ConstantPool.new RedSun::StringSwfIO.new(data)
    cp.ints.length.should == 1
    cp.uints.length.should == 1
    cp.doubles.length.should == 1

    cp.strings.length.should == 2
    cp.strings[0].should == nil
    cp.strings[1].should == "".to_sym

  end

  it "should read namespaces" do
    data = "000000020141".pack_as_hex+
      "0201010000".pack_as_hex
    cp = RedSun::ABC::ConstantPool.new RedSun::StringSwfIO.new(data)
    cp.ints.length.should == 1
    cp.uints.length.should == 1
    cp.doubles.length.should == 1
    cp.strings.length.should == 2

    cp.namespaces.length.should == 2
    cp.namespaces[0].should == nil
    cp.namespaces[1].kind.should == 1
    cp.namespaces[1].name_index.should == 1
    cp.namespaces[1].name.should == :A

  end

  it "should read namespace set" do
    data = "0000000301410142".pack_as_hex+
      "0301010102".pack_as_hex+
      "0202010200".pack_as_hex
    cp = RedSun::ABC::ConstantPool.new RedSun::StringSwfIO.new(data)
    cp.ints.length.should == 1
    cp.uints.length.should == 1
    cp.doubles.length.should == 1
    cp.strings.length.should == 3
    cp.namespaces.length.should == 3

    cp.ns_sets.length.should == 2
    cp.ns_sets[0].should == nil
    cp.ns_sets[1].ns.length.should == 2
    cp.ns_sets[1].ns_indices.length == 2
    cp.ns_sets[1].ns_indices[0].should == 1
    cp.ns_sets[1].ns[0].name.should == :A
    cp.ns_sets[1].ns_indices[1].should == 2
    cp.ns_sets[1].ns[1].name.should == :B

  end

  it "should read multinames" do
    data = "0000000301410142".pack_as_hex+
      "0301010102".pack_as_hex+
      "02020102".pack_as_hex+
      "06".pack_as_hex+
      "070101".pack_as_hex+
      "0F02".pack_as_hex+
      "11".pack_as_hex+
      "090101".pack_as_hex+
      "1B01".pack_as_hex
    cp = RedSun::ABC::ConstantPool.new RedSun::StringSwfIO.new(data)
    cp.ints.length.should == 1
    cp.uints.length.should == 1
    cp.doubles.length.should == 1
    cp.strings.length.should == 3
    cp.namespaces.length.should == 3
    cp.ns_sets.length.should == 2

    cp.multinames.length.should == 6
    cp.multinames[0].class.should == RedSun::ABC::Multiname

    cp.multinames[1].kind.should == RedSun::ABC::Multiname::MultinameQName
    cp.multinames[1].ns_index.should == 1
    cp.multinames[1].ns.name.should == "A".to_sym
    cp.multinames[1].name_index.should == 1
    cp.multinames[1].name.should == "A".to_sym

    cp.multinames[2].kind.should == RedSun::ABC::Multiname::MultinameRTQName
    cp.multinames[2].name_index.should == 2
    cp.multinames[2].name.should == "B".to_sym

    cp.multinames[3].kind.should == RedSun::ABC::Multiname::MultinameRTQNameL

    cp.multinames[4].kind.should == RedSun::ABC::Multiname::MultinameC
    cp.multinames[4].ns_set_index.should == 1
    cp.multinames[4].ns_set.ns_indices.length.should == 2
    cp.multinames[4].ns_set.ns[0].name.should == "A".to_sym
    cp.multinames[4].ns_set.ns[1].name.should == "B".to_sym
    cp.multinames[4].name_index.should == 1
    cp.multinames[4].name.should == "A".to_sym

    cp.multinames[5].kind.should == RedSun::ABC::Multiname::MultinameL
    cp.multinames[5].ns_set_index.should == 1
    cp.multinames[5].ns_set.ns_indices.length.should == 2
    cp.multinames[5].ns_set.ns[0].name.should == "A".to_sym
    cp.multinames[5].ns_set.ns[1].name.should == "B".to_sym


  end

end

describe "(string packing)" do
  it "should pack hex string" do
    @str = "A1017FFF"
    @pack = @str.pack_as_hex
    @pack.should == 0xA1.chr+0x01.chr+0x7F.chr+0xFF.chr
  end

  it "should pack binary string" do
    @str = "10101010000000001111111100000001"
    @pack = @str.pack_as_binary
    @pack[0].should == 0xaa.chr
    @pack[1].should == 0x0.chr
    @pack[2].should == 0xFF.chr
    @pack[3].should == 0x01.chr
  end
end

describe RedSun::Tags::FileAttributes do
  before(:each) do
    @fa = RedSun::Tags::FileAttributes.new
    @as3 = "08000000".pack_as_hex
    @m_as3_net = "19000000".pack_as_hex
    @as3_net = "09000000".pack_as_hex
    @m = "10000000".pack_as_hex
  end

  it "should write metadata true" do
    @fa.has_metadata = true
    @fa.actionscript3 = false
    @fa.use_network = false
    @fa.update_contents
    @fa.contents.should == @m
  end

  it "should write as3 and network true" do
    @fa.has_metadata = false
    @fa.actionscript3 = true
    @fa.use_network = true
    @fa.update_contents
    @fa.contents.should == @as3_net
  end

  it "should write all true" do
    @fa.has_metadata = true
    @fa.actionscript3 = true
    @fa.use_network = true
    @fa.update_contents
    @fa.contents.should == @m_as3_net
  end

  it "should write as3 true" do
    @fa.has_metadata = false
    @fa.actionscript3 = true
    @fa.use_network = false
    @fa.update_contents
    @fa.contents.should == @as3
  end

  it "should read as3 true" do
    @fa.contents = @as3
    @fa.parse_contents
    @fa.has_metadata.should == false
    @fa.actionscript3.should == true
    @fa.use_network.should == false
  end

  it "should read as3 and network as true" do
    @fa.contents = @as3_net
    @fa.parse_contents
    @fa.has_metadata.should == false
    @fa.actionscript3.should == true
    @fa.use_network.should == true
  end

  it "should read metadata as true" do
    @fa.contents = @m
    @fa.parse_contents
    @fa.has_metadata.should == true
    @fa.actionscript3.should == false
    @fa.use_network.should == false
  end

  it "should read all as true" do
    @fa.contents = @m_as3_net
    @fa.parse_contents
    @fa.has_metadata.should == true
    @fa.actionscript3.should == true
    @fa.use_network.should == true
  end
end

describe RedSun::Swf do
  before(:each) do
    @empty_swf_contents = "43575309db03000078da5d52316fd34014beb39338090d6d55145a214424224508623bc942d3d422344d29031544480865c8e57c494c1cdb9ccf7532b121c6fe006610123b6367c4923fc0c2c4587e01dcd94dd372b275f7bef7bdefbdbbf7a620f10b80eb9f00d884a0b5be050078b7f10302d0a0e6a0fea2d52e4c27b6e3d7b9b55b1a31e6d5352d0c4335aca92e1d6a95eded6d4daf6ad56a9933cafecc61685a76fcbb25231268111f53cb6396eb14848dfa6ec0764ba57355135f887a01b52349136bc42613e2305faba8152e64e2fac0a513c40ce479b6859190d3a6657fe4e271888e497960237fd4d0964411c32c6613a369ba7d5268db645aa8159acbf8881d5304d95c166a5cba2612d12a76279a475d33c0bca601978a822f8708092fe8db963f22d4089cb1e386718a252a389812c4dcab8c0526fc367286011a1263ff59e4bbb0a31a1123c6d3c02ed42a0f0a555d7f189721d086f6df6b9f23bc8106b8b3166c152b453c2ece74f5a5aad668d3ee9061e7b13772db4fda2a98af864727dd6f1f4ebf86cf8b371bdd2f27adb5df7203ec49ef3f7e7e9d95f950a4f82f839f7c30c4fa0beecd6ef1f3f7ecfec463b34e3800a737de7240f807144d4805ac01555073607dc1d11687f4e2908b1aa79a96efd96896ea78d46264f7a0de0d5d3aee126c5b9e4fba88320bdbc4efb6660e9a58b889c50d3bd155bb3ec53b3b0b3d15f9a9a3fe1b82d94aac4c8ec51cadee8badc5b32086792b72ad38614c5d3f7418a1888b1e9318c95ff1efb97ca82d87d0641ee6139b723e0dd20a941529a9404549641429ab48d71469458eef2f81688750cac81100250813903f1f84e98c3cd70f841366b2d7ffa4ce94b97e969e1f82b30c47254e4cdf9feb1c4f12d093f55e42ef25f55e4aef297a4fe2df2b703b5a23c839320fc96d880c175d78c48d7fd630290d".pack_as_hex
  end

  it "(read abc)" do
    s = RedSun::Swf.new
    s.read_from @empty_swf_contents

    cons = s.tags[8].abc_file.find_method "EmptySwf/EmptySwf".to_sym
    cons.class.should == RedSun::ABC::Method
    cons.name.should == "EmptySwf/EmptySwf".to_sym
    cons.name_index.should == 2

    unnamed = s.tags[8].abc_file.find_method "".to_sym
    unnamed.class.should == Array
    unnamed.length.should == 2
  end

  it "(read/write MethodDecompile file)" do
    s = RedSun::Swf.new
    uc = s.uncompress_swf_string TestFiles::MethodDecompile
    s2 = RedSun::Swf.new
    s2.read_from TestFiles::MethodDecompile
    s2.compressed = false
    uc2 = s2.write_to_string

    stride = 16
    0.step(uc.length, stride) do |i|
      uc2[i..i+stride].should == uc[i..i+stride]
    end

  end

  it "(read/write swf file)" do
    s = RedSun::Swf.new
    uc = s.uncompress_swf_string @empty_swf_contents
    s2 = RedSun::Swf.new
    s2.read_from @empty_swf_contents
    s2.compressed = false
    uc2 = s2.write_to_string

    stride = 16
    0.step(uc.length, stride) do |i|
      uc2[i..i+stride].should == uc[i..i+stride]
    end

  end

  #describe "(parse swf header)" do
    before(:each) do
      @swfr_p = RedSun::Swf.new
      swf_string = "FWS"+"0913000000".pack_as_hex+
        ("01011000"+
        "01111111"+
        "00100000"+
        "10000000"+
        "00111101"+
        "00000001"+
        "00000000").pack_as_binary+
        "00180100".pack_as_hex
      @swfr_p.read_from swf_string
    end

    it "should parse swf header" do
      @swfr_p.sig.should == "FWS"
      @swfr_p.compressed.should == false
      @swfr_p.version.should == 9
      @swfr_p.length.should == 19

      @r = @swfr_p.frame_size
      @r[:xmin].should == 127
      @r[:xmax].should == 260
      @r[:ymin].should == 15
      @r[:ymax].should == 514

      @swfr_p.frame_rate[:whole].should == 24
      @swfr_p.frame_rate[:fraction].should == 0
      @swfr_p.frame_count.should == 1
    end
  #end
  #describe "(write swf header)" do
    before(:each) do
      @swfr_w = RedSun::Swf.new
      @std_rect_string = "780004e200000ea600".pack_as_hex
      @rect_string =
        ("01011000"+
        "01111111"+
        "00100000"+
        "10000000"+
        "00111101"+
        "00000001"+
        "00000000").pack_as_binary
      @swf_string = "FWS"+"0913000000".pack_as_hex+
        @rect_string+"00180100".pack_as_hex
    end

    it "should write swf header" do
      @swfr_w.compressed = false
      @swfr_w.version = 9
      #@swfr_w.length = 0xAA
      @swfr_w.frame_size = {:xmin=>127, :xmax=>260, :ymin=>15, :ymax=>514}

      @swfr_w.frame_rate = {:whole=>24, :fraction=>0}
      @swfr_w.frame_count = 1

      res = @swfr_w.write_to_string
      # "FWS" - uncompressed signature
      res[0..2].should == "FWS"
      # "09" - version
      res[3].should == 9.chr
      # length of 11+8 as ui32
      res[4..7].should == "13000000".pack_as_hex
      # rect_string - frame_size
      res[8..14].should == @rect_string
      # frame rate
      res[15..16].should == "0018".pack_as_hex
      # frame count
      res[17..18].should == "0100".pack_as_hex

      # compare the whole thing for good measure
      res.should == @swf_string
    end

    it "should write swf header using defaults" do
      res = @swfr_w.write_to_string
      # "FWS" - uncompressed signature
      res[0..2].should == "FWS"
      # "09" - version
      res[3].should == 9.chr
      # length of 13+8 as ui32
      res[4..7].should == "15000000".pack_as_hex
      # rect_string - frame_size
      res[8..16].should == @std_rect_string
      # frame rate
      res[17..18].should == "0018".pack_as_hex
      # frame count
      res[19..20].should == "0100".pack_as_hex

    end

  #end
end

#describe StringSwfIO do
  def convert type, read_val, write_val
    test_read type, read_val, write_val
    test_write type, read_val, write_val
  end

  def test_read type, read_val, write_val
    @buf_c.rewind
    @buf_c.source = write_val
    res = @buf_c.method(("read_"+type).to_sym).call()
    res.should == read_val
  end
  def test_write type, read_val, write_val
    @buf_c.rewind
    @buf_c.method(("write_"+type).to_sym).call(read_val)
    @buf_c.source.should == write_val
  end
#end
  describe "(read/write variable length integers)" do
    before(:each) do
      @buf_c = RedSun::StringSwfIO.new
    end

    #describe "(read/write unsigned integers)" do
      it "should read/write s32 0 and 1" do
        convert "s32", 0, "00000000".pack_as_binary
        convert "s32", 1, "00000001".pack_as_binary
      end

      it "should read/write s32 -1 and -2" do
        convert "s32", -1, "01111111".pack_as_binary
        convert "s32", -2, "01111110".pack_as_binary
      end

      it "should read/write s32 <= 7" do
        convert "s32", 3,   "00000011".pack_as_binary
        convert "s32", -3,  "01111101".pack_as_binary
        convert "s32", 17,  "00010001".pack_as_binary
        convert "s32", -17, "01101111".pack_as_binary
        convert "s32", 63,  "00111111".pack_as_binary
        convert "s32", -64, "01000000".pack_as_binary
      end

      it "should read/write s32 <= 14 bits" do
        convert "s32", 128,       ("10000000"+"00000001").pack_as_binary
        convert "s32", -128,      ("10000000"+"01111111").pack_as_binary
        convert "s32", 0x10c1,    ("11000001"+"00100001").pack_as_binary
        convert "s32", (2**13)-1, ("11111111"+"00111111").pack_as_binary
        convert "s32", -(2**13),  ("10000000"+"01000000").pack_as_binary
      end

      it "should read/write s32 <= 21 bits" do
        convert("s32", 2**14,
          ("10000000"+"10000000"+"00000001").pack_as_binary)
        convert("s32", 2**0+2**7+2**14,
          ("10000001"+"10000001"+"00000001").pack_as_binary)
        convert("s32", 2**20-1,
          ("11111111"+"11111111"+"00111111").pack_as_binary)
        convert("s32", -(2**20),
          ("10000000"+"10000000"+"01000000").pack_as_binary)
      end

      it "should read/write s32 <= 28 bits" do
        convert("s32", 2**21,
          ("10000000"+"10000000"+"10000000"+"00000001").pack_as_binary)
        convert("s32", 2**0+2**7+2**14+2**21,
          ("10000001"+"10000001"+"10000001"+"00000001").pack_as_binary)
        convert("s32", 2**27-1,
          ("11111111"+"11111111"+"11111111"+"00111111").pack_as_binary)
        convert("s32", -(2**27),
          ("10000000"+"10000000"+"10000000"+"01000000").pack_as_binary)
      end

      it "should read/write s32 and u32 <= 32 bits" do
        convert "s32", 2**28,
          ("10000000"+"10000000"+"10000000"+"10000000"+"00000001").pack_as_binary
        convert "s32", 2**0+2**7+2**14+2**21+2**28,
          ("10000001"+"10000001"+"10000001"+"10000001"+"00000001").pack_as_binary
        convert "s32", 2**30-1,
          ("11111111"+"11111111"+"11111111"+"11111111"+"00000011").pack_as_binary
        convert "s32", 2**31-1,
          ("11111111"+"11111111"+"11111111"+"11111111"+"00000111").pack_as_binary
        convert "s32", -(2**31),
          ("10000000"+"10000000"+"10000000"+"10000000"+"01111000").pack_as_binary
      end
    #end

    #describe "(read/write unsigned integers)" do
      it "should read/write u30 0 and 1" do
        convert "u30", 0, "00000000".pack_as_binary
        convert "u30", 1, "00000001".pack_as_binary
      end

      it "should read/write u30 <= 7 bits" do
        convert "u30", 3,   "00000011".pack_as_binary
        convert "u30", 65,  "01000001".pack_as_binary
        convert "u30", 127, "01111111".pack_as_binary
      end

      it "should read/write u30 <= 14 bits" do
        convert "u30", 128,       "1000000000000001".pack_as_binary
        convert "u30", 0x20c1,    "1100000101000001".pack_as_binary
        convert "u30", (2**14)-1, "1111111101111111".pack_as_binary
      end

      it "should read/write u30 <= 21 bits" do
        convert "u30", 2**14,
          "100000001000000000000001".pack_as_binary
        convert "u30", 2**0+2**7+2**14,
          "100000011000000100000001".pack_as_binary
        convert "u30", 2**21-1,
          "111111111111111101111111".pack_as_binary
      end

      it "should read/write u30 <= 28 bits" do
        convert("u30", 2**21,
          "10000000100000001000000000000001".pack_as_binary)
        convert("u30", 2**0+2**7+2**14+2**21,
          "10000001100000011000000100000001".pack_as_binary)
        convert("u30", 2**28-1,
          "11111111111111111111111101111111".pack_as_binary)
      end

      it "should read/write u30 and u32 <= 32 bits" do
        convert "u30", 2**28,
          "1000000010000000100000001000000000000001".pack_as_binary
        convert "u30", 2**0+2**7+2**14+2**21+2**28,
          "1000000110000001100000011000000100000001".pack_as_binary
        convert "u30", 2**30-1,
          "1111111111111111111111111111111100000011".pack_as_binary
        test_write "u30", 2**32-1,
          "1111111111111111111111111111111100000011".pack_as_binary
        test_read "u30", 2**30-1,
          "1111111111111111111111111111111100001111".pack_as_binary
        convert "u32", 2**32-1,
          "1111111111111111111111111111111100001111".pack_as_binary
      end
    #end
  end

  describe "(read/write string data)" do
    before(:each) do
      @buf = RedSun::StringSwfIO.new
    end

    it "should read string" do
      @buf.source = "this is a string\0"
      res = @buf.read_string
      res.should == "this is a string"
    end

    it "should write string" do
      @buf.write_string "this is a string"
      @buf.source.should == "this is a string\0"
    end
  end

  describe "(read/write color data)" do
    before(:each) do
      @buf = RedSun::StringSwfIO.new
    end

    it "should write rgba" do
      @buf.write_rgba 0x01020304
      @buf.source.should == "01020304".pack_as_hex

      @buf.rewind
      @buf.write_rgba 0xF100A180
      @buf.source.should == "F100A180".pack_as_hex

      @buf.rewind
      @buf.write_rgba 0x1F, 0x2F, 0x3F, 0x4F
      @buf.source.should == "1F2F3F4F".pack_as_hex

    end

    it "should read rgba" do
      @buf.source = "01020304".pack_as_hex
      res = @buf.read_rgba
      res.should == 0x01020304

      @buf.rewind
      @buf.source = "F100A180".pack_as_hex
      res = @buf.read_rgba
      res.should == 0xF100A180
    end

    it "should write rgb" do
      @buf.write_rgb 0x010203
      @buf.source.should == "010203".pack_as_hex

      @buf.rewind
      @buf.write_rgb 0xF100A1
      @buf.source.should == "F100A1".pack_as_hex

      @buf.rewind
      @buf.write_rgb 0x00, 0xA1, 0xFF
      @buf.source.should == "00A1FF".pack_as_hex

    end

    it "should read rgb" do
      @buf.source = "010203".pack_as_hex
      res = @buf.read_rgb
      res.should == 0x010203

      @buf.rewind
      @buf.source = "F100A1".pack_as_hex
      res = @buf.read_rgb
      res.should == 0xF100A1
    end

  end

  describe "(write rect)" do
    before(:each) do
      @buf = RedSun::StringSwfIO.new
    end

    it "should write 11 bit rect" do
      rect = {:xmin=>127, :xmax=>260, :ymin=>15, :ymax=>514}
      rect_string =
        ("01011000"+
        "01111111"+
        "00100000"+
        "10000000"+
        "00111101"+
        "00000001"+
        "00000000").pack_as_binary
      @buf.write_rect rect
      @buf.flush
      @buf.source.should == rect_string
      @buf.source.length.should == 7

    end

    it "should write 3 bit rects" do
      rect = {:xmin=>0,:xmax=>2,:ymin=>0,:ymax=>3}
      @buf.write_rect rect
      @buf.flush
      @buf.source[0].should == 0b00011000.chr
      @buf.source[1].should == 0b01000001.chr
      @buf.source[2].should == 0b10000000.chr
      @buf.source.length.should == 3

      @buf.rewind
      rect = {:xmin=>1,:xmax=>2,:ymin=>2,:ymax=>2}
      @buf.write_rect rect
      @buf.flush
      @buf.source[0].should == 0b00011001.chr
      @buf.source[1].should == 0b01001001.chr
      @buf.source[2].should == 0b00000000.chr
      @buf.source.length.should == 3

    end

    it "shortest rect possible - 2 bits" do
      rect = {:xmin=>0,:xmax=>1,:ymin=>0,:ymax=>1}
      @buf.write_rect rect
      @buf.flush
      @buf.source[0].should == 0b00010000.chr
      @buf.source[1].should == 0b10001000.chr
      @buf.source.length.should == 2

      @buf.rewind
      rect = {:xmin=>0,:xmax=>0,:ymin=>0,:ymax=>0}
      @buf.write_rect rect
      @buf.flush
      @buf.source[0].should == 0b00010000.chr
      @buf.source[1].should == 0b00000000.chr
      @buf.source.length.should == 2

    end

    it "shortest rect possible - 2 bits with negative values" do
      rect = {:xmin=>-1,:xmax=>1,:ymin=>-1,:ymax=>1}
      @buf.write_rect rect
      @buf.flush
      @buf.source[0].should == 0b00010110.chr
      @buf.source[1].should == 0b11101000.chr
      @buf.source.length.should == 2

    end

  end

  describe "(read/write mode enforcement)" do
    it "should fail write after read" do
      @buf = RedSun::StringSwfIO.new "53100000".pack_as_hex
      res = @buf.read_ui32
      res.should == 0x1053
      lambda { @buf.write_ui32 0xFF }.should raise_error(StandardError)
    end

    it "should fail read after after" do
      @buf = RedSun::StringSwfIO.new
      @buf.write_ui32 0x1053
      lambda { res = @buf.read_ui32 }.should raise_error(StandardError)
    end

    it "should read after write with rewind" do
      @buf = RedSun::StringSwfIO.new
      @buf.write_ui32 0x1053
      @buf.rewind
      res = @buf.read_ui32
      res.should == 0x1053
    end

    it "should write after read with rewind" do
      @buf = RedSun::StringSwfIO.new "53100000".pack_as_hex
      res = @buf.read_ui32
      res.should == 0x1053
      @buf.rewind
      @buf.write_ui32 0x10FF
    end

    it "should read new value after read-write-read" do
      @buf = RedSun::StringSwfIO.new "53100000".pack_as_hex
      res = @buf.read_ui32
      res.should == 0x1053
      @buf.rewind
      @buf.write_ui32 0x10FF
      @buf.rewind
      res = @buf.read_ui32
      res.should == 0x10FF
    end

  end

  describe "(write bits)" do
    before(:each) do
      @buf = RedSun::StringSwfIO.new
    end

    it "should write one set bit" do
      @buf.write_ubits 1, 1
      @buf.flush
      @buf.source[0].should == 0b10000000.chr
    end

    it "should write one empty bit" do
      @buf.write_ubits 1, 0
      @buf.flush
      @buf.source[0].should == 0.chr
    end

    it "should pack successive writes into same byte" do
      @buf.rewind
      @buf.write_ubits 3, 0b101
      @buf.write_ubits 5, 0b10111
      @buf.flush
      @buf.source[0].should == 0b10110111.chr

      @buf.rewind
      @buf.write_ubits 3, 0b101
      @buf.write_ubits 7, 0b1010111
      @buf.write_ubits 5, 0b10001
      @buf.flush
      @buf.source[0].should == 0b10110101.chr
      @buf.source[1].should == 0b11100010.chr
    end

    it "should write 8 < bits <= 16 bits" do
      @buf.rewind
      @buf.write_ubits 16, 0xF0F0
      @buf.flush
      @buf.source[0].should == 0xF0.chr
      @buf.source[1].should == 0xF0.chr

      @buf.rewind
      @buf.write_ubits 9, 0b111111111
      @buf.flush
      @buf.source[0].should == 0xFF.chr
      @buf.source[1].should == 0b10000000.chr

      @buf.rewind
      @buf.write_ubits 12, 0xFFFF
      @buf.flush
      @buf.source[0].should == 0xFF.chr
      @buf.source[1].should == 0b11110000.chr

      @buf.rewind
      @buf.write_ubits 13, 0b1010101010101
      @buf.flush
      @buf.source[0].should == 0b10101010.chr
      @buf.source[1].should == 0b10101000.chr

    end

    it "should write <= 8 bits" do
      @buf.write_ubits 4, 0b1010
      @buf.flush
      @buf.source[0].should == 0b10100000.chr

      @buf.rewind
      @buf.write_ubits 7, 0b111010
      @buf.flush
      @buf.source[0].should == 0b01110100.chr

      @buf.rewind
      @buf.write_ubits 8, 0b10110001
      @buf.flush
      @buf.source[0].should == 0b10110001.chr

      @buf.rewind
      @buf.write_ubits 8, 0b11111111
      @buf.flush
      @buf.source[0].should == 0b11111111.chr

      @buf.rewind
      @buf.write_ubits 8, 0
      @buf.flush
      @buf.source[0].should == 0.chr
    end
  end

  describe "(fixed write tests)" do
    before(:each) do
      @buf = RedSun::StringSwfIO.new
    end

    it "should write 52.16" do
      @buf.write_fixed8({:whole=>52,:fraction=>16})
      @buf.source[0].should == 16.chr
      @buf.source[1].should == 52.chr
    end

  end

  describe "(fixed read tests)" do
    before(:each) do
      @buf = RedSun::StringSwfIO.new("1034537400ACFF00".pack_as_hex)
    end

    it "should read 52.16" do
      res = @buf.read_fixed8
      res[:whole].should == 52
      res[:fraction].should == 16
    end

    it "should read 0x74.0x53" do
      @buf.read_fixed8
      res = @buf.read_fixed8
      res[:whole].should == 0x74
      res[:fraction].should == 0x53
    end
  end

  describe "(uint write tests)" do
    before(:each) do
      @buf = RedSun::StringSwfIO.new
      #("1034537400ACFF00".pack_as_hex)
    end

    it "should write 0x10345374" do
      @buf.write_ui32 0x74533410
      @buf.source[0..3].should == "10345374".pack_as_hex
    end

    it "should write 0x1034" do
      @buf.write_ui16 0x3410
      @buf.source[0..1].should == "1034".pack_as_hex
    end

    it "should write 0x7453" do
      @buf.write_ui16 0x3410
      @buf.write_ui16 0x7453
      @buf.source[2..3].should == "5374".pack_as_hex
    end

    it "should write 0xAC007453 with write_ubits around it" do
      @buf.write_ubits 11, 0xF
      @buf.write_ui32 0xAC007453
      @buf.source[2..5].should == "537400AC".pack_as_hex
      @buf.write_ubits 3, 0b111
      @buf.write_ui8 0xAC
      @buf.source[7].should == 0xAC.chr
    end

    it "should read 0x5334 with write_ubits around it" do
      @buf.write_ubits 4, 0b1001
      @buf.write_ui16 0x5334
      @buf.source[1..2].should == "3453".pack_as_hex
      @buf.write_ubits 8, 0x74
      @buf.source[3].should == 0x74.chr
    end

    it "should read 0x7453 with write_ubits around it" do
      @buf.write_ubits 9, 0b001001100
      @buf.write_ui16 0x7453
      @buf.source[2..3].should == "5374".pack_as_hex
    end

  end

  describe "(read/write fixed length integers)" do
    before(:each) do
      @buf_c = RedSun::StringSwfIO.new
    end

    it "should convert s24 0,1,-1" do
      convert "s24", 0, "000000".pack_as_hex
      convert "s24", 1, "010000".pack_as_hex
      convert "s24", -1, "FFFFFF".pack_as_hex
    end

    it "should convert s24 " do
      convert "s24", 0x45A430, "30A445".pack_as_hex
      convert "s24", -0x45A430, "d05bba".pack_as_hex
      convert "s24", -0x800000, "000080".pack_as_hex
    end
  end

  describe "(uint read tests)" do
    before(:each) do
      @buf = RedSun::StringSwfIO.new("1034537400ACFF00".pack_as_hex)
    end

    it "should read 0x74533410" do
      res = @buf.read_ui32
      res.should == 0x74533410
    end

    it "should read 0x3410" do
      res = @buf.read_ui16
      res.should == 0x3410
    end

    it "should read 0x7453" do
      @buf.read_ui16
      res = @buf.read_ui16
      res.should == 0x7453
    end

    it "should read 0xAC007453" do
      @bits = @buf.read_bits 11
      @bits.should == 0x81
      res = @buf.read_ui32
      res.should == 0xAC007453
      @bits = @buf.read_bits 16
      @bits.should == 0xFF00
    end

    it "should read 0x5334" do
      @bits = @buf.read_bits 4
      @bits.should == 0x01
      res = @buf.read_ui16
      res.should == 0x5334
      @bits = @buf.read_bits 8
      @bits.should == 0x74
    end

    it "should read 0x7453" do
      @bits = @buf.read_bits 9
      @bits.should == 0x20
      res = @buf.read_ui16
      res.should == 0x7453
    end

  end

  describe "(bit read tests)" do
    before(:each) do
      @buf = RedSun::StringSwfIO.new((
                          #76543210
                          "11010001"+
                          "01111001"+
                          "11010001"+
                          "01111001").pack_as_binary)
    end

    it "should read ui16 after bits" do
      @buf.read_bits 5
      @buf.read_bits 5
      @buf.read_bits 5
      @buf.read_bits 1
      res = @buf.read_ui16
      res.should == 0x79d1
    end

    it "should find 3 ones" do
      @three = @buf.read_bits 3
      @buf.bit_pos.should == 3
      @three.should == 0b110
    end

    it "should find 5 ones" do
      @five = @buf.read_bits 5
      @buf.bit_pos.should == 5
      @five.should == 0b11010
    end

    it "should find 8 ones" do
      @eight = @buf.read_bits 8
      @buf.bit_pos.should == 0
      @eight.should == 0b11010001
    end

    it "should find 3 ones after reading 5" do
      @buf.read_bits 5
      @buf.bit_pos.should == 5
      @three = @buf.read_bits 3
      @buf.bit_pos.should == 0
      @three.should == 0b001
    end

    it "should fine 0b101 at border" do
      @buf.read_bits 7
      @three = @buf.read_bits 3
      @three.should == 0b101
    end

    it "should fine 0b001 at end" do
      @buf.read_bits 7
      @buf.read_bits 3
      @buf.read_bits 3
      @three = @buf.read_bits 3
      @three.should == 0b001
    end

  end

  describe "(read rect)" do
    before(:each) do
      @rect = RedSun::StringSwfIO.new((
                          "01011000"+
                          "01111111"+
                          "00100000"+
                          "10000000"+
                          "00111101"+
                          "00000001"+
                          "00000000").pack_as_binary)
    end

    it "should read 11, (127, 260, 15, 514) from rec" do
      @bits = @rect.read_bits 5
      @bits.should == 11
      @xmin = @rect.read_bits @bits
      @xmin.should == 127
      @xmax = @rect.read_bits @bits
      @xmax.should == 260
      @ymin = @rect.read_bits @bits
      @ymin.should == 15
      @ymax = @rect.read_bits @bits
      @ymax.should == 514

      @rect.bit_pos.should == 1
    end

    it "should create rect (127, 260, 15, 514)" do
      @r = @rect.read_rect
      @r[:xmin].should == 127
      @r[:xmax].should == 260
      @r[:ymin].should == 15
      @r[:ymax].should == 514
    end
  end

#end

describe "stub swf generation" do
  before(:each) do
    @swf = RedSun::Swf.new
    @swf.create_stub_swf("EmptySwf")
  end
  it "should have default swf settings" do
    @swf.compressed.should == true
    @swf.version.should == 9
    @swf.frame_size[:xmin].should == 0
    @swf.frame_size[:ymin].should == 0
    @swf.frame_size[:xmax].should == 10000
    @swf.frame_size[:ymax].should == 7500
    @swf.frame_rate[:whole].should == 24
    @swf.frame_rate[:fraction].should == 0
    @swf.frame_count.should == 1
  end
  it "should have FileAttributes tag" do
    t = @swf.tag_select(RedSun::Tags::FileAttributes)[0]
    t.class.should == RedSun::Tags::FileAttributes
    t.actionscript3.should == true
    t.use_network.should == true
    t.has_metadata.should == false
    t.reserved1.should == 0
    t.reserved2.should == 0
    t.reserved3.should == 0
  end
  it "should have ScriptLimits tag" do
    t = @swf.tag_select(RedSun::Tags::ScriptLimits)[0]
    t.class.should == RedSun::Tags::ScriptLimits
    t.max_recursion_depth.should == 1000
    t.script_timeout_secs.should == 60
  end
  it "should have SetBackgroundColor tag" do
    t = @swf.tag_select(RedSun::Tags::SetBackgroundColor)[0]
    t.class.should == RedSun::Tags::SetBackgroundColor
    t.background_color.should == 0x869ca7
  end
  it "should have FrameLabel tag" do
    t = @swf.tag_select(RedSun::Tags::FrameLabel)[0]
    t.class.should == RedSun::Tags::FrameLabel
    t.name.should == "EmptySwf"
  end
  it "should have DoABC tag" do
    t = @swf.tag_select(RedSun::Tags::DoABC)[0]
    t.class.should == RedSun::Tags::DoABC
    t.flags.should == 1
    t.name.should == "frame1"
    t.abc_file.minor_version.should == 16
    t.abc_file.major_version.should == 46
  end
  it "should have ints, uints, doubles setup" do
    t = @swf.tag_select(RedSun::Tags::DoABC)[0]
    t.abc_file.ints.length.should == 1
    t.abc_file.ints[0].should == nil

    t.abc_file.uints.length.should == 1
    t.abc_file.uints[0].should == nil
    t.abc_file.doubles.length.should == 1
    t.abc_file.doubles[0].should == nil
  end
  it "should have strings setup" do
    t = @swf.tag_select(RedSun::Tags::DoABC)[0]
    strings = t.abc_file.strings
    strings[0].should == nil
    strings.include?("".to_sym).should == true
    strings.include?("EmptySwf/EmptySwf".to_sym).should == true
    strings.include?("EmptySwf".to_sym).should == true
    strings.include?("flash.display".to_sym).should == true
    strings.include?("Sprite".to_sym).should == true
    #strings.include?("/path/to/src;;EmptySwf.as".to_sym).should == true
    strings.include?("Object".to_sym).should == true
    strings.include?("flash.events".to_sym).should == true
    strings.include?("EventDispatcher".to_sym).should == true
    strings.include?("DisplayObject".to_sym).should == true
    strings.include?("InteractiveObject".to_sym).should == true
    strings.include?("DisplayObjectContainer".to_sym).should == true

    # Allow extra strings, it doesn't hurt anything
    #strings.length.should == 12
  end
  it "should have namespaces and ns_sets setup" do
    t = @swf.tag_select(RedSun::Tags::DoABC)[0]
    namespaces = t.abc_file.namespaces
    namespaces[0].should == nil

    cp = t.abc_file.constant_pool

    namespaces.include?(RedSun::ABC::Namespace.new(RedSun::ABC::Namespace::PackageNamespace, cp.find_string("".to_sym))).should == true
    namespaces.include?(RedSun::ABC::Namespace.new(RedSun::ABC::Namespace::PackageNamespace, cp.find_string("flash.display".to_sym))).should == true
    namespaces.include?(RedSun::ABC::Namespace.new(RedSun::ABC::Namespace::PackageNamespace, cp.find_string("flash.events".to_sym))).should == true
    namespaces.include?(RedSun::ABC::Namespace.new(RedSun::ABC::Namespace::ProtectedNamespace, cp.find_string("EmptySwf".to_sym))).should == true

    # There are more namespace, but we're stopping here for now
    #namespaces.include?(RedSun::ABC::Namespace.new(RedSun::ABC::Namespace::PrivateNs, cp.find_string("EmptySwf".to_sym))).should == true

    #namespaces.length.should == 6

    ns_sets = t.abc_file.ns_sets
    #ns_sets.length.should == 2
    ns_sets[0].should == nil
  end
  it "should have multinames setup" do
    t = @swf.tag_select(RedSun::Tags::DoABC)[0]
    multinames = t.abc_file.multinames
    multinames.length.should == 8
    multinames[0].class.should == RedSun::ABC::Multiname

    cp = t.abc_file.constant_pool
    top_ns = cp.find_namespace(RedSun::ABC::Namespace.new(RedSun::ABC::Namespace::PackageNamespace, cp.find_string("".to_sym)))
    display = cp.find_namespace(RedSun::ABC::Namespace.new(RedSun::ABC::Namespace::PackageNamespace, cp.find_string("flash.display".to_sym)))
    events = cp.find_namespace(RedSun::ABC::Namespace.new(RedSun::ABC::Namespace::PackageNamespace, cp.find_string("flash.events".to_sym)))

    multinames.include?(RedSun::ABC::Multiname.new(RedSun::ABC::Multiname::MultinameQName, cp.find_string("EmptySwf".to_sym), top_ns)).should == true
    multinames.include?(RedSun::ABC::Multiname.new(RedSun::ABC::Multiname::MultinameQName, cp.find_string("Object".to_sym), top_ns)).should == true
    multinames.include?(RedSun::ABC::Multiname.new(RedSun::ABC::Multiname::MultinameQName, cp.find_string("EventDispatcher".to_sym), events)).should == true
    multinames.include?(RedSun::ABC::Multiname.new(RedSun::ABC::Multiname::MultinameQName, cp.find_string("DisplayObject".to_sym), display)).should == true
    multinames.include?(RedSun::ABC::Multiname.new(RedSun::ABC::Multiname::MultinameQName, cp.find_string("InteractiveObject".to_sym), display)).should == true
    multinames.include?(RedSun::ABC::Multiname.new(RedSun::ABC::Multiname::MultinameQName, cp.find_string("DisplayObjectContainer".to_sym), display)).should == true
    multinames.include?(RedSun::ABC::Multiname.new(RedSun::ABC::Multiname::MultinameQName, cp.find_string("Sprite".to_sym), display)).should == true

  end

  it "should have SymbolClass tag" do
    t = @swf.tag_select(RedSun::Tags::SymbolClass)[0]
    t.class.should == RedSun::Tags::SymbolClass
    t.symbols.length.should == 1
    t.symbols[0][:tag].should == 0
    t.symbols[0][:name].should == "EmptySwf"
  end
  it "should have ShowFrame tag" do
    t = @swf.tag_select(RedSun::Tags::ShowFrame)[0]
    t.class.should == RedSun::Tags::ShowFrame
  end
  it "should have End tag" do
    t = @swf.tag_select(RedSun::Tags::End)[0]
    t.class.should == RedSun::Tags::End
  end
end

describe "namespace, sets, multiname equality" do
  it "namespaces should be equal" do
    ns = RedSun::ABC::Namespace.new(RedSun::ABC::Namespace::PackageNamespace, 1)
    ns2 = RedSun::ABC::Namespace.new(RedSun::ABC::Namespace::PackageNamespace, 1)
    ns3 = RedSun::ABC::Namespace.new(RedSun::ABC::Namespace::ProtectedNamespace, 1)
    ns4 = RedSun::ABC::Namespace.new(RedSun::ABC::Namespace::ProtectedNamespace, 1)
    ns.should == ns
    ns.should == ns2
    ns2.should == ns
    (ns == ns).should == true
    (ns != ns).should == false
    (ns == ns2).should == true
    (ns != ns2).should == false
    (ns2 == ns).should == true
    (ns2 != ns).should == false
    ns3.should == ns4
    (ns3 == ns4).should == true
    (ns3 != ns4).should == false
  end
  it "namespaces should not be equal" do
    ns = RedSun::ABC::Namespace.new(RedSun::ABC::Namespace::PackageNamespace, 1)
    ns2 = RedSun::ABC::Namespace.new(RedSun::ABC::Namespace::PackageNamespace, 2)
    ns3 = RedSun::ABC::Namespace.new(RedSun::ABC::Namespace::ProtectedNamespace, 2)
    ns4 = RedSun::ABC::Namespace.new(RedSun::ABC::Namespace::StaticProtectedNs, 1)
    (ns == ns2).should == false
    (ns != ns2).should == true
    (ns == ns3).should == false
    (ns != ns3).should == true
    (ns == ns4).should == false
    (ns != ns4).should == true
    (ns2 == ns3).should == false
    (ns2 != ns3).should == true
    (ns2 == ns4).should == false
    (ns2 != ns4).should == true
    (ns3 == ns4).should == false
    (ns3 != ns4).should == true
  end
  it "namespace sets should be equal" do
    ns = RedSun::ABC::NsSet.new([0,1,2])
    ns2 = RedSun::ABC::NsSet.new([0,1,2])
    ns3 = RedSun::ABC::NsSet.new([2,1,3])
    ns4 = RedSun::ABC::NsSet.new([2,1,3])
    ns.should == ns
    ns.should == ns2
    ns2.should == ns
    (ns == ns).should == true
    (ns != ns).should == false
    (ns == ns2).should == true
    (ns != ns2).should == false
    (ns2 == ns).should == true
    (ns2 != ns).should == false
    ns3.should == ns4
    (ns3 == ns4).should == true
    (ns3 != ns4).should == false
  end
  it "namespace sets should not be equal" do
    ns = RedSun::ABC::NsSet.new([0,1,2])
    ns2 = RedSun::ABC::NsSet.new([2,1,0])
    ns3 = RedSun::ABC::NsSet.new([0,1,3])
    ns4 = RedSun::ABC::NsSet.new([0])
    (ns == ns2).should == false
    (ns != ns2).should == true
    (ns == ns3).should == false
    (ns != ns3).should == true
    (ns == ns4).should == false
    (ns != ns4).should == true
    (ns2 == ns3).should == false
    (ns2 != ns3).should == true
    (ns2 == ns4).should == false
    (ns2 != ns4).should == true
    (ns3 == ns4).should == false
    (ns3 != ns4).should == true
  end
  it "multinames should be equal" do
    ns = RedSun::ABC::Multiname.new(RedSun::ABC::Multiname::MultinameQName, 1, 4)
    ns2 = RedSun::ABC::Multiname.new(RedSun::ABC::Multiname::MultinameQName, 1, 4)
    ns3 = RedSun::ABC::Multiname.new(RedSun::ABC::Multiname::MultinameC, 2, nil, 3)
    ns4 = RedSun::ABC::Multiname.new(RedSun::ABC::Multiname::MultinameC, 2, nil, 3)
    ns.should == ns
    ns.should == ns2
    ns2.should == ns
    (ns == ns).should == true
    (ns != ns).should == false
    (ns == ns2).should == true
    (ns != ns2).should == false
    (ns2 == ns).should == true
    (ns2 != ns).should == false
    ns3.should == ns4
    (ns3 == ns4).should == true
    (ns3 != ns4).should == false
  end
  it "multinames should not be equal" do
    ns = RedSun::ABC::Multiname.new(RedSun::ABC::Multiname::MultinameQName, 1, 4)
    ns2 = RedSun::ABC::Multiname.new(RedSun::ABC::Multiname::MultinameQNameA, 1, 4)
    ns3 = RedSun::ABC::Multiname.new(RedSun::ABC::Multiname::MultinameRTQNameL)
    ns4 = RedSun::ABC::Multiname.new(RedSun::ABC::Multiname::MultinameL, nil, nil, 4)
    (ns == ns2).should == false
    (ns != ns2).should == true
    (ns == ns3).should == false
    (ns != ns3).should == true
    (ns == ns4).should == false
    (ns != ns4).should == true
    (ns2 == ns3).should == false
    (ns2 != ns3).should == true
    (ns2 == ns4).should == false
    (ns2 != ns4).should == true
    (ns3 == ns4).should == false
    (ns3 != ns4).should == true
  end
end

describe "abc file basic creation" do
  before(:each) do
    @af = RedSun::ABC::ABCFile.new
    @empty_swf_ruby = <<HERE
class EmptySwf < Flash::Display::Sprite
  def initialize
    super
  end
end
HERE
    @vm = RubyVM::InstructionSequence.compile(@empty_swf_ruby)
    @af.load_ruby(@vm.to_a)
  end
  it "should have one class definition" do
    @af.classes.length.should == 1
    @af.instances.length.should == 1
  end
  it "should have class named EmptySwf" do
    inst = @af.instances[0]

    inst.name_index.nil?.should == false
    inst.name.nil?.should == false
    inst.name.kind.should == RedSun::ABC::Multiname::MultinameQName
    inst.name.name.nil?.should == false
    inst.name.name.should == :EmptySwf
    inst.name.name_index.should == @af.constant_pool.find_string(:EmptySwf)
    inst.name.ns.nil?.should == false
    inst.name.ns.kind.should == RedSun::ABC::Namespace::PackageNamespace
    inst.name.ns.name.nil?.should == false
    inst.name.ns.name.should == "".to_sym
    inst.name.ns.name_index.should == @af.constant_pool.find_string("".to_sym)

  end
  it "should have super class flash.display.Sprite" do
    inst = @af.instances[0]

    inst.super_name_index.nil?.should == false
    inst.super_name.nil?.should == false
    inst.super_name.kind.should == RedSun::ABC::Multiname::MultinameQName
    inst.super_name.name.nil?.should == false
    inst.super_name.name.should == :Sprite
    inst.super_name.name_index.should == @af.constant_pool.find_string(:Sprite)
    inst.super_name.ns.nil?.should == false
    inst.super_name.ns.kind.should == RedSun::ABC::Namespace::PackageNamespace
    inst.super_name.ns.name.nil?.should == false
    inst.super_name.ns.name.should == "flash.display".to_sym
    inst.super_name.ns.name_index.should == @af.constant_pool.find_string("flash.display".to_sym)

  end
  it "should have iinit settings properly" do
    inst = @af.instances[0]

    inst.iinit_index.nil?.should == false
    inst.iinit.nil?.should == false
    inst.iinit.param_types.length.should == 0
    inst.iinit.options.length.should == 0
    inst.iinit.param_names.length.should == 0
    inst.iinit.param_types.length.should == 0
    inst.iinit.return_type_index.should == 0
    inst.iinit.name.should == "EmptySwf/EmptySwf".to_sym
    inst.iinit.name_index.should == @af.constant_pool.find_string("EmptySwf/EmptySwf".to_sym)
    inst.iinit.need_arguments.should == false
    inst.iinit.need_activation.should == false
    inst.iinit.need_rest.should == false
    inst.iinit.has_optional.should == false
    inst.iinit.set_dxns.should == false
    inst.iinit.has_param_names.should == false

  end
  it "should have created iinit method body" do
    inst = @af.instances[0]

    inst.iinit.body.nil?.should == false
    inst.iinit.body.method_index.should == inst.iinit_index
    inst.iinit.body.max_stack.should == 2
    inst.iinit.body.local_count.should == 1
    inst.iinit.body.init_scope_depth.should == 0
    inst.iinit.body.max_scope_depth.should == 1

    inst.iinit.body.code.codes[0].opcode.should == RedSun::ABC::GetLocal0::Opcode
    inst.iinit.body.code.codes[1].opcode.should == RedSun::ABC::PushScope::Opcode
    inst.iinit.body.code.codes[2].opcode.should == RedSun::ABC::PushFalse::Opcode
    inst.iinit.body.code.codes[3].opcode.should == RedSun::ABC::GetLocal0::Opcode
    inst.iinit.body.code.codes[4].opcode.should == RedSun::ABC::ConstructSuper::Opcode
    inst.iinit.body.code.codes[4].arg_count.should == 0
    inst.iinit.body.code.codes[5].opcode.should == RedSun::ABC::ReturnVoid::Opcode
    inst.iinit.body.code.codes.length.should == 6
  end
  it "should setup basic instance settings" do
    inst = @af.instances[0]

    inst.flags.should == RedSun::ABC::Instance::ProtectedNamespace

    inst.protected_namespace_index.nil?.should == false
    inst.protected_namespace.nil?.should == false
    inst.protected_namespace.kind.should == RedSun::ABC::Namespace::ProtectedNamespace
    inst.protected_namespace.name.should == :EmptySwf

    inst.interface_indices.length.should == 0
    inst.traits.length.should == 0

  end
  it "should setup basic class settings" do
    cls = @af.classes[0]

    cls.traits.length.should == 0

  end

  it "should have cinit settings properly" do
    cls = @af.classes[0]

    cls.cinit_index.nil?.should == false
    cls.cinit.nil?.should == false
    cls.cinit.param_types.length.should == 0
    cls.cinit.options.length.should == 0
    cls.cinit.param_names.length.should == 0
    cls.cinit.param_types.length.should == 0
    cls.cinit.return_type_index.should == 0
    cls.cinit.name.should == "".to_sym
    cls.cinit.name_index.should == @af.constant_pool.find_string("".to_sym)
    cls.cinit.need_arguments.should == false
    cls.cinit.need_activation.should == false
    cls.cinit.need_rest.should == false
    cls.cinit.has_optional.should == false
    cls.cinit.set_dxns.should == false
    cls.cinit.has_param_names.should == false

  end
  it "should have created cinit method body" do
    cls = @af.classes[0]

    cls.cinit.body.nil?.should == false
    cls.cinit.body.method_index.should == cls.cinit_index
    cls.cinit.body.max_stack.should == 1
    cls.cinit.body.local_count.should == 1
    cls.cinit.body.init_scope_depth.should == 0
    cls.cinit.body.max_scope_depth.should == 1

    cls.cinit.body.code.codes.length.should == 3
    cls.cinit.body.code.codes[0].opcode.should == RedSun::ABC::GetLocal0::Opcode
    cls.cinit.body.code.codes[1].opcode.should == RedSun::ABC::PushScope::Opcode
    cls.cinit.body.code.codes[2].opcode.should == RedSun::ABC::ReturnVoid::Opcode
  end
  it "should have initialized a doc class script" do
    scr = @af.scripts[0]

    scr.nil?.should == false
    scr.traits.length.should == 1
    trait = scr.traits[0]

    trait.nil?.should == false
    trait.has_metadata.should == false
    trait.final.should == false
    trait.override.should == false
    trait.type.should == RedSun::ABC::Trait::ClassId

    # Trait name same as class name
    trait.name_index.nil?.should == false
    trait.name.nil?.should == false
    trait.name.kind.should == RedSun::ABC::Multiname::MultinameQName
    trait.name.name.nil?.should == false
    trait.name.name.should == :EmptySwf
    trait.name.name_index.should == @af.constant_pool.find_string(:EmptySwf)
    trait.name.ns.nil?.should == false
    trait.name.ns.kind.should == RedSun::ABC::Namespace::PackageNamespace
    trait.name.ns.name.nil?.should == false
    trait.name.ns.name.should == "".to_sym
    trait.name.ns.name_index.should == @af.constant_pool.find_string("".to_sym)

    trait.data.nil?.should == false
    trait.data.class.should == RedSun::ABC::TraitClass
    trait.data.slot_id.should == 1
    trait.data.class_index.should == 0

  end
  it "should have initialized a doc class script method" do
    scr = @af.scripts[0]

    scr.init_index.nil?.should == false
    scr.init.nil?.should == false
    scr.init.param_types.length.should == 0
    scr.init.options.length.should == 0
    scr.init.param_names.length.should == 0
    scr.init.param_types.length.should == 0
    scr.init.return_type_index.should == 0
    scr.init.name.should == "".to_sym
    scr.init.name_index.should == @af.constant_pool.find_string("".to_sym)
    scr.init.need_arguments.should == false
    scr.init.need_activation.should == false
    scr.init.need_rest.should == false
    scr.init.has_optional.should == false
    scr.init.set_dxns.should == false
    scr.init.has_param_names.should == false
  end
  it "should have created doc class script body" do
    scr = @af.scripts[0]

    scr.init.body.nil?.should == false
    scr.init.body.method_index.should == 2
    scr.init.body.max_stack.should == 2
    scr.init.body.local_count.should == 1
    scr.init.body.init_scope_depth.should == 1
    scr.init.body.max_scope_depth.should == 8

    codes = scr.init.body.code.codes

    codes[0].opcode.should == RedSun::ABC::GetLocal0::Opcode
    codes[1].opcode.should == RedSun::ABC::PushScope::Opcode
    codes[2].opcode.should == RedSun::ABC::GetScopeObject::Opcode
    codes[2].index.should == 0

    3.step(13,2) do |i|
      codes[i].opcode.should == RedSun::ABC::GetLex::Opcode
      codes[i+1].opcode.should == RedSun::ABC::PushScope::Opcode
    end

    codes[3].property.name.should == :Object
    codes[3].property.ns.name.should == "".to_sym

    codes[5].property.name.should == :EventDispatcher
    codes[5].property.ns.name.should == "flash.events".to_sym

    fd = "flash.display".to_sym
    codes[7].property.name.should == :DisplayObject
    codes[7].property.ns.name.should == fd
    codes[9].property.name.should == :InteractiveObject
    codes[9].property.ns.name.should == fd
    codes[11].property.name.should == :DisplayObjectContainer
    codes[11].property.ns.name.should == fd
    codes[13].property.name.should == :Sprite
    codes[13].property.ns.name.should == fd

    codes[15].opcode.should == RedSun::ABC::GetLex::Opcode
    codes[15].property.name.should == :Sprite
    codes[15].property.ns.name.should == fd
    codes[16].opcode.should == RedSun::ABC::NewClass::Opcode
    codes[16].index.should == 0

    17.upto(22) do |i|
      codes[i].opcode.should == RedSun::ABC::PopScope::Opcode
    end

    codes[23].opcode.should == RedSun::ABC::InitProperty::Opcode
    codes[24].opcode.should == RedSun::ABC::ReturnVoid::Opcode
    codes.length.should == 25
  end
end


def verify_trait_ns_set(namespaces, additional=[])
  # Verify namespace set in order:
  # PrivateNs "Traits"
  # PrivateNs "Traits.as$23"
  # PackageNamespace ""
  # PackageInternalNs ""
  # ProtectedNamespace "Traits"
  # StaticProtectedNs "Traits"
  # StaticProtectedNs "flash.display:Sprite"
  # StaticProtectedNs "flash.display:DisplayObjectContainer"
  # StaticProtectedNs "flash.display:InteractiveObject"
  # StaticProtectedNs "flash.display:DisplayObject"
  # StaticProtectedNs "flash.events:EventDispatcher"
  # StaticProtectedNs "Object"
  namespaces[0].kind.should == RedSun::ABC::Namespace::PrivateNs
  namespaces[0].name.should == "Traits".to_sym
  namespaces[1].kind.should == RedSun::ABC::Namespace::PrivateNs
  namespaces[1].name.should == "file.as".to_sym
  namespaces[2].kind.should == RedSun::ABC::Namespace::PackageNamespace
  namespaces[2].name.should == "".to_sym
  namespaces[3].kind.should == RedSun::ABC::Namespace::PackageInternalNs
  namespaces[3].name.should == "".to_sym
  namespaces[4].kind.should == RedSun::ABC::Namespace::ProtectedNamespace
  namespaces[4].name.should == "Traits".to_sym
  namespaces[5].kind.should == RedSun::ABC::Namespace::StaticProtectedNs
  namespaces[5].name.should == "Traits".to_sym
  namespaces[6].kind.should == RedSun::ABC::Namespace::StaticProtectedNs
  namespaces[6].name.should == "flash.display:Sprite".to_sym
  namespaces[7].kind.should == RedSun::ABC::Namespace::StaticProtectedNs
  namespaces[7].name.should == "flash.display:DisplayObjectContainer".to_sym
  namespaces[8].kind.should == RedSun::ABC::Namespace::StaticProtectedNs
  namespaces[8].name.should == "flash.display:InteractiveObject".to_sym
  namespaces[9].kind.should == RedSun::ABC::Namespace::StaticProtectedNs
  namespaces[9].name.should == "flash.display:DisplayObject".to_sym
  namespaces[10].kind.should == RedSun::ABC::Namespace::StaticProtectedNs
  namespaces[10].name.should == "flash.events:EventDispatcher".to_sym
  namespaces[11].kind.should == RedSun::ABC::Namespace::StaticProtectedNs
  namespaces[11].name.should == "Object".to_sym
  num = 12
  additional.each do |o|
    namespaces[num].should == o
    num += 1
  end
  namespaces.length.should == 12+additional.length
end


describe "typed method compiler" do
  before(:each) do
    @af = RedSun::ABC::ABCFile.new
    @empty_swf_ruby = <<HERE
class Traits < Flash::Display::Sprite
  def initialize
    super
    hasEventListener("bar")
  end
end
HERE
    @vm = RubyVM::InstructionSequence.compile(@empty_swf_ruby)
    @af.load_ruby(@vm.to_a)
  end

  it "should compile method call" do
    inst = @af.instances[0]

    inst.iinit.body.nil?.should == false
    inst.iinit.body.method_index.should == inst.iinit_index
    inst.iinit.body.max_stack.should == 3
    inst.iinit.body.local_count.should == 1
    inst.iinit.body.init_scope_depth.should == 0
    inst.iinit.body.max_scope_depth.should == 1

    codes = inst.iinit.body.code.codes

    codes[0].opcode.should == RedSun::ABC::GetLocal0::Opcode
    codes[1].opcode.should == RedSun::ABC::PushScope::Opcode
    codes[2].opcode.should == RedSun::ABC::PushFalse::Opcode
    codes[3].opcode.should == RedSun::ABC::GetLocal0::Opcode
    codes[4].opcode.should == RedSun::ABC::ConstructSuper::Opcode
    codes[4].arg_count.should == 0
    codes[5].opcode.should == RedSun::ABC::Pop::Opcode

    codes[6].opcode.should == RedSun::ABC::FindPropStrict::Opcode
    codes[6].property.kind.should == RedSun::ABC::Multiname::MultinameC
    codes[6].property.ns_index.should == nil
    codes[6].property.name.should == :hasEventListener
    verify_trait_ns_set(codes[6].property.ns_set.ns)

    codes[7].opcode.should == RedSun::ABC::PushString::Opcode
    codes[7].string.should == :bar

    codes[8].opcode.should == RedSun::ABC::CallProperty::Opcode
    codes[8].arg_count.should == 1
    codes[8].property.kind.should == RedSun::ABC::Multiname::MultinameC
    codes[8].property.ns_index.should == nil
    codes[8].property.name.should == :hasEventListener
    verify_trait_ns_set(codes[8].property.ns_set.ns)

    codes[9].opcode.should == RedSun::ABC::CoerceA::Opcode

    codes[10].opcode.should == RedSun::ABC::ReturnVoid::Opcode

    inst.iinit.body.code.codes.length.should == 11
  end

end

describe "typed property compiler" do
  before(:each) do
    @af = RedSun::ABC::ABCFile.new
    @empty_swf_ruby = <<HERE
class Traits < Flash::Display::Sprite
  def initialize
    super
    get.graphics.lineStyle(1,1,1)
    get.graphics.beginFill(0xFF00FF,1)
    get.graphics.drawRect(5,5,100,100)
  end
end
HERE
    @vm = RubyVM::InstructionSequence.compile(@empty_swf_ruby)
    @af.load_ruby(@vm.to_a)
  end

  it "should compile property get and method call" do
    inst = @af.instances[0]

    inst.iinit.body.nil?.should == false
    inst.iinit.body.method_index.should == inst.iinit_index
    inst.iinit.body.max_stack.should == 6
    inst.iinit.body.local_count.should == 1
    inst.iinit.body.init_scope_depth.should == 0
    inst.iinit.body.max_scope_depth.should == 1

    codes = inst.iinit.body.code.codes

    codes[0].opcode.should == RedSun::ABC::GetLocal0::Opcode
    codes[1].opcode.should == RedSun::ABC::PushScope::Opcode
    codes[2].opcode.should == RedSun::ABC::PushFalse::Opcode
    codes[3].opcode.should == RedSun::ABC::GetLocal0::Opcode
    codes[4].opcode.should == RedSun::ABC::ConstructSuper::Opcode
    codes[4].arg_count.should == 0
    codes[5].opcode.should == RedSun::ABC::Pop::Opcode

    codes[6].opcode.should == RedSun::ABC::GetLex::Opcode
    codes[6].property.kind.should == RedSun::ABC::Multiname::MultinameC
    codes[6].property.ns_index.should == nil
    codes[6].property.name.should == :graphics
    verify_trait_ns_set(codes[6].property.ns_set.ns)

    codes[7].opcode.should == RedSun::ABC::PushByte::Opcode
    codes[7].value.should == 1
    codes[8].opcode.should == RedSun::ABC::PushByte::Opcode
    codes[8].value.should == 1
    codes[9].opcode.should == RedSun::ABC::PushByte::Opcode
    codes[9].value.should == 1

    codes[10].opcode.should == RedSun::ABC::CallProperty::Opcode
    codes[10].arg_count.should == 3
    codes[10].property.kind.should == RedSun::ABC::Multiname::MultinameC
    codes[10].property.ns_index.should == nil
    codes[10].property.name.should == :lineStyle
    verify_trait_ns_set(codes[10].property.ns_set.ns)
    codes[11].opcode.should == RedSun::ABC::CoerceA::Opcode
    codes[12].opcode.should == RedSun::ABC::Pop::Opcode

    codes[13].opcode.should == RedSun::ABC::GetLex::Opcode
    codes[13].property.kind.should == RedSun::ABC::Multiname::MultinameC
    codes[13].property.ns_index.should == nil
    codes[13].property.name.should == :graphics
    verify_trait_ns_set(codes[13].property.ns_set.ns)

    codes[14].opcode.should == RedSun::ABC::PushInt::Opcode
    codes[14].value.should == 0xFF00FF
    codes[15].opcode.should == RedSun::ABC::PushByte::Opcode
    codes[15].value.should == 1

    codes[16].opcode.should == RedSun::ABC::CallProperty::Opcode
    codes[16].arg_count.should == 2
    codes[16].property.kind.should == RedSun::ABC::Multiname::MultinameC
    codes[16].property.ns_index.should == nil
    codes[16].property.name.should == :beginFill
    verify_trait_ns_set(codes[16].property.ns_set.ns)
    codes[17].opcode.should == RedSun::ABC::CoerceA::Opcode
    codes[18].opcode.should == RedSun::ABC::Pop::Opcode

    codes[19].opcode.should == RedSun::ABC::GetLex::Opcode
    codes[19].property.kind.should == RedSun::ABC::Multiname::MultinameC
    codes[19].property.ns_index.should == nil
    codes[19].property.name.should == :graphics
    verify_trait_ns_set(codes[19].property.ns_set.ns)

    codes[20].opcode.should == RedSun::ABC::PushByte::Opcode
    codes[20].value.should == 5
    codes[21].opcode.should == RedSun::ABC::PushByte::Opcode
    codes[21].value.should == 5
    codes[22].opcode.should == RedSun::ABC::PushByte::Opcode
    codes[22].value.should == 100
    codes[23].opcode.should == RedSun::ABC::PushByte::Opcode
    codes[23].value.should == 100

    codes[24].opcode.should == RedSun::ABC::CallProperty::Opcode
    codes[24].arg_count.should == 4
    codes[24].property.kind.should == RedSun::ABC::Multiname::MultinameC
    codes[24].property.ns_index.should == nil
    codes[24].property.name.should == :drawRect
    verify_trait_ns_set(codes[24].property.ns_set.ns)
    codes[25].opcode.should == RedSun::ABC::CoerceA::Opcode
    #codes[26].opcode.should == RedSun::ABC::Pop::Opcode

    codes[26].opcode.should == RedSun::ABC::ReturnVoid::Opcode

    codes.length.should == 27
  end

end

describe "compiler" do
  before(:each) do
    @af = RedSun::ABC::ABCFile.new
    @empty_swf_ruby = <<HERE
class Traits < Flash::Display::Sprite
  def initialize
    super
    sp = Flash::Display::Sprite.new
    sp.get.graphics.lineStyle(1,1,1)
    sp.get.graphics.beginFill(0x005500,1)
    sp.get.graphics.drawCircle(50,50,45)
    sp.get.graphics.endFill()
    addChild(sp)
  end
end
HERE
    @vm = RubyVM::InstructionSequence.compile(@empty_swf_ruby)
    @af.load_ruby(@vm.to_a)
  end

  it "should compile object creation" do
    inst = @af.instances[0]

    inst.iinit.body.nil?.should == false
    inst.iinit.body.method_index.should == inst.iinit_index
    inst.iinit.body.max_stack.should == 4
    inst.iinit.body.local_count.should == 2
    inst.iinit.body.init_scope_depth.should == 0
    inst.iinit.body.max_scope_depth.should == 1

    codes = inst.iinit.body.code.codes

    codes[0].opcode.should == RedSun::ABC::GetLocal0::Opcode
    codes[1].opcode.should == RedSun::ABC::PushScope::Opcode
    codes[2].opcode.should == RedSun::ABC::PushFalse::Opcode
    codes[3].opcode.should == RedSun::ABC::GetLocal0::Opcode
    codes[4].opcode.should == RedSun::ABC::ConstructSuper::Opcode
    codes[4].arg_count.should == 0
    codes[5].opcode.should == RedSun::ABC::Pop::Opcode

    codes[6].opcode.should == RedSun::ABC::FindPropStrict::Opcode
    codes[6].property.kind.should == RedSun::ABC::Multiname::MultinameC
    codes[6].property.ns_index.should == nil
    codes[6].property.name.should == :Sprite
    verify_trait_ns_set(codes[6].property.ns_set.ns,
          [RedSun::ABC::Namespace.new(RedSun::ABC::Namespace::PackageNamespace,
              @af.constant_pool.find_string("flash.display".to_sym))
          ])

    codes[7].opcode.should == RedSun::ABC::ConstructProp::Opcode
    codes[7].arg_count.should == 0
    codes[7].property.kind.should == RedSun::ABC::Multiname::MultinameC
    codes[7].property.ns_index.should == nil
    codes[7].property.name.should == :Sprite
    verify_trait_ns_set(codes[7].property.ns_set.ns,
          [RedSun::ABC::Namespace.new(RedSun::ABC::Namespace::PackageNamespace,
              @af.constant_pool.find_string("flash.display".to_sym))
          ])
    codes[8].opcode.should == RedSun::ABC::CoerceA::Opcode
    codes[9].opcode.should == RedSun::ABC::SetLocal1::Opcode

    codes[10].opcode.should == RedSun::ABC::GetLocal1::Opcode
    codes[11].opcode.should == RedSun::ABC::GetProperty::Opcode
    codes[11].property.kind.should == RedSun::ABC::Multiname::MultinameC
    codes[11].property.ns_index.should == nil
    codes[11].property.name.should == :graphics
    verify_trait_ns_set(codes[11].property.ns_set.ns)

    codes[12].opcode.should == RedSun::ABC::PushByte::Opcode
    codes[12].value.should == 1
    codes[13].opcode.should == RedSun::ABC::PushByte::Opcode
    codes[13].value.should == 1
    codes[14].opcode.should == RedSun::ABC::PushByte::Opcode
    codes[14].value.should == 1

    codes[15].opcode.should == RedSun::ABC::CallProperty::Opcode
    codes[15].arg_count.should == 3
    codes[15].property.kind.should == RedSun::ABC::Multiname::MultinameC
    codes[15].property.ns_index.should == nil
    codes[15].property.name.should == :lineStyle
    verify_trait_ns_set(codes[15].property.ns_set.ns)
    codes[16].opcode.should == RedSun::ABC::CoerceA::Opcode
    codes[17].opcode.should == RedSun::ABC::Pop::Opcode

    codes[18].opcode.should == RedSun::ABC::GetLocal1::Opcode
    codes[19].opcode.should == RedSun::ABC::GetProperty::Opcode
    codes[19].property.kind.should == RedSun::ABC::Multiname::MultinameC
    codes[19].property.ns_index.should == nil
    codes[19].property.name.should == :graphics
    verify_trait_ns_set(codes[19].property.ns_set.ns)

    codes[20].opcode.should == RedSun::ABC::PushInt::Opcode
    codes[20].value.should == 0x005500
    codes[21].opcode.should == RedSun::ABC::PushByte::Opcode
    codes[21].value.should == 1

    codes[22].opcode.should == RedSun::ABC::CallProperty::Opcode
    codes[22].arg_count.should == 2
    codes[22].property.kind.should == RedSun::ABC::Multiname::MultinameC
    codes[22].property.ns_index.should == nil
    codes[22].property.name.should == :beginFill
    verify_trait_ns_set(codes[22].property.ns_set.ns)
    codes[23].opcode.should == RedSun::ABC::CoerceA::Opcode
    codes[24].opcode.should == RedSun::ABC::Pop::Opcode

    codes[25].opcode.should == RedSun::ABC::GetLocal1::Opcode
    codes[26].opcode.should == RedSun::ABC::GetProperty::Opcode
    codes[26].property.kind.should == RedSun::ABC::Multiname::MultinameC
    codes[26].property.ns_index.should == nil
    codes[26].property.name.should == :graphics
    verify_trait_ns_set(codes[26].property.ns_set.ns)

    codes[27].opcode.should == RedSun::ABC::PushByte::Opcode
    codes[27].value.should == 50
    codes[28].opcode.should == RedSun::ABC::PushByte::Opcode
    codes[28].value.should == 50
    codes[29].opcode.should == RedSun::ABC::PushByte::Opcode
    codes[29].value.should == 45

    codes[30].opcode.should == RedSun::ABC::CallProperty::Opcode
    codes[30].arg_count.should == 3
    codes[30].property.kind.should == RedSun::ABC::Multiname::MultinameC
    codes[30].property.ns_index.should == nil
    codes[30].property.name.should == :drawCircle
    verify_trait_ns_set(codes[30].property.ns_set.ns)
    codes[31].opcode.should == RedSun::ABC::CoerceA::Opcode
    codes[32].opcode.should == RedSun::ABC::Pop::Opcode

    codes[33].opcode.should == RedSun::ABC::GetLocal1::Opcode
    codes[34].opcode.should == RedSun::ABC::GetProperty::Opcode
    codes[34].property.kind.should == RedSun::ABC::Multiname::MultinameC
    codes[34].property.ns_index.should == nil
    codes[34].property.name.should == :graphics
    verify_trait_ns_set(codes[34].property.ns_set.ns)

    codes[35].opcode.should == RedSun::ABC::CallProperty::Opcode
    codes[35].arg_count.should == 0
    codes[35].property.kind.should == RedSun::ABC::Multiname::MultinameC
    codes[35].property.ns_index.should == nil
    codes[35].property.name.should == :endFill
    verify_trait_ns_set(codes[35].property.ns_set.ns)
    codes[36].opcode.should == RedSun::ABC::CoerceA::Opcode
    codes[37].opcode.should == RedSun::ABC::Pop::Opcode

    codes[38].opcode.should == RedSun::ABC::FindPropStrict::Opcode
    codes[38].property.kind.should == RedSun::ABC::Multiname::MultinameC
    codes[38].property.ns_index.should == nil
    codes[38].property.name.should == :addChild
    verify_trait_ns_set(codes[38].property.ns_set.ns)

    codes[39].opcode.should == RedSun::ABC::GetLocal1::Opcode
    codes[40].opcode.should == RedSun::ABC::CallProperty::Opcode
    codes[40].arg_count.should == 1
    codes[40].property.kind.should == RedSun::ABC::Multiname::MultinameC
    codes[40].property.ns_index.should == nil
    codes[40].property.name.should == :addChild
    verify_trait_ns_set(codes[40].property.ns_set.ns)


    codes[41].opcode.should == RedSun::ABC::CoerceA::Opcode
    #codes[26].opcode.should == RedSun::ABC::Pop::Opcode

    codes[42].opcode.should == RedSun::ABC::ReturnVoid::Opcode

    codes.length.should == 43
  end

end

describe "compiler" do
  before(:each) do
    @af = RedSun::ABC::ABCFile.new
    @empty_swf_ruby = <<HERE
class Traits < Flash::Display::Sprite
  def initialize
    super
    draw(0x334400, 10, 20)
    draw(0x336655, 60, 20)
  end
  def draw(color, x, y)
    get.graphics.lineStyle(4, 0, 1)
    get.graphics.beginFill(color, 1)
    get.graphics.drawRoundRect(x, y, 40, 30, 5)
  end
end
HERE
    @vm = RubyVM::InstructionSequence.compile(@empty_swf_ruby)
    @af.load_ruby(@vm.to_a)
  end

  it "should compile method calls in constructor" do
    inst = @af.instances[0]

    inst.iinit.body.nil?.should == false
    inst.iinit.body.method_index.should == inst.iinit_index
    inst.iinit.body.max_stack.should == 5
    inst.iinit.body.local_count.should == 1
    inst.iinit.body.init_scope_depth.should == 0
    inst.iinit.body.max_scope_depth.should == 1

    codes = inst.iinit.body.code.codes

    codes[0].opcode.should == RedSun::ABC::GetLocal0::Opcode
    codes[1].opcode.should == RedSun::ABC::PushScope::Opcode
    codes[2].opcode.should == RedSun::ABC::PushFalse::Opcode
    codes[3].opcode.should == RedSun::ABC::GetLocal0::Opcode
    codes[4].opcode.should == RedSun::ABC::ConstructSuper::Opcode
    codes[4].arg_count.should == 0
    codes[5].opcode.should == RedSun::ABC::Pop::Opcode

    codes[6].opcode.should == RedSun::ABC::FindPropStrict::Opcode
    codes[6].property.kind.should == RedSun::ABC::Multiname::MultinameC
    codes[6].property.ns_index.should == nil
    codes[6].property.name.should == :draw
    verify_trait_ns_set(codes[6].property.ns_set.ns)

    codes[7].opcode.should == RedSun::ABC::PushInt::Opcode
    codes[7].value.should == 0x334400
    codes[8].opcode.should == RedSun::ABC::PushByte::Opcode
    codes[8].value.should == 10
    codes[9].opcode.should == RedSun::ABC::PushByte::Opcode
    codes[9].value.should == 20

    codes[10].opcode.should == RedSun::ABC::CallProperty::Opcode
    codes[10].arg_count.should == 3
    codes[10].property.kind.should == RedSun::ABC::Multiname::MultinameC
    codes[10].property.ns_index.should == nil
    codes[10].property.name.should == :draw
    verify_trait_ns_set(codes[10].property.ns_set.ns)
    codes[11].opcode.should == RedSun::ABC::CoerceA::Opcode
    codes[12].opcode.should == RedSun::ABC::Pop::Opcode

    codes[13].opcode.should == RedSun::ABC::FindPropStrict::Opcode
    codes[13].property.kind.should == RedSun::ABC::Multiname::MultinameC
    codes[13].property.ns_index.should == nil
    codes[13].property.name.should == :draw
    verify_trait_ns_set(codes[13].property.ns_set.ns)

    codes[14].opcode.should == RedSun::ABC::PushInt::Opcode
    codes[14].value.should == 0x336655
    codes[15].opcode.should == RedSun::ABC::PushByte::Opcode
    codes[15].value.should == 60
    codes[16].opcode.should == RedSun::ABC::PushByte::Opcode
    codes[16].value.should == 20

    codes[17].opcode.should == RedSun::ABC::CallProperty::Opcode
    codes[17].arg_count.should == 3
    codes[17].property.kind.should == RedSun::ABC::Multiname::MultinameC
    codes[17].property.ns_index.should == nil
    codes[17].property.name.should == :draw
    verify_trait_ns_set(codes[17].property.ns_set.ns)

    codes[18].opcode.should == RedSun::ABC::CoerceA::Opcode
    #codes[19].opcode.should == RedSun::ABC::Pop::Opcode

    codes[19].opcode.should == RedSun::ABC::ReturnVoid::Opcode

    codes.length.should == 20
  end

  it "should compile method definition" do
    method = @af.abc_methods[1]

    method.name.should == "Traits/draw".to_sym
    method.return_type_index.should == 0
    method.has_param_names.should == false
    method.param_types.length.should == 3
    method.param_types[0].should == 0
    method.param_types[1].should == 0
    method.param_types[2].should == 0

    method.body.nil?.should == false
    method.body.method_index.should == 1
    method.body.max_stack.should == 5
    method.body.local_count.should == 4
    method.body.init_scope_depth.should == 0
    method.body.max_scope_depth.should == 1

    codes = method.body.code.codes

    codes[0].opcode.should == RedSun::ABC::GetLocal0::Opcode
    codes[1].opcode.should == RedSun::ABC::PushScope::Opcode

    codes[2].opcode.should == RedSun::ABC::GetLex::Opcode
    codes[2].property.kind.should == RedSun::ABC::Multiname::MultinameC
    codes[2].property.ns_index.should == nil
    codes[2].property.name.should == :graphics
    verify_trait_ns_set(codes[2].property.ns_set.ns)

    codes[3].opcode.should == RedSun::ABC::PushByte::Opcode
    codes[3].value.should == 4
    codes[4].opcode.should == RedSun::ABC::PushByte::Opcode
    codes[4].value.should == 0
    codes[5].opcode.should == RedSun::ABC::PushByte::Opcode
    codes[5].value.should == 1

    codes[6].opcode.should == RedSun::ABC::CallProperty::Opcode
    codes[6].arg_count.should == 3
    codes[6].property.kind.should == RedSun::ABC::Multiname::MultinameC
    codes[6].property.ns_index.should == nil
    codes[6].property.name.should == :lineStyle
    verify_trait_ns_set(codes[6].property.ns_set.ns)
    codes[7].opcode.should == RedSun::ABC::CoerceA::Opcode
    codes[8].opcode.should == RedSun::ABC::Pop::Opcode

    codes[9].opcode.should == RedSun::ABC::GetLex::Opcode
    codes[9].property.kind.should == RedSun::ABC::Multiname::MultinameC
    codes[9].property.ns_index.should == nil
    codes[9].property.name.should == :graphics
    verify_trait_ns_set(codes[9].property.ns_set.ns)

    codes[10].opcode.should == RedSun::ABC::GetLocal3::Opcode
    codes[11].opcode.should == RedSun::ABC::PushByte::Opcode
    codes[11].value.should == 1

    codes[12].opcode.should == RedSun::ABC::CallProperty::Opcode
    codes[12].arg_count.should == 2
    codes[12].property.kind.should == RedSun::ABC::Multiname::MultinameC
    codes[12].property.ns_index.should == nil
    codes[12].property.name.should == :beginFill
    verify_trait_ns_set(codes[12].property.ns_set.ns)
    codes[13].opcode.should == RedSun::ABC::CoerceA::Opcode
    codes[14].opcode.should == RedSun::ABC::Pop::Opcode

    codes[15].opcode.should == RedSun::ABC::GetLex::Opcode
    codes[15].property.kind.should == RedSun::ABC::Multiname::MultinameC
    codes[15].property.ns_index.should == nil
    codes[15].property.name.should == :graphics
    verify_trait_ns_set(codes[15].property.ns_set.ns)

    codes[16].opcode.should == RedSun::ABC::GetLocal2::Opcode
    codes[17].opcode.should == RedSun::ABC::GetLocal1::Opcode

    codes[18].opcode.should == RedSun::ABC::PushByte::Opcode
    codes[18].value.should == 40
    codes[19].opcode.should == RedSun::ABC::PushByte::Opcode
    codes[19].value.should == 30
    codes[20].opcode.should == RedSun::ABC::PushByte::Opcode
    codes[20].value.should == 5

    codes[21].opcode.should == RedSun::ABC::CallProperty::Opcode
    codes[21].arg_count.should == 5
    codes[21].property.kind.should == RedSun::ABC::Multiname::MultinameC
    codes[21].property.ns_index.should == nil
    codes[21].property.name.should == :drawRoundRect
    verify_trait_ns_set(codes[21].property.ns_set.ns)
    codes[22].opcode.should == RedSun::ABC::CoerceA::Opcode

    codes[23].opcode.should == RedSun::ABC::ReturnValue::Opcode

    codes.length.should == 24
  end


  it "should compile class initialization setting prototype" do
    cls = @af.classes[0]

    cls.cinit.body.nil?.should == false
    cls.cinit.body.method_index.should == cls.cinit_index
    cls.cinit.body.max_stack.should == 2
    cls.cinit.body.local_count.should == 1
    cls.cinit.body.init_scope_depth.should == 0
    cls.cinit.body.max_scope_depth.should == 1

    codes = cls.cinit.body.code.codes

    codes[0].opcode.should == RedSun::ABC::GetLocal0::Opcode
    codes[1].opcode.should == RedSun::ABC::PushScope::Opcode

    codes[2].opcode.should == RedSun::ABC::GetLex::Opcode
    codes[2].property.kind.should == RedSun::ABC::Multiname::MultinameC
    codes[2].property.ns_index.should == nil
    codes[2].property.name.should == :prototype
    verify_trait_ns_set(codes[2].property.ns_set.ns)

    codes[3].opcode.should == RedSun::ABC::NewFunction::Opcode
    codes[3].index.should == 1

    codes[4].opcode.should == RedSun::ABC::SetProperty::Opcode
    codes[4].property.kind.should == RedSun::ABC::Multiname::MultinameC
    codes[4].property.ns_index.should == nil
    codes[4].property.name.should == :draw
    verify_trait_ns_set(codes[4].property.ns_set.ns)

    codes[5].opcode.should == RedSun::ABC::ReturnVoid::Opcode
  end

end

