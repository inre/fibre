module Fibre::Synchrony

  refine Array do
    def sync
      res = Fiber.scope { collect(&:sync) }
      res.collect(&:result)
    end
  end

  #<<<
end
