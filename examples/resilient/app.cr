require "kemal"
require "../../src/crystal_live"

class SafeCounter < CrystalLive::LiveComponent
  def initialize(session_id : String)
    super("safe-counter", session_id)
    @count = 0
  end

  def handle_event(event_name : String, payload : Hash(String, String)? = nil)
    @error = nil

    case event_name
    when "increment" then @count += 1
    when "decrement" then @count -= 1
    when "risky"     then raise "Calculation failed"
    end

    push_update
  end

  def on_error(error : Exception, event_name : String? = nil)
    @error = error.message
    push_update
  end

  def render : String
    if error = @error
      return <<-HTML
      <section class="counter error">
        <p class="error">Error: #{HTML.escape(error)}</p>
        <button type="button"#{live_event("increment")}>Reset (+1)</button>
      </section>
      HTML
    end

    <<-HTML
    <section class="counter">
      <p class="value">Count: #{@count}</p>
      <button type="button"#{live_event("decrement")}>−</button>
      <button type="button"#{live_event("increment")}>+</button>
      <button type="button"#{live_event("risky")}>Risky op</button>
    </section>
    HTML
  end

  @error : String? = nil
end

CrystalLive::KemalExtensions.mount!

get "/" do |context|
  session_id = CrystalLive::KemalExtensions.ensure_session_id(context)
  counter = SafeCounter.new(session_id)
  CrystalLive::KemalExtensions.page_html("Resilient Counter", counter.marker_html)
end

Kemal.run
