class Sim
  REGEX = [/(\d+)\s+(\d+)/, /(\d+)\s+(\d+)\s+([NSEW])/, /([LMR]+)/]
  
  attr_accessor :map, :commands
 
  def initialize
    @map      = nil
    @commands = []
    @rovers   = []
  end
  
  #accepts input via console
  def console_input
    print "Ready for data entry.  When complete, enter a blank line.\n>"
    input = nil
    i = 0
    while true
      input = gets.chomp
      break if input == ''
      match_data = validate_data(input, i)
      @commands << match_data
      print ">"
      i += 1
    end
  end
  
  #converts all numbers in the command array to integers
  def convert_commands
    @commands.each do |array|
      array.map! do |command| 
        if command =~ /\d+/ 
          command.to_i
        else
          command
        end
      end
    end
  end
  
  def create_map
    #since the provided map size is the end index, we must add 1 to achieve the
    #desired effect since arrays are zero-indexed
    @map = Array.new(@commands[0][0] +  1) {Array.new(@commands[0][1] + 1)}
    @commands.shift
  end
  
  def file_input
    print "Please type the name of the file wish you to load.\n>"
    filename = gets.chomp
    contents = []
    File.read(filename).each_line {|line| contents << line.chomp}
    contents.each_with_index do |line, i|
      match_data = validate_data(line, i)
      @commands << match_data
    end
  end
  
  def get_input
    while true
      print "Press (F) to load a file or (C) to enter simulation data via the console.\n>"
      input = gets.chomp
      break if input == 'F' || input == 'C'
    end
    if input == 'F'
      file_input
    else
      console_input
    end
  end
  
  #prints results of the simulation to the end user
  def print_results
    @rovers.each do |rover|
      puts "#{rover.position[0]} #{rover.position[1]} #{rover.direction}"
    end
    puts "=" * 10
  end
  
  def process_commands
    @commands.each_with_index do |array, i|
      if i % 2 == 0
        @rovers << Rover.new([array[0], array[1]], array[2], @map)
      else
        @rovers.last.run(array)
      end
    end
  end
  
  #runs the simulation using the given commands
  def run
    get_input
    convert_commands
    create_map
    process_commands
    print_results
  end
  
  def validate_coords(coords)
    if (coords[0] < 0 || coords[1] < 0 || coords[0] > @commands[0][0].to_i ||
        coords[1] > @commands[0][1].to_i )
      raise "Rover was placed outside the map boundaries."
    end
  end
  
  #returns command data in an array unless data is not in correct format, then raises except
  def validate_data(input, i)
    match_data = REGEX[0].match(input) if i == 0
    match_data = REGEX[i % 2 == 1 ? 1 : 2].match(input) if i != 0
    if i % 2 == 1 && match_data
      coords = match_data.to_a[1..2].map(&:to_i)
      validate_coords(coords)
    end
    #we only want index 1 through to the end. index 0 is the match without groupings
    return match_data[1..-1] unless match_data.nil?
    raise "Data input error, please check formatting."
  end
end

class Rover
  DIRECTION_TO_VECTOR = {'N' => [0,1], 'S' => [0,-1], 'E' => [1,0], 'W' => [-1,0]}
  # this is an array used to simulate clockswise and counter clockwise movement by
  # changing the index value -1 for left and +1 for right
  DIRECTIONS_MAP      = ['N', 'E', 'S', 'W']
  TURN_MAP            = {'L' => -1, 'R' => 1}
  
  attr_reader :position, :direction

  def initialize(position, direction, map)
    @direction  = direction
    @map        = map
    @directions = ['N', 'E', 'S', 'W']
    @position   = position
    #place this rover on the map so it can be seen by other rovers    
    map[position[0]][position[1]] = self
  end
  
  def get_map(coords)
    @map[coords[0]][coords[1]]
  end
  
  def set_map(coords, value)
    @map[coords[0]][coords[1]] = value  
  end
  
  def move
    raise "Invalid move attempted by rover." unless valid_move?
    coords = next_coords
    old_position = get_map(@position)
    set_map(coords, self)
    set_map(@position, nil)
    @position = coords
  end
  
  #returns the coordinates of the next move based on current postion
  #and heading
  def next_coords
    vector = DIRECTION_TO_VECTOR[@direction]
    [vector[0] + @position[0], vector[1] + @position[1]]
  end
  
  def on_map?(coords)
    return false if (coords[0] < 0 || coords[1] < 0)
    return false if (coords[0] + 1 > @map.length) || (coords[1] + 1 > @map[0].length)
    true
  end
   
  def run(commands)
    commands.first.split('').each do |command|
      if command == 'M'
        move
      elsif command == 'L' || command == 'R'
        turn(command)
      end
    end
  end
  
  def to_s
    "r"
  end
    
  def turn(direction)
    new_dir = DIRECTIONS_MAP.index(@direction) + TURN_MAP[direction]
    new_dir += 4 if new_dir < 0
    new_dir -= 4 if new_dir > 3
    @direction = DIRECTIONS_MAP[new_dir]
  end
    
  def valid_move?
    coords = next_coords
    return false unless on_map?(next_coords)
    return false unless get_map(coords).nil?
    true
  end
end

s = Sim.new
s.run

