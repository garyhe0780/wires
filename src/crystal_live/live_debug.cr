module CrystalLive
  module LiveDebug
    def self.log_patch(session_id : String, component_id : String, patch_html : String)
      return unless CrystalLive.config.debug

      STDERR.puts "[crystal-live] patch session=#{session_id} component=#{component_id} bytes=#{patch_html.size}"
    end

    def self.log_event(
      session_id : String,
      component_id : String,
      event_name : String,
      payload : Hash(String, String)?,
    )
      return unless CrystalLive.config.debug

      payload_text = payload ? payload.inspect : "{}"
      STDERR.puts "[crystal-live] event session=#{session_id} component=#{component_id} name=#{event_name} payload=#{payload_text}"
    end

    def self.log_ws_message(session_id : String, message : String)
      return unless CrystalLive.config.debug

      STDERR.puts "[crystal-live] ws session=#{session_id} message=#{message}"
    end

    def self.log_error(
      session_id : String,
      component_id : String,
      event_name : String?,
      error : Exception,
    )
      return unless CrystalLive.config.debug

      event_label = event_name || "unknown"
      STDERR.puts "[crystal-live] error session=#{session_id} component=#{component_id} event=#{event_label} #{error.class}: #{error.message}"
    end
  end
end
