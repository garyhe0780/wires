require "./spec_helper"

class TestKitWidget < CrystalLive::LiveComponent
  def initialize(session_id : String)
    super("testkit-widget", session_id)
  end

  def handle_event(event_name : String, payload : Hash(String, String)? = nil)
    push_update if event_name == "refresh"
  end

  def render : String
    "rendered"
  end
end

describe CrystalLive::TestKit do
  it "provides a stable test session id" do
    CrystalLive::TestKit.session_id.should eq("test-session")
  end

  it "captures patches emitted by a component" do
    widget = TestKitWidget.new(CrystalLive::TestKit.session_id)
    CrystalLive::TestKit.render(widget)

    CrystalLive::TestKit.capture_patches(CrystalLive::TestKit.session_id, "testkit-widget") do |patches|
      CrystalLive::TestKit.dispatch(widget, "refresh")
      patches.size.should eq(1)
      patches.first.should contain("rendered")
    end
  end
end
