[CCode (cprefix = "Cheese", lower_case_cprefix = "cheese_gtk_")]
namespace CheeseGtk
{
  [CCode (cheader_filename = "cheese-gtk.h")]
  public static bool init([CCode (array_length_cname = "argc", array_length_pos = 0.5)] ref unowned string[]? argv);
}
