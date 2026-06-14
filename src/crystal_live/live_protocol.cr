require "json"

module CrystalLive
  module LiveProtocol
    SUBSCRIBE_PREFIX = "subscribe:"
    DETACH_PREFIX    = "detach:"
    EVENT_PREFIX     = "event:"
    PING             = "ping"
    PONG             = "pong"

    struct EventMessage
      getter component_id : String
      getter event_name : String
      getter payload : Hash(String, String)

      def initialize(@component_id : String, @event_name : String, @payload : Hash(String, String))
      end
    end

    def self.parse_event(message : String) : EventMessage?
      return unless message.starts_with?(EVENT_PREFIX)

      rest = message[EVENT_PREFIX.size..]
      parts = rest.split(":", limit: 3)
      return if parts.size < 2

      component_id = parts[0]
      event_name = parts[1]
      payload = parse_payload(parts[2]?)

      EventMessage.new(component_id, event_name, payload)
    end

    def self.parse_payload(raw : String?) : Hash(String, String)
      payload = {} of String => String
      return payload unless raw

      begin
        json = JSON.parse(raw)
        if hash = json.as_h?
          hash.each do |key, value|
            payload[key.to_s] = value.as_s? || value.to_s
          end
        end
      rescue JSON::ParseException
      end

      payload
    end
  end
end
