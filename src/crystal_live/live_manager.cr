module CrystalLive
  struct Connection
    def initialize(@send_fn : Proc(String, Nil))
    end

    def self.from_websocket(ws : HTTP::WebSocket) : self
      new(->(message : String) { ws.send(message) })
    end

    def send(message : String)
      @send_fn.call(message)
    end
  end

  module LiveManager
    @@websocket_connections = {} of HTTP::WebSocket => Set(Connection)
    @@websocket_sessions = {} of HTTP::WebSocket => String
    @@session_socket_counts = {} of String => Int32

    def self.register_websocket(ws : HTTP::WebSocket, session_id : String)
      @@websocket_sessions[ws] = session_id
      @@session_socket_counts[session_id] = (@@session_socket_counts[session_id]? || 0) + 1
    end

    def self.session_for(ws : HTTP::WebSocket) : String?
      @@websocket_sessions[ws]?
    end

    def self.subscribe(session_id : String, component_id : String, ws : HTTP::WebSocket)
      connection = Connection.from_websocket(ws)
      LiveSession.subscribe(session_id, component_id, connection)
      (@@websocket_connections[ws] ||= Set(Connection).new) << connection
    end

    def self.subscribe_connection(session_id : String, component_id : String, connection : Connection)
      LiveSession.subscribe(session_id, component_id, connection)
    end

    def self.unsubscribe(ws : HTTP::WebSocket)
      session_id = @@websocket_sessions[ws]?

      @@websocket_connections[ws]?.try &.each do |connection|
        LiveSession.unsubscribe_connection(connection)
      end
      @@websocket_connections.delete(ws)
      @@websocket_sessions.delete(ws)

      return unless session_id

      remaining = (@@session_socket_counts[session_id]? || 1) - 1
      if remaining <= 0
        @@session_socket_counts.delete(session_id)
        LiveRegistry.disconnect_session(session_id)
        Csrf.clear_session(session_id)
      else
        @@session_socket_counts[session_id] = remaining
      end
    end

    def self.unsubscribe_connection(connection : Connection)
      LiveSession.unsubscribe_connection(connection)
    end

    def self.broadcast_patch(session_id : String, component_id : String, patch_html : String)
      LiveDebug.log_patch(session_id, component_id, patch_html)
      LiveSession.broadcast(session_id, component_id, patch_html)
      LiveStream.broadcast(session_id, component_id, patch_html)
    end

    def self.subscription_count(session_id : String, component_id : String) : Int32
      LiveSession.subscription_count(session_id, component_id)
    end

    def self.session_socket_count(session_id : String) : Int32
      @@session_socket_counts[session_id]? || 0
    end

    def self.clear
      LiveSession.clear
      LiveStream.clear
      @@websocket_connections.clear
      @@websocket_sessions.clear
      @@session_socket_counts.clear
    end
  end
end
