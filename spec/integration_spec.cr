require "./spec_helper"

class IntegrationClock < CrystalLive::LiveComponent
  property ticks = 0

  def initialize(session_id : String)
    super("integration-clock", session_id)
  end

  def handle_event(event_name : String, payload : Hash(String, String)? = nil)
    return unless event_name == "tick"

    @ticks += 1
    push_fragment(".ticks", "<span class=\"ticks\">#{@ticks}</span>", morph: true)
  end

  def render : String
    "<span class=\"ticks\">#{@ticks}</span>"
  end
end

describe "Crystal Live integration" do
  it "registers, subscribes, handles events, and broadcasts targeted patches" do
    patches = [] of String
    connection = CrystalLive::Connection.new(->(message : String) { patches << message })

    clock = IntegrationClock.new("session-1")
    clock.marker_html

    CrystalLive::LiveManager.subscribe_connection("session-1", "integration-clock", connection)
    CrystalLive::LiveEventRegistry.dispatch("session-1", "integration-clock", "tick")

    clock.ticks.should eq(1)
    patches.size.should eq(1)
    patches.first.should contain("data-live-target=\".ticks\"")
    patches.first.should contain("data-live-morph=\"true\"")
  end

  it "accepts subscribe protocol messages via LiveManager" do
    connection = CrystalLive::Connection.new(->(_message : String) { })
    CrystalLive::LiveManager.subscribe_connection("session-1", "integration-clock", connection)
    CrystalLive::LiveManager.subscription_count("session-1", "integration-clock").should eq(1)
  end

  it "delivers readonly patches over SSE and interactive patches over websocket" do
    sse = [] of String
    ws_patches = [] of String

    sse_channel = CrystalLive::LiveStream.register("session-1", ["readonly-clock"])
    ws = CrystalLive::Connection.new(->(message : String) { ws_patches << message })

    spawn do
      2.times do
        begin
          sse << sse_channel.receive
        rescue Channel::ClosedError
          break
        end
      end
    end

    CrystalLive::LiveManager.subscribe_connection("session-1", "interactive-clock", ws)

    CrystalLive::LiveManager.broadcast_patch("session-1", "readonly-clock", "<template for=\"readonly-clock\"></template>")
    CrystalLive::LiveManager.broadcast_patch("session-1", "interactive-clock", "<template for=\"interactive-clock\"></template>")

    sleep 20.milliseconds

    sse.size.should eq(1)
    sse.first.should contain("readonly-clock")
    ws_patches.size.should eq(1)
    ws_patches.first.should contain("interactive-clock")
  end

  it "embeds runtime config in page_html" do
    CrystalLive.configure do |config|
      config.ws_path = "/custom-live"
    end

    html = CrystalLive::KemalExtensions.page_html("App", "<main></main>", session_id: "session-1")
    html.should contain("CrystalLiveConfig")
    html.should contain("/custom-live")
  end
end
