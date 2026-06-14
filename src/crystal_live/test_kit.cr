module CrystalLive
  module TestKit
    SESSION_ID = "test-session"

    def self.session_id : String
      SESSION_ID
    end

    def self.capture_patches(session_id : String, component_id : String, &block)
      patches = [] of String
      connection = Connection.new(->(patch : String) { patches << patch })
      LiveManager.subscribe_connection(session_id, component_id, connection)

      yield patches
    end

    def self.render(component : LiveComponent) : String
      component.marker_html
    end

    def self.dispatch(
      component : LiveComponent,
      event_name : String,
      payload : Hash(String, String)? = nil,
    )
      payload ||= {} of String => String
      if CrystalLive.config.csrf_protection
        payload["_csrf"] = Csrf.token_for(component.session_id)
      end

      LiveEventRegistry.dispatch(component.session_id, component.id, event_name, payload)
    end
  end
end
