require "./spec_helper"

class FragmentWidget < CrystalLive::LiveComponent
  def initialize(session_id : String)
    super("fragment-widget", session_id)
  end

  def render : String
    "<span class=\"value\">1</span>"
  end
end

describe CrystalLive::LivePatch do
  it "builds full component replacement patches" do
    patch = CrystalLive::LivePatch.build("clock", "<p>12:00</p>")

    patch.should contain("<template for=\"clock\">")
    patch.should contain("data-live-component=\"clock\"")
    patch.should contain("<template shadowrootmode=\"open\">")
    patch.should contain("<p>12:00</p>")
  end

  it "builds targeted inner-shadow patches" do
    patch = CrystalLive::LivePatch.build(
      "search",
      "<span class=\"status\">Saving...</span>",
      target: ".status",
    )

    patch.should contain("data-live-target=\".status\"")
    patch.should contain("<span class=\"status\">Saving...</span>")
    patch.should_not contain("shadowrootmode")
  end

  it "adds morph hint for targeted patches" do
    patch = CrystalLive::LivePatch.build(
      "search",
      "<span class=\"status\">Saved</span>",
      target: ".status",
      morph: true,
    )

    patch.should contain("data-live-morph=\"true\"")
  end

  it "encodes SSE payloads as JSON" do
    json = CrystalLive::LivePatch.to_sse_data("clock", "<template for=\"clock\"></template>")
    parsed = JSON.parse(json).as_h

    parsed["component"].as_s.should eq("clock")
    parsed["html"].as_s.should contain("clock")
  end
end

describe CrystalLive::LiveStream do
  it "delivers patches to matching SSE subscriptions" do
    channel = CrystalLive::LiveStream.register("session-a", ["metrics"])
    received = [] of String

    spawn do
      begin
        received << channel.receive
      rescue Channel::ClosedError
      end
    end

    sleep 10.milliseconds
    CrystalLive::LiveStream.broadcast("session-a", "metrics", "<template for=\"metrics\"></template>")
    sleep 10.milliseconds

    received.size.should eq(1)
    received.first.should contain("metrics")
  end

  it "ignores broadcasts for unsubscribed components" do
    channel = CrystalLive::LiveStream.register("session-a", ["clock"])
    received = false

    spawn do
      begin
        channel.receive
        received = true
      rescue Channel::ClosedError
      end
    end

    CrystalLive::LiveStream.broadcast("session-a", "other", "patch")
    sleep 20.milliseconds

    received.should be_false
  end
end

describe CrystalLive::LiveComponent do
  it "supports targeted fragment updates" do
    sent = [] of String
    connection = CrystalLive::Connection.new(->(message : String) { sent << message })
    CrystalLive::LiveManager.subscribe_connection("session-a", "fragment-widget", connection)

    widget = FragmentWidget.new("session-a")
    widget.push_fragment(".value", "<span class=\"value\">2</span>", morph: true)

    sent.size.should eq(1)
    sent.first.should contain("data-live-target=\".value\"")
    sent.first.should contain("data-live-morph=\"true\"")
  end
end
