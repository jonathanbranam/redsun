package
{
import flash.display.Sprite;

import ruby.internals.RbISeq;
import ruby.internals.RubyCore;
import ruby.internals.RubyFrame;
import ruby.internals.Value;

public class RubyVMMain extends Sprite
{
  public function RubyVMMain()
  {
    super();
    var rc:RubyCore = new RubyCore();
    // Must do ruby_init to prep for creating iseq.
    rc.run(this, ruby_iseq(rc));
  }

  protected function ruby_iseq(rc:RubyCore):Array
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
