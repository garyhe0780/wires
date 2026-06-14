module CrystalLive
  class Config
    property session_cookie : String = "crystal_live_session"
    property ws_path : String = "/live"
    property stream_path : String? = "/live/stream"
    property static_folder : String = "./static"
    property script_path : String = "/crystal-live.js"
    property heartbeat_interval_ms : Int32 = 30_000
    property heartbeat_timeout_ms : Int32 = 10_000
    property reconnect_delay_ms : Int32 = 1_000
    property reconnect_max_delay_ms : Int32 = 30_000
    property debug : Bool = false
    property csrf_protection : Bool = false
    property navigation_enabled : Bool = true
    property main_selector : String = "[data-live-main]"
  end

  @@config = Config.new

  def self.config : Config
    @@config
  end

  def self.configure(&block)
    yield @@config
  end

  def self.reset_config!
    @@config = Config.new
  end
end
