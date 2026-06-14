module CrystalLive
  module ComponentRegistry
    @@factories = {} of Symbol => (String -> LiveComponent)
    @@instances = [] of LiveComponent

    def self.register(name : Symbol, &factory : String -> LiveComponent)
      @@factories[name] = factory
    end

    def self.render(name : Symbol, session_id : String) : String
      factory = @@factories[name]?
      raise KeyError.new("Live component #{name} is not registered") unless factory

      component = factory.call(session_id)
      @@instances << component
      component.marker_html
    end

    def self.registered?(name : Symbol) : Bool
      @@factories.has_key?(name)
    end

    def self.clear
      @@factories.clear
      @@instances.clear
    end
  end
end
