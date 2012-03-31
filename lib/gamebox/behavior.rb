# Behavior is any type of behavior an actor can exibit.
class Behavior
  attr_accessor :actor, :opts, :relegated_methods

  def configure(actor, opts={})
    @actor = actor
    @opts = opts
    @relegated_methods = []
    setup
  end

  def setup
  end

  def react_to(message_type, *opts)
  end

  def removed
    target = self

    @actor.instance_eval do
      (class << self; self; end).class_eval do
        target.relegated_methods.each do |meth|
          remove_method meth
        end
      end
    end
  end

  def update(time)
  end

  def self.required_behaviors
    @required_behaviors ||= []
  end

  def self.requires_behaviors(*args)
    @required_behaviors ||= []
    for a in args
      @required_behaviors << a
    end
    @behaviors
  end

  def self.requires_behavior(*args)
    requires_behaviors(*args)
  end

  def relegates(*methods)
    target = self

    @actor.instance_eval do
      (class << self; self; end).class_eval do
        methods.each do |meth|
          # log("redefining #{meth} for #{@actor.class}") if @actor.respond_to? meth
          target.relegated_methods << meth

          define_method meth do |*args, &block|
            target.send meth, *args, &block
          end
        end
      end
    end
  end

end
