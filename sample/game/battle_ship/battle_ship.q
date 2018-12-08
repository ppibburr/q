namespace module BattleShip
  using Gtk
 
  class Player < Object
    attr_accessor grid: :Grid,
                  game: :Game, 
                  ships_visible: :bool,
                  ships: :Ship[]   
   
    signal;
    def lost_game(); end
   

    def self.new(game: :Game)                     
      Object(game:game)

      @ships_visible = true
      @grid = Grid.new(self)                       
    end    
    
    def auto_layout()
      @ships = [
        PatrolBoat.new(),
        Carrier.new(),
        Submarine.new(),
        Destroyer.new(),
        BattleShip.new()
      ]     
    
      @grid.clear()
    
      :Ship.in(@ships) do |ship|
        layout(ship)
        
        ship.sunk.connect() do
          c = 0
          
          :Ship.in(@ships) do |cs|
            if cs.sunken
              c += 1
            end
          end
          
          if c == 5
            lost_game()
          end
        end
      end                  
    end
    
    def layout(ship: :Ship):bool
      x = Random.int_range(0,9)
      y = Random.int_range(0,9)
      q = Random.int_range(0,500)
      
      orient = 0
      
      if q > 250
        orient = 1
      end
      
      cell = :Cell << @grid.find_cell(x,y)
      cc = :Cell
      
      cells = :Cell[]
      cells = nil
      
      if cell.has_ship()
        return layout(ship)
      
      else
        if orient == 0
          if x+ship.length <= 9
            for i in x..x+ship.length-1
              cc = grid.find_cell(i,y);
    
              if cc.has_ship()
                return layout(ship)
              else
                cells += cc
              end
            end
      
          else
            return layout(ship)
          end
        
        else
          if y+ship.length <= 9
            for i in y..y+ship.length-1
              cc = grid.find_cell(x,i);
      
              if cc.has_ship()
                return layout(ship)
      
              else
                cells += cc
              end
            end
          
          else
            return layout(ship)
          end
        end
      end
      
      :Cell.in(cells) do |c|
        c.ship = ship
        
        ship.cells = cells
      
        if @ships_visible
          c.state = Cell::STATE_SHIP       
        else
          c.state = Cell::STATE_WATER
        end
        
        c.render()
      end
      return true
    end    
  end
  
  class Targeter < Object
    @axis           = 0
    @direction      = 0
    @axis_completed = false
    @reversed       = false
    @flopped        = false
    
    @hits           = :Cell[]
    @n_hits         = 0
    
    attr_accessor computer: :Computer,
                  first_hit: :Cell?,
                  last_hit: :Cell?,
                  last_guess: :Cell?
    
    def self.new(comp:Computer)
      Object(computer:comp)
    end
    
    def hit_bound()
      @last_hit = @first_hit
      @last_guess = nil
      
      reverse_direction()   
    end
    
    def guess():Cell?
      if @last_hit != nil
        if @last_guess != nil
          if @last_guess.state == Cell::STATE_MISS
            hit_bound()
            return guess()          
          end
        end
        
        x = @last_hit.x
        y = @last_hit.y
        
        if @axis == 0
          if @direction == 0
            x += 1
          end
          
          if @direction == 1
            x -= 1
          end
        end
        
        if @axis == 1
          if @direction == 0
            y += 1
          end
          
          if @direction == 1
            y -= 1
          end
        end      
        
        if x > 9
          hit_bound()
          return guess()
        end  
        
        if x < 0
          hit_bound()
          return guess()
        end          
        
        if y > 9
          hit_bound()
          return guess()
        end  
        
        if y < 0
          hit_bound()
          return guess()
        end
        
        return @computer.game.player.grid.find_cell(x,y)
      
      else
        return nil           
      end
    end
    
    def change_axis()
      if @flopped
        @last_hit = nil
        return;
      end
    
      @flopped = true
      
      if @axis == 1
        @axis = 0
      else
        @axis = 1
      end      
      
      @reversed = false
      @direction = 0
    end
    
    def reverse_direction()
      if @reversed
        change_axis()
        return;
      end
    
      @reversed = true
      
      if @direction == 1
        @direction = 0
      else
        @direction = 1
      end
    end
  end
  
  class Computer < Player
    attr_accessor targeter: :Targeter
    
    def self.new(game: :Game)                     
      Object(game:game)
      
      @ships_visible = false
      @grid = ComputerGrid.new(self)                              
    end
    
    def target()
      cell = :Cell
      x    = :int
      y    = :int
      
      if @targeter != nil
        cell = @targeter.guess()
        
        if cell == nil
          @targeter = nil
          target()
          return;
        end
      
      else
        x = Random.int_range(0,9);
        y = Random.int_range(0,9);
      
        cell = game.player.grid.find_cell(x,y);
      end
      
      if @targeter != nil
        @targeter.last_guess = cell
      end      
      
      if cell.has_ship() and cell.ship.sunken
        if @targeter != nil
          @targeter.hit_bound() 
        end 
        
        target()
        
        return;
      end
      
      if cell.state == Cell::STATE_MISS
        if @targeter != nil
          @targeter.hit_bound() 
        end      
        
        target()
        
        return;
      end
      
      if cell.state == Cell::STATE_HIT
        if @targeter != nil
          @targeter.hit_bound() 
        end   
        
        target()
        
        return;
      end
      
      cell.clicked()
      
      if cell.state == Cell::STATE_HIT
        if @targeter == nil
          @targeter = Targeter.new(self)
          
          @targeter.first_hit = cell
        end
       
        @targeter.last_hit = cell
        
        if cell.has_ship() && cell.ship.sunken
          @targeter = nil
        end
      end 
    end  
  end
  
  class Game < Object
    :ToolButton[@quit_button, @new_game_button, @redraw_button]
    
    @status_bar = :Statusbar
    @context_id = :uint
    
    
    attr_accessor window: :Gtk::Window,
                  player: :Player,
                  computer: :Computer,
                  active: :bool,
                  wins: :int,
                  losts: :int
    
    signal; 
    def activate(); end
    
    def self.new(win:Window)    
      Object(window:win)

      @active = false
      @wins   = 0
      @losts  = 0

      @computer = Computer.new(self)
      @player   = Player.new(self)
      
      draw()

      
      @player.lost_game.connect() do
        message("You lost :(\n")
        @losts = @losts+1
        new_game()
      end
      

      @computer.lost_game.connect() do
        message("You win!\n")
        @wins += 1
        new_game()
      end
 
      activate.connect() do
        @active = true
        @redraw_button.set_sensitive(false)
      end
 
      new_game()
 
      @window.show_all()
    end
    
    def message(msg: :string)
      dialog = Gtk::MessageDialog.new(@window,
                            Gtk::DialogFlags::MODAL,
                            Gtk::MessageType::WARNING,
                            Gtk::ButtonsType::OK_CANCEL,
                            msg);
     dialog.run();
     dialog.destroy();    
    end
    
    def new_game()
      @status_bar.push(@context_id, "Wins: #{@wins} Losts: #{@losts}")
      @active = false
      @player.auto_layout()
      @computer.auto_layout()
      @redraw_button.set_sensitive(true)
      @redraw_button.show()
    end
    
    def draw()
      vb = Gtk::VBox.new(false,0)
      tb = Gtk::Toolbar.new()
      
      @quit_button = Gtk::ToolButton.new_from_stock(Gtk::Stock::QUIT)
      tb.add(@quit_button)
      @quit_button.clicked.connect() do
        Gtk.main_quit()
      end
     
      
      @new_game_button = Gtk::ToolButton.new_from_stock(Gtk::Stock::NEW)
      tb.add(@new_game_button)  
      @new_game_button.clicked.connect() do
        @player.lost_game()
      end
          
   
      @redraw_button = Gtk::ToolButton.new_from_stock(Gtk::Stock::REDO)
      tb.add(@redraw_button)  
      @redraw_button.clicked.connect() do
        @player.auto_layout()
      end 
      
      vb.pack_start(tb, false,false,2)
     
      hb = Gtk::HBox.new(false,0)
      vb.pack_start(hb,true,true,0) 
      @window.add(vb)
      
      @player.grid.draw(hb)  
      
      hb.pack_start(HSeparator.new(),false,false,14) 
             
      @status_bar = Gtk::Statusbar.new()
      @context_id = @status_bar.get_context_id("battleship")       

      vb.pack_start(@status_bar, false,false, 0)       
                
      @computer.grid.draw(hb)
    end
  end
  
  class Cell < Button
    attr_accessor x: :int,
                  y: :int,
                  state: :int,
                  ostate: :int,
                  ship: :Ship?
    
    STATE_HIT   = 1
    STATE_MISS  = 2
    STATE_SHIP  = 3
    STATE_WATER = 0
    STATE_SUNK  = 4
    
    def self.new()
      st = 0
      Object(state:st)
      set_size_request(40,40)
    end
   
    def has_ship():bool
      if @ship != nil
        return true
      end
      return false
    end
   
    def render()      
      c = Gdk::RGBA.new()
      if @state == Cell::STATE_WATER
        c.parse("rgb(0,0,255)") 
      elsif @state == Cell::STATE_HIT
        c.parse("rgb(255,0,0)")
      elsif @state == Cell::STATE_MISS
        c.parse("rgb(255,255,255)")
      elsif @state == Cell::STATE_SHIP
        c.parse(ship.colour) 
      elsif @state == Cell::STATE_SUNK
        c.parse("rgb(128,25,66)")                   
      end
      
      override_background_color(0, c)
    end
  end
  
  class Grid < Object
    attr_accessor player: :Player
    
    @widget = :Box
    
    def self.new(player:Player)
      Object(player:player)
    end
    
    def add_cell():Cell
      cell = Cell.new()
      return cell
    end
    
    def draw(where: :Gtk::Box)
      @widget = Gtk::VBox.new(false,0)
     
      for i in 0..9
        row = Gtk::HBox.new(false,0)
        for x in 0..9
          b = add_cell()
          b.x = x
          b.y = i
          b.render()
       
          b.enter_notify_event.connect() do
            b.ostate = b.state
            b.state = Cell::STATE_MISS
            b.render()
            return false
          end
   
          b.clicked.connect() do
            if b.state == Cell::STATE_SUNK or (b.has_ship() && b.ship.sunken)
              
            else
              if b.state != Cell::STATE_HIT
                if b.has_ship()
                  b.state = Cell::STATE_HIT
                  b.ostate = Cell::STATE_HIT
                  b.ship.hit()
                else
                  b.state = Cell::STATE_MISS
                  b.ostate = Cell::STATE_MISS
                end
                b.render()
              end
            end
           
          end
          
          b.leave_notify_event.connect() do
            b.state = b.ostate
            b.render()
            return false
          end          
          
          row.pack_start(b,true,true,0)
        end
        @widget.pack_start(row,true,true,0)
      end
      
      where.pack_start(@widget,true,true,0)
    end
    
    def clear()
      for y in 0..9
        for x in 0..9
          cell = :Cell << find_cell(x,y)
          cell.state = 0
          cell.ostate = 0 
          cell.ship = nil
          cell.render()
        end
      end
    end
    
    def find_cell(x: :int, y: :int):Cell?
      r = 0
      c = 0
      
      found = :Widget?
      
      @widget.foreach() do |row|
        if r == y
          (:Box << row).foreach() do |cell|
            if c == x
              found = cell
            end
            
            if c > x
              return;
            end
            
            c = c+1
          end 
        end
        
        if r > y
          return;
        end
        
        r = r+1
      end
      
      return :Cell << found
    end
  end
  
  class ComputerGrid < Grid
    def self.new(player:Player)
      Object(player:player)
    end  
    
    override;
    def add_cell():Cell
      cell = Cell.new()
      cell.clicked.connect() do
        if !@player.game.active
          @player.game.activate()
        end
        
        @player.game.computer.target()
      end
      
      return cell
    end
  end
  
  class Ship < Object
    @length  = :int
    @orient  = :bool
    @cells   = :Cell?[]
    @n_cells = 0
    @colour  = "rgb(0,255,0)"
    
    attr_accessor sunken: :bool,
                  hits: :int,
                  grid: :Grid,
                  name: :string
    
    signal;
    def hit(); end
    
    signal; 
    def sunk(); end

    
    def initialize()
      @sunken = false
      hit.connect() do
        if @sunken
          return;
        end
        
        @hits += 1
        
        if @hits == @length
          self.sunk()
        end
      end
      
      sunk.connect() do
        @sunken = true
        
        puts "#{@name} sunk\n"
        
        :Cell.in(@cells) do |c|
          c.state = Cell::STATE_SUNK
          c.ostate = Cell::STATE_SUNK          
          c.render()
        end
      end
    end
  end
  
  class PatrolBoat < Ship
    def initialize()
      @length = 2
      @name   = "PatrolBoat"
      @colour = "rgb(255,124,0)"
    end
  end
 
  class Destroyer < Ship
    def initialize()
      @length = 3
      @name   = "Destroyer"
      @colour = "rgb(0,124,124)"      
    end
  end 
  
  class Submarine < Ship
    def initialize()
      @length = 4
      @name   = "Submarine"
      @colour = "rgb(124,124,0)"
    end
  end
  
  class Carrier < Ship
    def initialize()
      @length = 5
      @name   = "Carrier"
      @colour = "rgb(124,124,124)"      
    end
  end    
  
  class BattleShip < Ship
    def initialize()
      @length = 6
      @name   = "BattleShip"
    end
  end  
  
  def self.main(args: :string[])
    Gtk.init(:ref << args)
    
    win = Window.new()
    win.set_title("Territorial Battle")
    
    game = Game.new(win)
    
    win.destroy.connect() do
      Gtk.main_quit()
    end
    
    Gtk.main()
  end
end
