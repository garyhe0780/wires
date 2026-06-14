require "./spec_helper"

class RegistryWidget < CrystalLive::LiveComponent
  def initialize(session_id : String)
    super("registry-widget", session_id)
  end

  def render : String
    "ok"
  end
end

describe CrystalLive::Config do
  it "allows global configuration" do
    CrystalLive.configure do |config|
      config.ws_path = "/ws/live"
      config.session_cookie = "app_session"
    end

    CrystalLive.config.ws_path.should eq("/ws/live")
    CrystalLive.config.session_cookie.should eq("app_session")
  end

  it "can be reset for isolated tests" do
    CrystalLive.configure { |config| config.ws_path = "/custom" }
    CrystalLive.reset_config!
    CrystalLive.config.ws_path.should eq("/live")
  end
end

describe CrystalLive::LiveRegistry do
  it "registers and unregisters components for events" do
    component = RegistryWidget.new("session-a")
    component.marker_html

    CrystalLive::LiveRegistry.registered?("session-a", "registry-widget").should be_true

    CrystalLive::LiveRegistry.unregister("session-a", "registry-widget")
    CrystalLive::LiveRegistry.registered?("session-a", "registry-widget").should be_false
  end
end
