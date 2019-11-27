namespace module Q
  namespace module UI
    # BUG: Gtk::InfoBar may not reshow once hidden
    # This fixes that
    class InfoBar < Gtk::InfoBar
      def initialize()
        revealer = :Gtk::Revealer > get_template_child(typeof(:Gtk::InfoBar),"revealer");
        if (revealer!=nil) 
          revealer.transition_type = Gtk::RevealerTransitionType::NONE
          revealer.set_transition_duration(0);
        end
      end
      
      def self.new_with_buttons(argv: :Value?[])
        Object()
        i = 0
        while argv[i] != nil
          add_button(:string > argv[i],:int > argv[i+1])
          i+=2
        end
      end
    end
  end
end
