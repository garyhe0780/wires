require "kemal"
require "../../src/crystal_live"

class Clock < CrystalLive::LiveComponent
  def initialize(session_id : String)
    super("clock", session_id)

    spawn do
      loop do
        sleep 1.seconds
        push_update
      end
    end
  end

  def render : String
    <<-HTML
    <div id="clock">#{Time.utc.to_s("%H:%M:%S")}</div>
    HTML
  end
end

CrystalLive::KemalExtensions.serve_static
CrystalLive::KemalExtensions.setup_live_ws

get "/" do |context|
  session_id = CrystalLive::KemalExtensions.ensure_session_id(context)
  clock = Clock.new(session_id)
  <<-HTML
  <!DOCTYPE html>
  <html>
  <head>
    <meta charset="utf-8">
    <title>Crystal Live — Clock</title>
    <script src="/crystal-live.js"></script>
  </head>
  <body>
    <h1>Crystal Live Clock</h1>
    #{clock.marker_html}
  </body>
  </html>
  HTML
end

Kemal.run
