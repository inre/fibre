class FiberError < StandardError
  attr_accessor :parent

  def initialize parent = $!
    @parent = parent
    super(parent && parent.to_s)
  end

  def set_backtrace backtrace
    bt = backtrace
    if parent
      bt = parent.backtrace
      bt << "<<< parent fiber: #{parent.class.name}: #{parent}"
      bt.concat backtrace
    end
    super bt
  end
end
