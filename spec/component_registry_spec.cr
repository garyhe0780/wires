require "./spec_helper"

class RegistryClock < CrystalLive::LiveComponent
  def initialize(session_id : String)
    super("registry-clock", session_id)
  end

  def render : String
    "tick"
  end
end

describe CrystalLive::ComponentRegistry do
  it "renders marker html for registered components" do
    CrystalLive::ComponentRegistry.register(:clock) do |session_id|
      RegistryClock.new(session_id)
    end

    html = CrystalLive::ComponentRegistry.render(:clock, "session-1")

    html.should contain("<!--?marker name=\"registry-clock\"?-->")
    html.should contain("tick")
  end

  it "raises when a component is not registered" do
    expect_raises KeyError, "Live component missing is not registered" do
      CrystalLive::ComponentRegistry.render(:missing, "session-1")
    end
  end

  it "tracks registered component names" do
    CrystalLive::ComponentRegistry.register(:widget) do |session_id|
      RegistryClock.new(session_id)
    end

    CrystalLive::ComponentRegistry.registered?(:widget).should be_true
    CrystalLive::ComponentRegistry.registered?(:missing).should be_false
  end
end

describe CrystalLive::KemalExtensions do
  it "builds a live page shell with the polyfill script" do
    html = CrystalLive::KemalExtensions.page_html("Dashboard", "<main>body</main>")

    html.should contain("<title>Dashboard</title>")
    html.should contain("<script>window.CrystalLiveConfig=")
    html.should contain("<script src=\"/crystal-live.js\"></script>")
    html.should contain("<main>body</main>")
  end
end
