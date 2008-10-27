package
{
import com.adobe.serialization.json.JSONDecoder;

import flash.display.Sprite;

import ruby.internals.RbISeq;
import ruby.internals.RubyCore;
import ruby.internals.RubyFrame;

public class RubyVMMain extends Sprite
{
  public function RubyVMMain()
  {
    super();
    var rc:RubyCore = new RubyCore();
    // Must do ruby_init to prep for creating iseq.
    rc.run(get_bytecode(), this);
  }

  protected function get_bytecode():String
  {
    var s:String =
    //"[\"YARVInstructionSequence\\/SimpleDataFormat\",1,1,1,{\"arg_size\":0,\"local_size\":2,\"stack_max\":5},\"<compiled>\",\"<compiled>\",\"top\",[\"v\"],0,[],[1,[\"trace\",1],[\"putstring\",\"hi\"],[\"setlocal\",2],2,[\"trace\",1],[\"putspecialobject\",1],[\"putspecialobject\",2],[\"putobject\",\"pt\"],[\"putiseq\",[\"YARVInstructionSequence\\/SimpleDataFormat\",1,1,1,{\"arg_size\":3,\"local_size\":4,\"stack_max\":2},\"pt\",\"<compiled>\",\"method\",[\"a\",\"b\",\"c\"],3,[],[4,[\"trace\",8],3,[\"trace\",1],[\"getlocal\",4],[\"getlocal\",3],[\"opt_plus\"],[\"getlocal\",2],[\"opt_plus\"],4,[\"trace\",16],3,[\"leave\"]]]],[\"send\",\"core#define_method\",3,null,0,null],[\"pop\"],5,[\"trace\",1],[\"putspecialobject\",1],[\"putspecialobject\",2],[\"putobject\",\"mimic\"],[\"putiseq\",[\"YARVInstructionSequence\\/SimpleDataFormat\",1,1,1,{\"arg_size\":1,\"local_size\":2,\"stack_max\":1},\"mimic\",\"<compiled>\",\"method\",[\"a\"],1,[],[7,[\"trace\",8],6,[\"trace\",1],[\"getlocal\",2],7,[\"trace\",16],6,[\"leave\"]]]],[\"send\",\"core#define_method\",3,null,0,null],[\"pop\"],8,[\"trace\",1],[\"putspecialobject\",1],[\"putspecialobject\",2],[\"putobject\",\"wait\"],[\"putiseq\",[\"YARVInstructionSequence\\/SimpleDataFormat\",1,1,1,{\"arg_size\":0,\"local_size\":1,\"stack_max\":1},\"wait\",\"<compiled>\",\"method\",[],0,[],[10,[\"trace\",8],9,[\"trace\",1],[\"putstring\",\"done waiting\"],10,[\"trace\",16],9,[\"leave\"]]]],[\"send\",\"core#define_method\",3,null,0,null],[\"pop\"],11,[\"trace\",1],[\"putnil\"],[\"putnil\"],[\"putstring\",\"wait 5\"],[\"send\",\"mimic\",1,null,8,null],[\"send\",\"puts\",1,null,8,null],[\"pop\"],12,[\"trace\",1],[\"putnil\"],[\"putnil\"],[\"send\",\"wait\",0,null,8,null],[\"send\",\"puts\",1,null,8,null],[\"pop\"],13,[\"trace\",1],[\"putspecialobject\",1],[\"putspecialobject\",2],[\"putobject\",\"col\"],[\"putiseq\",[\"YARVInstructionSequence\\/SimpleDataFormat\",1,1,1,{\"arg_size\":0,\"local_size\":1,\"stack_max\":1},\"col\",\"<compiled>\",\"method\",[],0,[],[15,[\"trace\",8],14,[\"trace\",1],[\"putobject\",65280],15,[\"trace\",16],14,[\"leave\"]]]],[\"send\",\"core#define_method\",3,null,0,null],[\"pop\"],16,[\"trace\",1],\"label_112\",[\"getinlinecache\",null,\"label_119\"],[\"getconstant\",\"Document\"],[\"setinlinecache\",\"label_112\"],\"label_119\",[\"send\",\"graphics\",0,null,0,null],[\"putobject\",1],[\"putobject\",1],[\"putobject\",1],[\"send\",\"lineStyle\",3,null,0,null],[\"pop\"],17,[\"trace\",1],\"label_140\",[\"getinlinecache\",null,\"label_147\"],[\"getconstant\",\"Document\"],[\"setinlinecache\",\"label_140\"],\"label_147\",[\"send\",\"graphics\",0,null,0,null],[\"putnil\"],[\"send\",\"col\",0,null,24,null],[\"send\",\"beginFill\",1,null,0,null],[\"pop\"],18,[\"trace\",1],\"label_169\",[\"getinlinecache\",null,\"label_176\"],[\"getconstant\",\"Document\"],[\"setinlinecache\",\"label_169\"],\"label_176\",[\"send\",\"graphics\",0,null,0,null],[\"putobject\",5],[\"putobject\",5],[\"putobject\",105],[\"putobject\",105],[\"send\",\"drawRect\",4,null,0,null],[\"leave\"]]]";
    //some functions
    //"[\"YARVInstructionSequence\\/SimpleDataFormat\",1,1,1,{\"arg_size\":0,\"local_size\":2,\"stack_max\":5},\"<compiled>\",\"<compiled>\",\"top\",[\"v\"],0,[],[1,[\"trace\",1],[\"putstring\",\"hi\"],[\"setlocal\",2],2,[\"trace\",1],[\"putspecialobject\",1],[\"putspecialobject\",2],[\"putobject\",\"pt\"],[\"putiseq\",[\"YARVInstructionSequence\\/SimpleDataFormat\",1,1,1,{\"arg_size\":3,\"local_size\":4,\"stack_max\":2},\"pt\",\"<compiled>\",\"method\",[\"a\",\"b\",\"c\"],3,[],[4,[\"trace\",8],3,[\"trace\",1],[\"getlocal\",4],[\"getlocal\",3],[\"opt_plus\"],[\"getlocal\",2],[\"opt_plus\"],4,[\"trace\",16],3,[\"leave\"]]]],[\"send\",\"core#define_method\",3,null,0,null],[\"pop\"],5,[\"trace\",1],[\"putspecialobject\",1],[\"putspecialobject\",2],[\"putobject\",\"mimic\"],[\"putiseq\",[\"YARVInstructionSequence\\/SimpleDataFormat\",1,1,1,{\"arg_size\":1,\"local_size\":2,\"stack_max\":1},\"mimic\",\"<compiled>\",\"method\",[\"a\"],1,[],[7,[\"trace\",8],6,[\"trace\",1],[\"getlocal\",2],7,[\"trace\",16],6,[\"leave\"]]]],[\"send\",\"core#define_method\",3,null,0,null],[\"pop\"],8,[\"trace\",1],[\"putspecialobject\",1],[\"putspecialobject\",2],[\"putobject\",\"wait\"],[\"putiseq\",[\"YARVInstructionSequence\\/SimpleDataFormat\",1,1,1,{\"arg_size\":0,\"local_size\":1,\"stack_max\":1},\"wait\",\"<compiled>\",\"method\",[],0,[],[10,[\"trace\",8],9,[\"trace\",1],[\"putstring\",\"done waiting\"],10,[\"trace\",16],9,[\"leave\"]]]],[\"send\",\"core#define_method\",3,null,0,null],[\"pop\"],11,[\"trace\",1],[\"putnil\"],[\"putnil\"],[\"putstring\",\"wait 5\"],[\"send\",\"mimic\",1,null,8,null],[\"send\",\"puts\",1,null,8,null],[\"pop\"],12,[\"trace\",1],[\"putnil\"],[\"putnil\"],[\"send\",\"wait\",0,null,8,null],[\"send\",\"puts\",1,null,8,null],[\"pop\"],13,[\"trace\",1],[\"putspecialobject\",1],[\"putspecialobject\",2],[\"putobject\",\"col\"],[\"putiseq\",[\"YARVInstructionSequence\\/SimpleDataFormat\",1,1,1,{\"arg_size\":0,\"local_size\":1,\"stack_max\":1},\"col\",\"<compiled>\",\"method\",[],0,[],[15,[\"trace\",8],14,[\"trace\",1],[\"putobject\",255],15,[\"trace\",16],14,[\"leave\"]]]],[\"send\",\"core#define_method\",3,null,0,null],[\"pop\"],16,[\"trace\",1],\"label_112\",[\"getinlinecache\",null,\"label_119\"],[\"getconstant\",\"Document\"],[\"setinlinecache\",\"label_112\"],\"label_119\",[\"send\",\"graphics\",0,null,0,null],[\"putobject\",1],[\"putobject\",1],[\"putobject\",1],[\"send\",\"lineStyle\",3,null,0,null],[\"pop\"],17,[\"trace\",1],\"label_140\",[\"getinlinecache\",null,\"label_147\"],[\"getconstant\",\"Document\"],[\"setinlinecache\",\"label_140\"],\"label_147\",[\"send\",\"graphics\",0,null,0,null],[\"putnil\"],[\"send\",\"col\",0,null,24,null],[\"send\",\"beginFill\",1,null,0,null],[\"pop\"],18,[\"trace\",1],\"label_169\",[\"getinlinecache\",null,\"label_176\"],[\"getconstant\",\"Document\"],[\"setinlinecache\",\"label_169\"],\"label_176\",[\"send\",\"graphics\",0,null,0,null],[\"putobject\",5],[\"putobject\",5],[\"putobject\",105],[\"putobject\",105],[\"send\",\"drawRect\",4,null,0,null],[\"leave\"]]]";

    // create class
    //"[\"YARVInstructionSequence\\/SimpleDataFormat\",1,1,1,{\"arg_size\":0,\"local_size\":2,\"stack_max\":2},\"<compiled>\",\"<compiled>\",\"top\",[\"a\"],0,[],[1,[\"trace\",1],[\"putspecialobject\",2],[\"putnil\"],[\"defineclass\",\"A\",[\"YARVInstructionSequence\\/SimpleDataFormat\",1,1,1,{\"arg_size\":0,\"local_size\":1,\"stack_max\":4},\"<class:A>\",\"<compiled>\",\"class\",[],0,[],[10,[\"trace\",2],2,[\"trace\",1],[\"putspecialobject\",1],[\"putspecialobject\",2],[\"putobject\",\"col\"],[\"putiseq\",[\"YARVInstructionSequence\\/SimpleDataFormat\",1,1,1,{\"arg_size\":0,\"local_size\":1,\"stack_max\":1},\"col\",\"<compiled>\",\"method\",[],0,[],[4,[\"trace\",8],3,[\"trace\",1],[\"putobject\",3368499],4,[\"trace\",16],3,[\"leave\"]]]],[\"send\",\"core#define_method\",3,null,0,null],[\"pop\"],5,[\"trace\",1],[\"putspecialobject\",1],[\"putspecialobject\",2],[\"putobject\",\"a\"],[\"putiseq\",[\"YARVInstructionSequence\\/SimpleDataFormat\",1,1,1,{\"arg_size\":0,\"local_size\":1,\"stack_max\":5},\"a\",\"<compiled>\",\"method\",[],0,[],[9,[\"trace\",8],6,[\"trace\",1],\"label_4\",[\"getinlinecache\",null,\"label_11\"],[\"getconstant\",\"Document\"],[\"setinlinecache\",\"label_4\"],\"label_11\",[\"send\",\"graphics\",0,null,0,null],[\"putobject\",1],[\"putobject\",1],[\"putobject\",1],[\"send\",\"lineStyle\",3,null,0,null],[\"pop\"],7,[\"trace\",1],\"label_32\",[\"getinlinecache\",null,\"label_39\"],[\"getconstant\",\"Document\"],[\"setinlinecache\",\"label_32\"],\"label_39\",[\"send\",\"graphics\",0,null,0,null],[\"putnil\"],[\"send\",\"col\",0,null,24,null],[\"send\",\"beginFill\",1,null,0,null],[\"pop\"],8,[\"trace\",1],\"label_61\",[\"getinlinecache\",null,\"label_68\"],[\"getconstant\",\"Document\"],[\"setinlinecache\",\"label_61\"],\"label_68\",[\"send\",\"graphics\",0,null,0,null],[\"putobject\",5],[\"putobject\",5],[\"putobject\",105],[\"putobject\",105],[\"send\",\"drawRect\",4,null,0,null],9,[\"trace\",16],8,[\"leave\"]]]],[\"send\",\"core#define_method\",3,null,0,null],10,[\"trace\",4],5,[\"leave\"]]],0],[\"pop\"],11,[\"trace\",1],\"label_12\",[\"getinlinecache\",null,\"label_19\"],[\"getconstant\",\"A\"],[\"setinlinecache\",\"label_12\"],\"label_19\",[\"send\",\"new\",0,null,0,null],[\"setlocal\",2],12,[\"trace\",1],[\"getlocal\",2],[\"send\",\"a\",0,null,0,null],[\"leave\"]]]";

    // class + module
    "[\"YARVInstructionSequence\\/SimpleDataFormat\",1,1,1,{\"arg_size\":0,\"local_size\":2,\"stack_max\":2},\"<compiled>\",\"<compiled>\",\"top\",[\"a\"],0,[],[1,[\"trace\",1],[\"putspecialobject\",2],[\"putnil\"],[\"defineclass\",\"B\",[\"YARVInstructionSequence\\/SimpleDataFormat\",1,1,1,{\"arg_size\":0,\"local_size\":1,\"stack_max\":4},\"<module:B>\",\"<compiled>\",\"class\",[],0,[],[5,[\"trace\",2],2,[\"trace\",1],[\"putspecialobject\",1],[\"putspecialobject\",2],[\"putobject\",\"col\"],[\"putiseq\",[\"YARVInstructionSequence\\/SimpleDataFormat\",1,1,1,{\"arg_size\":0,\"local_size\":1,\"stack_max\":1},\"col\",\"<compiled>\",\"method\",[],0,[],[4,[\"trace\",8],3,[\"trace\",1],[\"putobject\",6697762],4,[\"trace\",16],3,[\"leave\"]]]],[\"send\",\"core#define_method\",3,null,0,null],5,[\"trace\",4],2,[\"leave\"]]],2],[\"pop\"],6,[\"trace\",1],[\"putspecialobject\",2],[\"putnil\"],[\"defineclass\",\"A\",[\"YARVInstructionSequence\\/SimpleDataFormat\",1,1,1,{\"arg_size\":0,\"local_size\":1,\"stack_max\":4},\"<class:A>\",\"<compiled>\",\"class\",[],0,[],[13,[\"trace\",2],7,[\"trace\",1],[\"putnil\"],\"label_5\",[\"getinlinecache\",null,\"label_12\"],[\"getconstant\",\"B\"],[\"setinlinecache\",\"label_5\"],\"label_12\",[\"send\",\"include\",1,null,8,null],[\"pop\"],8,[\"trace\",1],[\"putspecialobject\",1],[\"putspecialobject\",2],[\"putobject\",\"a\"],[\"putiseq\",[\"YARVInstructionSequence\\/SimpleDataFormat\",1,1,1,{\"arg_size\":0,\"local_size\":1,\"stack_max\":5},\"a\",\"<compiled>\",\"method\",[],0,[],[12,[\"trace\",8],9,[\"trace\",1],\"label_4\",[\"getinlinecache\",null,\"label_11\"],[\"getconstant\",\"Document\"],[\"setinlinecache\",\"label_4\"],\"label_11\",[\"send\",\"graphics\",0,null,0,null],[\"putobject\",1],[\"putobject\",1],[\"putobject\",1],[\"send\",\"lineStyle\",3,null,0,null],[\"pop\"],10,[\"trace\",1],\"label_32\",[\"getinlinecache\",null,\"label_39\"],[\"getconstant\",\"Document\"],[\"setinlinecache\",\"label_32\"],\"label_39\",[\"send\",\"graphics\",0,null,0,null],[\"putnil\"],[\"send\",\"col\",0,null,24,null],[\"send\",\"beginFill\",1,null,0,null],[\"pop\"],11,[\"trace\",1],\"label_61\",[\"getinlinecache\",null,\"label_68\"],[\"getconstant\",\"Document\"],[\"setinlinecache\",\"label_61\"],\"label_68\",[\"send\",\"graphics\",0,null,0,null],[\"putobject\",5],[\"putobject\",5],[\"putobject\",105],[\"putobject\",105],[\"send\",\"drawRect\",4,null,0,null],12,[\"trace\",16],11,[\"leave\"]]]],[\"send\",\"core#define_method\",3,null,0,null],13,[\"trace\",4],8,[\"leave\"]]],0],[\"pop\"],14,[\"trace\",1],\"label_22\",[\"getinlinecache\",null,\"label_29\"],[\"getconstant\",\"A\"],[\"setinlinecache\",\"label_22\"],\"label_29\",[\"send\",\"new\",0,null,0,null],[\"setlocal\",2],15,[\"trace\",1],[\"getlocal\",2],[\"send\",\"a\",0,null,0,null],[\"leave\"]]]";
    return s;
  }

  protected function get_iseq(rc:RubyCore):Array
  {
    var s:String = get_bytecode();

    var decoder:JSONDecoder = new JSONDecoder( s, rc )
    return decoder.getValue();

    //return JSON.decode(s);
  }

  protected function ruby_iseq2(rc:RubyCore):Array
  {
    return [
  "YARVInstructionSequence/SimpleDataFormat", 1, 1, 1,
  {arg_size:0, local_size:2, stack_max:5},
  "<compiled>", "<compiled>",
  "top",
  ["v"],
  0,
  [],
  [
    ["putstring", "hi"],
    ["setlocal", 2],
    ["putspecialobject", 1],
    ["putspecialobject", 2],
    ["putobject", "mimic"],
    ["putiseq",
      [
        "YARVInstructionSequence/SimpleDataFormat", 1, 1, 1,
        {arg_size:1, local_size:2, stack_max:1},
        "mimic", "<compiled>",
        "method",
        ["a"],
        1,
        [],
        [
          ["getlocal", 2],
          ["leave"],
        ]
      ]
    ],
    ["send", "core#define_method", 3, rc.Qnil, 0, rc.Qnil],
    ["pop"],
    ["putspecialobject", 1],
    ["putspecialobject", 2],
    ["putobject", "wait"],
    ["putiseq",
      [
        "YARVInstructionSequence/SimpleDataFormat", 1, 1, 1,
        {arg_size:0, local_size:1, stack_max:1},
        "wait", "<compiled>",
        "method",
        [],
        0,
        [],
        [
          ["putstring", "done waiting"],
          ["leave"],
        ]
      ]
    ],
    ["send", "core#define_method", 3, rc.Qnil, 0, rc.Qnil],
    ["pop"],
    ["putnil"],
    ["putnil"],
    ["putstring", "wait 5"],
    ["send", "mimic", 1, rc.Qnil, 8, rc.Qnil],
    ["send", "puts", 1, rc.Qnil, 8, rc.Qnil],
    ["pop"],
    ["putnil"],
    ["putnil"],
    ["send", "wait", 0, rc.Qnil, 8, rc.Qnil],
    ["send", "puts", 1, rc.Qnil, 8, rc.Qnil],
    ["pop"],
    ["putspecialobject", 1],
    ["putspecialobject", 2],
    ["putobject", "col"],
    ["putiseq",
      [
        "YARVInstructionSequence/SimpleDataFormat", 1, 1, 1,
        {arg_size:0, local_size:1, stack_max:1},
        "col", "<compiled>",
        "method",
        [],
        0,
        [],
        [
          ["putobject", 65280],
          ["leave"],
        ]
      ]
    ],
    ["send", "core#define_method", 3, rc.Qnil, 0, rc.Qnil],
    ["pop"],
    "label_95",
    ["getinlinecache", rc.Qnil, "label_102"],
    ["getconstant", "Document"],
    ["setinlinecache", "label_95"],
    "label_102",
    ["send", "graphics", 0, rc.Qnil, 0, rc.Qnil],
    ["putobject", 1],
    ["putobject", 1],
    ["putobject", 1],
    ["send", "lineStyle", 3, rc.Qnil, 0, rc.Qnil],
    ["pop"],
    "label_123",
    ["getinlinecache", rc.Qnil, "label_130"],
    ["getconstant", "Document"],
    ["setinlinecache", "label_123"],
    "label_130",
    ["send", "graphics", 0, rc.Qnil, 0, rc.Qnil],
    ["putnil"],
    ["send", "col", 0, rc.Qnil, 24, rc.Qnil],
    ["send", "beginFill", 1, rc.Qnil, 0, rc.Qnil],
    ["pop"],
    "label_152",
    ["getinlinecache", rc.Qnil, "label_159"],
    ["getconstant", "Document"],
    ["setinlinecache", "label_152"],
    "label_159",
    ["send", "graphics", 0, rc.Qnil, 0, rc.Qnil],
    ["putobject", 5],
    ["putobject", 5],
    ["putobject", 105],
    ["putobject", 105],
    ["send", "drawRect", 4, rc.Qnil, 0, rc.Qnil],
    ["leave"],
  ]
];


  }

  protected function ruby_func():Function
  {
    return function (f:RubyFrame):void {
      f.putstring("hi");
      f.setlocal(2);

      f.getinlinecache(f.Qnil, "label_15");
      f.getconstant("Document");
      f.setinlinecache("label_8");
      f.send("graphics", 0, f.Qnil, 0, f.Qnil);
      f.putobject(1);
      f.putobject(1);
      f.putobject(1);
      f.send("lineStyle", 3, f.Qnil, 0, f.Qnil);
      f.pop();

      f.getinlinecache(f.Qnil, "label_43");
      f.getconstant("Document");
      f.setinlinecache("label_36");
      f.send("graphics", 0, f.Qnil, 0, f.Qnil);
      f.putobject(5);
      f.putobject(5);
      f.putobject(105);
      f.putobject(105);
      f.send("drawRect", 4, f.Qnil, 0, f.Qnil);
      f.pop();

      f.getlocal(2);
      if (f.branchif()) {
        f.putnil();
        f.putstring("FAIL");
        f.send("puts", 1, f.Qnil, 8, f.Qnil);
        f.pop();
      }
      f.getlocal(2);
      if (f.branchunless()) {
        f.putnil();
        f.putstring("SUCCESS");
        f.send("puts", 1, f.Qnil, 8, f.Qnil);
        f.leave();
        return;
        f.pop();
      }

      f.putnil();
      f.leave();
      return;
    }
  }

  protected function ruby_func2():Function
  {
    return function (f:RubyFrame):void {
      f.putnil();
      f.putstring("THIS IS A STRING FROM RUBY!!");
      f.send("puts", 1, f.Qnil, 8, f.Qnil);

      f.putstring("put this into local var");
      f.setlocal(2);

      f.putnil();
      f.getlocal(2);
      f.send("puts", 1, f.Qnil, 8, f.Qnil);

      f.putnil();
      f.putstring("This is another string.");
      f.send("puts", 1, f.Qnil, 8, f.Qnil);

      f.putspecialobject(2);
      f.putnil();
      var class_iseq:RbISeq = f.rc.class_iseq_from_func("A", 0, 1, 1,
      function(f:RubyFrame):void {

        f.putspecialobject(1);
        f.putspecialobject(2);
        f.putobject("m");

        var m_iseq:RbISeq = f.rc.method_iseq_from_func("m", 0, 1, 1,
        function(f:RubyFrame):void {
          f.putstring("RETURNED from A#m");
          f.leave();
        });

        f.putiseq(m_iseq);
        f.send("core#define_method", 3, f.Qnil, 0, f.Qnil);

        f.putnil();
        f.leave();
      });

      f.defineclass("A", class_iseq, 0);
      f.pop();

      f.getinlinecache(f.Qnil, "label_31");
      f.getconstant("A");
      f.setinlinecache("label_24");
      f.send("new", 0, f.Qnil, 0, f.Qnil);
      f.setlocal(2);

      f.putnil();
      f.getlocal(2);
      f.send("m", 0, f.Qnil, 0, f.Qnil);
      f.send("puts", 1, f.Qnil, 8, f.Qnil);

      // [:leave]
      f.leave();
    };
  }

}
}
