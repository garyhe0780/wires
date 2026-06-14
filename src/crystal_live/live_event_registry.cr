module CrystalLive
  module LiveEventRegistry
    @@components = {} of String => LiveComponent
    @@session_components = {} of String => Set(String)

    def self.register(component : LiveComponent)
      key = LiveSession.subscription_key(component.session_id, component.id)
      @@components[key] = component
      (@@session_components[component.session_id] ||= Set(String).new) << component.id
      component.on_mount
    end

    def self.dispatch(session_id : String, component_id : String, event_name : String, payload : Hash(String, String)? = nil)
      return unless Csrf.valid?(session_id, payload.try(&.["_csrf"]?))

      key = LiveSession.subscription_key(session_id, component_id)
      component = @@components[key]?
      return unless component

      begin
        LiveDebug.log_event(session_id, component_id, event_name, payload)
        component.handle_event(event_name, payload)
      rescue ex : Exception
        LiveDebug.log_error(session_id, component_id, event_name, ex)
        component.on_error(ex, event_name)
      end
    end

    def self.registered?(session_id : String, component_id : String) : Bool
      key = LiveSession.subscription_key(session_id, component_id)
      @@components.has_key?(key)
    end

    def self.unregister(session_id : String, component_id : String)
      key = LiveSession.subscription_key(session_id, component_id)
      @@components.delete(key)
      @@session_components[session_id]?.try &.delete(component_id)
    end

    def self.detach(session_id : String, component_id : String)
      key = LiveSession.subscription_key(session_id, component_id)
      component = @@components[key]?
      component.try &.on_disconnect
      unregister(session_id, component_id)
    end

    def self.disconnect_session(session_id : String)
      component_ids = @@session_components.delete(session_id)
      return unless component_ids

      component_ids.each do |component_id|
        key = LiveSession.subscription_key(session_id, component_id)
        component = @@components.delete(key)
        component.try &.on_disconnect
      end
    end

    def self.clear
      @@components.clear
      @@session_components.clear
    end
  end
end
