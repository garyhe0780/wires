require "./spec_helper"

class ErrorWidget < CrystalLive::LiveComponent
  property error_message : String? = nil

  def initialize(session_id : String)
    super("error-widget", session_id)
  end

  def handle_event(event_name : String, payload : Hash(String, String)? = nil)
    raise "boom" if event_name == "fail"
  end

  def on_error(error : Exception, event_name : String? = nil)
    @error_message = error.message
    push_update
  end

  def render : String
    if message = @error_message
      "<p class=\"error\">#{message}</p>"
    else
      "<button type=\"button\"#{live_event("fail")}>Trigger error</button>"
    end
  end
end

describe CrystalLive::LiveEventRegistry do
  it "routes event failures to on_error" do
    widget = ErrorWidget.new(CrystalLive::TestKit.session_id)
    widget.marker_html

    CrystalLive::TestKit.capture_patches(CrystalLive::TestKit.session_id, "error-widget") do |patches|
      CrystalLive::TestKit.dispatch(widget, "fail")

      widget.error_message.should eq("boom")
      patches.size.should eq(1)
      patches.first.should contain("boom")
    end
  end
end

describe CrystalLive::LiveDebug do
  it "logs only when debug mode is enabled" do
    CrystalLive.configure { |config| config.debug = false }
    CrystalLive::LiveDebug.log_patch("s", "c", "patch")
  end
end
