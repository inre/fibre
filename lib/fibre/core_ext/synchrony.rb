# Extend some classes to support synchronous operations
#
# Outline,
#
# use Fibre::Synchrony
# [req1, req2].sync
# { op1: req1, op2: req2 }.sync

module Fibre::Synchrony

  refine Array do
    def await
      res = Fiber.scope { collect(&:await) }
      res.collect(&:result)
    end

    def await!
      res = Fiber.scope do
        await_deep_scoped
      end

      res.each do |mock|
        node = self
        path = mock.path.split(/./)
        key = path.pop
        path.each { |k| node = node[k] }
        node[key] = mock.result
      end

      self
    end

    def await_deep_scoped(path: [])
      each_with_index do |item, index|
        # deeeep
        if item.is_a?(Array) || item.is_a?(Hash) # item.respond_to?(:deep_sync_scoped) not works in ruby 2.1.2
          item.await_deep_scoped(path: path + [index])
          next
        end

        item.await.tap do |mock|
          mock.path = path + [index]
        end
      end
    end
  end

  refine Hash do
    def await
      res = Fiber.scope { values.collect(&:await) }
      hash = {}
      res.each_with_index do |mock, index|
        hash[keys[index]] = mock.result
      end
      hash
    end

    def await!
      res = Fiber.scope do
        await_deep_scoped
      end

      res.each do |mock|
        node = self
        path = mock.path
        key = path.pop
        path.each { |k| node = node[k] }
        node[key] = mock.result
      end

      self
    end

    def await_deep_scoped(path: [])
      each do |key, item|
        # deeeep
        if item.is_a?(Array) || item.is_a?(Hash) # item.respond_to?(:deep_sync_scoped) not works in ruby 2.1.2
          item.await_deep_scoped(path: path + [key])
          next
        end
        item.await.tap do |mock|
          mock.path = path + [key]
        end
      end
    end
  end

  #<<<
end
