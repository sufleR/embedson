module Embedson
  module Model

    def embeds_one(name, options = {})
      MethodBuilder.new(self, name, options).embeds
    end

    def embedded_in(name, options = {})
      MethodBuilder.new(self, name, options).embedded
    end
  end
end
