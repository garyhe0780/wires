require "html"
require "json"
require "kemal"

module CrystalLive
  module KemalExtensions
    def self.mount!(
      static_folder : String? = nil,
      ws_path : String? = nil,
      stream_path : String? | ::Nil = nil,
    )
      cfg = CrystalLive.config
      folder = static_folder || cfg.static_folder
      websocket_path = ws_path || cfg.ws_path
      stream = stream_path.nil? ? cfg.stream_path : stream_path

      serve_static(folder)
      setup_live_ws(websocket_path)
      setup_live_stream(stream) if stream
    end

    def self.serve_static(folder : String? = nil)
      public_folder folder || CrystalLive.config.static_folder
    end

    def self.client_config_json(session_id : String? = nil) : String
      cfg = CrystalLive.config
      csrf_token = session_id && cfg.csrf_protection ? Csrf.token_for(session_id) : nil

      {
        wsPath:              cfg.ws_path,
        streamPath:          cfg.stream_path,
        debug:               cfg.debug,
        csrfToken:           csrf_token,
        heartbeatIntervalMs: cfg.heartbeat_interval_ms,
        heartbeatTimeoutMs:  cfg.heartbeat_timeout_ms,
        reconnectDelayMs:    cfg.reconnect_delay_ms,
        reconnectMaxDelayMs: cfg.reconnect_max_delay_ms,
        navigationEnabled:   cfg.navigation_enabled,
        mainSelector:        cfg.main_selector,
      }.to_json
    end

    def self.navigation_shell(
      title : String,
      nav : String,
      main_content : String,
      session_id : String,
    ) : String
      body = <<-HTML
      #{nav}
      #{LiveNavigation.main(main_content)}
      HTML

      page_html(title, body, session_id: session_id)
    end

    def self.page_html(
      title : String,
      body : String,
      session_id : String? = nil,
      script : String? = nil,
      include_config : Bool = true,
    ) : String
      cfg = CrystalLive.config
      script_path = script || cfg.script_path
      config_tag = include_config ? "<script>window.CrystalLiveConfig=#{client_config_json(session_id)};</script>\n" : ""

      <<-HTML
      <!DOCTYPE html>
      <html lang="en">
      <head>
        <meta charset="utf-8">
        <meta name="viewport" content="width=device-width, initial-scale=1">
        <title>#{HTML.escape(title)}</title>
        #{config_tag}<script src="#{HTML.escape(script_path)}"></script>
      </head>
      <body>
        #{body}
      </body>
      </html>
      HTML
    end

    def self.parse_cookies(header : String?) : Hash(String, String)
      cookies = {} of String => String
      return cookies unless header

      header.split(";").each do |part|
        key, _, value = part.strip.partition("=")
        next if key.empty?

        cookies[key] = value
      end

      cookies
    end

    def self.session_id_from_request(context : HTTP::Server::Context) : String?
      parse_cookies(context.request.headers["Cookie"]?)[CrystalLive.config.session_cookie]?
    end

    def self.ensure_session_id(context : HTTP::Server::Context) : String
      session_id = session_id_from_request(context)
      return session_id if session_id

      session_id = Random::Secure.hex(16)
      set_session_cookie(context, session_id)
      session_id
    end

    def self.set_session_cookie(context : HTTP::Server::Context, session_id : String)
      cookie = CrystalLive.config.session_cookie
      context.response.headers["Set-Cookie"] =
        "#{cookie}=#{session_id}; Path=/; HttpOnly; SameSite=Lax"
    end

    def self.handle_ws_message(session_id : String, socket : HTTP::WebSocket, message : String)
      LiveDebug.log_ws_message(session_id, message)

      case message
      when LiveProtocol::PING
        socket.send(LiveProtocol::PONG)
      when .starts_with?(LiveProtocol::SUBSCRIBE_PREFIX)
        component_id = message[LiveProtocol::SUBSCRIBE_PREFIX.size..]
        LiveManager.subscribe(session_id, component_id, socket) unless component_id.empty?
      when .starts_with?(LiveProtocol::DETACH_PREFIX)
        component_id = message[LiveProtocol::DETACH_PREFIX.size..]
        LiveRegistry.detach(session_id, component_id) unless component_id.empty?
      else
        if event = LiveProtocol.parse_event(message)
          LiveEventRegistry.dispatch(session_id, event.component_id, event.event_name, event.payload)
        end
      end
    end

    def self.setup_live_stream(path : String? = nil)
      stream_path = path || CrystalLive.config.stream_path
      return unless stream_path

      get stream_path do |context|
        session_id = ensure_session_id(context)
        components = parse_stream_components(context.params.query["components"]?)

        context.response.content_type = "text/event-stream"
        context.response.headers["Cache-Control"] = "no-cache"
        context.response.headers["Connection"] = "keep-alive"

        channel = LiveStream.register(session_id, components)
        output = context.response

        begin
          output.print ": connected\n\n"
          output.flush

          loop do
            payload = channel.receive
            output.print "data: "
            output.print(payload)
            output.print "\n\n"
            output.flush
          end
        rescue IO::Error | Channel::ClosedError
        ensure
          LiveStream.unregister(channel)
          channel.close
        end
      end
    end

    def self.parse_stream_components(raw : String?) : Array(String)
      return [] of String unless raw

      raw.split(",").map(&.strip).reject(&.empty?)
    end

    def self.setup_live_ws(path : String? = nil)
      ws_path = path || CrystalLive.config.ws_path

      ws ws_path do |socket, context|
        session_id = session_id_from_request(context)
        unless session_id
          session_id = Random::Secure.hex(16)
        end

        LiveManager.register_websocket(socket, session_id)

        socket.on_message do |message|
          handle_ws_message(session_id, socket, message)
        end

        socket.on_close do
          LiveManager.unsubscribe(socket)
        end
      end
    end
  end
end
