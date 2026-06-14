module CrystalLive
  # Unified component lifecycle for event dispatch and session teardown.
  module LiveRegistry
    def self.register(component : LiveComponent)
      LiveEventRegistry.register(component)
    end

    def self.unregister(session_id : String, component_id : String)
      LiveEventRegistry.unregister(session_id, component_id)
    end

    def self.registered?(session_id : String, component_id : String) : Bool
      LiveEventRegistry.registered?(session_id, component_id)
    end

    def self.disconnect_session(session_id : String)
      LiveEventRegistry.disconnect_session(session_id)
    end

    def self.detach(session_id : String, component_id : String)
      LiveEventRegistry.detach(session_id, component_id)
    end

    def self.clear
      LiveEventRegistry.clear
    end
  end
end
