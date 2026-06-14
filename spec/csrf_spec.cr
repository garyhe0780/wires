require "./spec_helper"

class SecureWidget < CrystalLive::LiveComponent
  property handled = false

  def initialize(session_id : String)
    super("secure-widget", session_id)
  end

  def handle_event(event_name : String, payload : Hash(String, String)? = nil)
    @handled = true
  end

  def render : String
    "secure"
  end
end

describe CrystalLive::Csrf do
  it "issues and validates session tokens when protection is enabled" do
    CrystalLive.configure { |config| config.csrf_protection = true }

    token = CrystalLive::Csrf.token_for("session-a")
    CrystalLive::Csrf.valid?("session-a", token).should be_true
    CrystalLive::Csrf.valid?("session-a", "invalid").should be_false
  end

  it "skips validation when protection is disabled" do
    CrystalLive.configure { |config| config.csrf_protection = false }
    CrystalLive::Csrf.valid?("session-a", nil).should be_true
  end
end

describe CrystalLive::LiveEventRegistry do
  it "rejects events with invalid csrf tokens when protection is enabled" do
    CrystalLive.configure { |config| config.csrf_protection = true }

    widget = SecureWidget.new("session-a")
    widget.marker_html
    token = CrystalLive::Csrf.token_for("session-a")

    CrystalLive::LiveEventRegistry.dispatch("session-a", "secure-widget", "click", {"_csrf" => token})
    widget.handled.should be_true

    widget = SecureWidget.new("session-a")
    widget.marker_html
    CrystalLive::LiveEventRegistry.dispatch("session-a", "secure-widget", "click", {"_csrf" => "bad"})
    widget.handled.should be_false
  end
end
