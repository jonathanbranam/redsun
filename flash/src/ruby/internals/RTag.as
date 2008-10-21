package ruby.internals
{
public class RTag extends Error
{
  public static const TAG_RAISE:int = 1;

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
