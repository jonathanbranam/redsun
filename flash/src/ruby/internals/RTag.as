package ruby.internals
{
public class RTag extends Error
{
  public static const TAG_RETURN:int = 1;
  public static const TAG_BREAK:int = 2;
  public static const TAG_NEXT:int = 3;
  public static const TAG_RETRY:int = 4;
  public static const TAG_REDO:int = 5
  public static const TAG_RAISE:int = 6;
  public static const TAG_THROW:int = 7;
  public static const TAG_FATAL:int = 8;
  public static const TAG_MASK:int = 0xf;


  public var tag:int;
  public var mesg:Value;

  public function RTag(tag:int, mesg:Value)
  {
    super("Tag: " + tag + " value: " + mesg);
    this.tag = tag;
    this.mesg = mesg;
  }

}
}
