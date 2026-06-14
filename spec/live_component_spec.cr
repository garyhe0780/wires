require "./spec_helper"

class TestComponent < CrystalLive::LiveComponent
  def initialize(@content : String = "content", session_id : String = "test-session")
    super("test-component", session_id)
  end

  def render : String
    @content
  end
end

describe CrystalLive::LiveComponent do
  it "renders a marker comment and shadow root wrapper" do
    component = TestComponent.new
    html = component.marker_html

    html.should contain("<!--?marker name=\"test-component\"?-->")
    html.should contain("data-live-component=\"test-component\"")
    html.should contain("<template shadowrootmode=\"open\">")
    html.should contain("content")
  end

  it "stream_patch broadcasts a template patch" do
    sent = [] of String
    connection = CrystalLive::Connection.new(->(message : String) { sent << message })
    CrystalLive::LiveManager.subscribe_connection("test-session", "test-component", connection)

    component = TestComponent.new("updated")
    component.stream_patch("updated")

    sent.size.should eq(1)
    sent.first.should contain("<template for=\"test-component\">")
    sent.first.should contain("updated")
    sent.first.should contain("<template shadowrootmode=\"open\">")
  end

  it "push_update re-renders and broadcasts" do
    sent = [] of String
    connection = CrystalLive::Connection.new(->(message : String) { sent << message })
    CrystalLive::LiveManager.subscribe_connection("test-session", "test-component", connection)

    component = TestComponent.new("live")
    component.push_update

    sent.size.should eq(1)
    sent.first.should contain("live")
  end
end
