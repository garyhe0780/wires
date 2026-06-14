module CrystalLive
  module LiveSession
    @@subscriptions = {} of String => Set(Connection)

    def self.subscription_key(session_id : String, component_id : String) : String
      "#{session_id}:#{component_id}"
    end

    def self.subscribe(session_id : String, component_id : String, connection : Connection)
      key = subscription_key(session_id, component_id)
      (@@subscriptions[key] ||= Set(Connection).new) << connection
    end

    def self.unsubscribe_connection(connection : Connection)
      @@subscriptions.each_value(&.delete(connection))
    end

    def self.broadcast(session_id : String, component_id : String, patch_html : String)
      key = subscription_key(session_id, component_id)
      @@subscriptions[key]?.try &.each do |connection|
        connection.send(patch_html)
      end
    end

    def self.subscription_count(session_id : String, component_id : String) : Int32
      key = subscription_key(session_id, component_id)
      @@subscriptions[key]?.try &.size || 0
    end

    def self.clear
      @@subscriptions.clear
    end
  end
end
