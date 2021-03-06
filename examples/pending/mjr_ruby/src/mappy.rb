require 'two_d_grid_location'
require 'two_d_grid_map'

class Mappy < Actor
  attr_reader :major_ruby, :tw, :th, :width, :height, :actors, :pretty_gems

  def setup
    @pretty_gems = []
    @actors = []
    load_map @opts[:map_filename]

    @major_ruby = spawn :major_ruby, :x => 100, :y => 50, :map => self
  end

  def finished?
    @pretty_gems.size == 0
  end

  def remove(gems)
    @actors.delete_if{|it|gems.include? it}
    @pretty_gems.delete_if{|it|gems.include? it}
  end

  def load_map(filename)
    lines = File.readlines(File.join(DATA_PATH,"maps",filename)).map { |line| line.chop }
    @height = lines.size
    @width = lines[0].size
    @pretty_gems = []
    @actors = []
    @tw = 44
    @th = 44
    @half_tw = @tw/2
    @half_th = @tw/2


    @map = TwoDGridMap.new @width, @height

    @width.times do |x|
      @height.times do |y|
        type = 
          case lines[y][x, 1]
            when '"'
              # grass
              :grass
            when '#'
              # earth
              :earth
            when 'x'
              # gem
              :pretty_gem
            else
              nil
          end
        unless type.nil?
          # no overlap yet
          thing = spawn type, :x => x*@tw, :y => y*@tw
          @actors << thing

          @pretty_gems << thing if type == :pretty_gem
          @map.place(TwoDGridLocation.new(x,y), thing)
        end
      end
    end

    @map
  end

  def solid?(x,y)
    occ = @map.occupant TwoDGridLocation.new((x+@half_tw)/@tw, (y+@half_th)/@th)
    not occ.nil? and occ.class != PrettyGem
  end
  
end
