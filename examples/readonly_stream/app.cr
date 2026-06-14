require "kemal"
require "../../src/crystal_live"

class ReadonlyClock < CrystalLive::LiveComponent
  def initialize(session_id : String)
    super("readonly-clock", session_id, readonly: true)

    spawn do
      loop do
        sleep 1.seconds
        push_update
      end
    end
  end

  def render : String
    <<-HTML
    <section class="clock">
      <h2>HTTP Stream Clock</h2>
      <p class="time">#{Time.utc.to_s("%H:%M:%S")} UTC</p>
      <small>Updates via Server-Sent Events (read-only transport)</small>
    </section>
    HTML
  end
end

CrystalLive::KemalExtensions.mount!

get "/" do |context|
  session_id = CrystalLive::KemalExtensions.ensure_session_id(context)
  clock = ReadonlyClock.new(session_id)
  CrystalLive::KemalExtensions.page_html("Readonly Stream", clock.marker_html)
end

Kemal.run
