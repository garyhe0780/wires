require "./spec_helper"

class DetachWidget < CrystalLive::LiveComponent
  property disconnected = false

  def initialize(session_id : String)
    super("detach-widget", session_id)
  end

  def on_disconnect
    @disconnected = true
  end

  def render : String
    "ok"
  end
end

describe CrystalLive::LiveNavigation do
  it "builds navigation links with data-live-navigate" do
    link = CrystalLive::LiveNavigation.link("/stats", "Stats", active: true)

    link.should contain("href=\"/stats\"")
    link.should contain("data-live-navigate")
    link.should contain("is-active")
  end

  it "wraps page content in a live main region" do
    CrystalLive::LiveNavigation.main("<p>Body</p>").should contain("data-live-main")
  end

  it "returns fragments for navigation requests" do
    request = HTTP::Request.new("GET", "/stats")
    request.headers["Crystal-Live-Navigation"] = "true"
    context = HTTP::Server::Context.new(request, HTTP::Server::Response.new(IO::Memory.new))

    html = CrystalLive::LiveNavigation.render(
      context,
      "Stats",
      CrystalLive::LiveNavigation.nav(""),
      "<p>Metrics</p>",
      "session-a",
    )

    html.should eq("<p>Metrics</p>")
    context.response.headers["Crystal-Live-Title"].should eq("Stats")
  end

  it "returns a full shell for normal requests" do
    request = HTTP::Request.new("GET", "/stats")
    context = HTTP::Server::Context.new(request, HTTP::Server::Response.new(IO::Memory.new))

    html = CrystalLive::LiveNavigation.render(
      context,
      "Stats",
      CrystalLive::LiveNavigation.link("/stats", "Stats", active: true),
      "<p>Metrics</p>",
      "session-a",
    )

    html.should contain("data-live-main")
    html.should contain("data-live-navigate")
    html.should contain("<p>Metrics</p>")
  end
end

describe CrystalLive::LiveRegistry do
  it "detaches components and calls on_disconnect" do
    widget = DetachWidget.new("session-a")
    widget.marker_html

    CrystalLive::LiveRegistry.detach("session-a", "detach-widget")

    widget.disconnected.should be_true
    CrystalLive::LiveRegistry.registered?("session-a", "detach-widget").should be_false
  end
end
