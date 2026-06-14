require "./spec_helper"

class LifecycleWidget < CrystalLive::LiveComponent
  property mounted = false
  property disconnected = false

  def initialize(session_id : String)
    super("lifecycle-widget", session_id)
  end

  def on_mount
    @mounted = true
  end

  def on_disconnect
    @disconnected = true
  end

  def render : String
    "ready"
  end
end

describe "component lifecycle" do
  it "calls on_mount when marker_html renders" do
    widget = LifecycleWidget.new("session-a")
    widget.mounted.should be_false

    widget.marker_html

    widget.mounted.should be_true
  end

  it "calls on_disconnect when a session is torn down" do
    widget = LifecycleWidget.new("session-a")
    widget.marker_html

    CrystalLive::LiveRegistry.disconnect_session("session-a")

    widget.disconnected.should be_true
    CrystalLive::LiveRegistry.registered?("session-a", "lifecycle-widget").should be_false
  end

  it "tracks active websocket counts per session" do
    socket_a = IO::Memory.new
    socket_b = IO::Memory.new
    ws_a = HTTP::WebSocket.new(socket_a)
    ws_b = HTTP::WebSocket.new(socket_b)

    CrystalLive::LiveManager.register_websocket(ws_a, "session-a")
    CrystalLive::LiveManager.register_websocket(ws_b, "session-a")
    CrystalLive::LiveManager.session_socket_count("session-a").should eq(2)

    CrystalLive::LiveManager.unsubscribe(ws_a)
    CrystalLive::LiveManager.session_socket_count("session-a").should eq(1)

    CrystalLive::LiveManager.unsubscribe(ws_b)
    CrystalLive::LiveManager.session_socket_count("session-a").should eq(0)
  end
end

describe CrystalLive::LiveLayout do
  it "wraps content in a shared layout shell" do
    html = CrystalLive::LiveLayout.new("Dashboard", "session-a").render("<p>Body</p>")

    html.should contain("live-layout__brand")
    html.should contain("Dashboard")
    html.should contain("<p>Body</p>")
    html.should contain("CrystalLiveConfig")
  end
end
