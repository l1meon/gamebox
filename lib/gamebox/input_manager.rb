require 'publisher'
class InputManager
  extend Publisher
  can_fire :key_up, :event_received

  MOUSE_BUTTON_LOOKUP = {
    1 => :left,
    2 => :middle,
    3 => :right,
  }

  attr_accessor :hooks
  
  def initialize
    @queue = EventQueue.new
    @queue.ignore = [
      ActiveEvent,
      JoyAxisEvent,
      JoyBallEvent,
      JoyDownEvent,
      JoyHatEvent,
      JoyUpEvent,
      ResizeEvent
    ]
    
    @clock = Clock.new do |c|
      c.target_framerate = 40
      if c.respond_to? :calibrate
        c.calibrate 
        c.granularity = 2 if c.granularity < 2
      end
    end

    @hooks = {}
    @non_id_hooks = {}
  end
  
  def framerate=(frame_rate)
    @clock.target_framerate = frame_rate
  end
  
  def framerate
    @clock.target_framerate
  end

  def main_loop(game)
    catch(:rubygame_quit) do
      loop do
        # add magic hooks
        @queue.each do |event|
          case event
          when KeyDownEvent
            case event.key
            when K_F
              puts "Framerate:#{@clock.framerate}"
            when K_ESCAPE
              throw :rubygame_quit
            end
          when QuitEvent
            throw :rubygame_quit
          end
          fire :event_received, event

          event_hooks = @hooks[event.class] 
          id = event.key if event.respond_to? :key
          id ||= MOUSE_BUTTON_LOOKUP[event.button] if event.respond_to? :button
          unless id.nil?
            event_action_hooks = event_hooks[id] if event_hooks
            if event_action_hooks
              for callback in event_action_hooks
                callback.call event
              end
            end
          end
          
          non_id_event_hooks = @non_id_hooks[event.class]
          if non_id_event_hooks
            for callback in non_id_event_hooks
              callback.call event
            end
          end          
        end

        game.update @clock.tick
      end
    end
  end

  def register_hook(event_class, *event_ids, &block)
    return unless block_given?
    @hooks[event_class] ||= {}
    for event_id in event_ids
      @hooks[event_class][event_id] ||= []
      @hooks[event_class][event_id] << block
    end
    @non_id_hooks[event_class] ||= []
    if event_ids.empty?
      @non_id_hooks[event_class] << block
    end
    listener = eval("self", block.binding) 
    listener.when :remove_me do
      unregister_hook event_class, *event_ids, &block
    end
  end
  alias reg register_hook

  def unregister_hook(event_class, *event_ids, &block)
    @hooks[event_class] ||= {}
    for event_id in event_ids
      @hooks[event_class][event_id] ||= []
      @hooks[event_class][event_id].delete block if block_given?
    end
    if event_ids.empty?
      @hooks[event_class] ||= []
      @hooks[event_class].delete block if block_given?
    end
  end
  alias unreg unregister_hook

  def clear_hooks(listener=nil)
    if listener
      for event_klass, id_listeners in @hooks
        for key in id_listeners.keys.dup
          id_listeners[key].delete_if do |block|
            eval('self',block.binding).equal?(listener)
          end
        end
      end
      
      for key in @non_id_hooks.keys.dup
        @non_id_hooks[key].delete_if do |block|
          eval('self',block.binding).equal?(listener)
        end
      end
    else
      @hooks = {}
      @non_id_hooks = {}
    end
  end
end
