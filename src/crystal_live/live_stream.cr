require "json"

module CrystalLive
  module LiveStream
    struct Subscription
      getter session_id : String
      getter component_ids : Set(String)
      getter channel : Channel(String)

      def initialize(@session_id : String, @component_ids : Set(String), @channel : Channel(String))
      end

      def matches?(session_id : String, component_id : String) : Bool
        @session_id == session_id && @component_ids.includes?(component_id)
      end
    end

    @@subscriptions = [] of Subscription

    def self.register(session_id : String, component_ids : Array(String)) : Channel(String)
      channel = Channel(String).new
      ids = component_ids.to_set
      @@subscriptions << Subscription.new(session_id, ids, channel)
      channel
    end

    def self.unregister(channel : Channel(String))
      @@subscriptions.reject! { |subscription| subscription.channel == channel }
    end

    def self.broadcast(session_id : String, component_id : String, patch_html : String)
      payload = LivePatch.to_sse_data(component_id, patch_html)

      @@subscriptions.each do |subscription|
        next unless subscription.matches?(session_id, component_id)

        begin
          subscription.channel.send(payload)
        rescue Channel::ClosedError
          unregister(subscription.channel)
        end
      end
    end

    def self.subscription_count : Int32
      @@subscriptions.size
    end

    def self.clear
      @@subscriptions.each(&.channel.close)
      @@subscriptions.clear
    end
  end
end
