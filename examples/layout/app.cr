require "kemal"
require "../../src/crystal_live"

CrystalLive.configure do |config|
  config.csrf_protection = true
end

class LayoutCounter < CrystalLive::LiveComponent
  property mounted = false
  property disconnected = false

  def initialize(session_id : String)
    super("layout-counter", session_id)
    @count = 0
  end

  def on_mount
    @mounted = true
  end

  def on_disconnect
    @disconnected = true
  end

  def handle_event(event_name : String, payload : Hash(String, String)? = nil)
    case event_name
    when "increment" then @count += 1
    when "decrement" then @count -= 1
    end
    push_update
  end

  def render : String
    <<-HTML
    <section class="counter">
      <p class="value">Count: #{@count}</p>
      <button type="button"#{live_event("decrement")}>−</button>
      <button type="button"#{live_event("increment")}>+</button>
    </section>
    HTML
  end

  @count : Int32
end

CrystalLive::KemalExtensions.mount!

get "/" do |context|
  session_id = CrystalLive::KemalExtensions.ensure_session_id(context)
  counter = LayoutCounter.new(session_id)
  layout = CrystalLive::LiveLayout.new("Secure Dashboard", session_id, brand: "Crystal Live")
  layout.render(counter.marker_html)
end

Kemal.run
