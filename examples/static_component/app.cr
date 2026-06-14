require "kemal"
require "../../src/crystal_live"

class Greeting < CrystalLive::LiveComponent
  def initialize(session_id : String)
    super("greeting", session_id)
  end

  def render : String
    "<p>Hello from Crystal Live!</p>"
  end
end

CrystalLive::KemalExtensions.serve_static
CrystalLive::KemalExtensions.setup_live_ws

get "/" do |context|
  session_id = CrystalLive::KemalExtensions.ensure_session_id(context)
  greeting = Greeting.new(session_id)
  <<-HTML
  <!DOCTYPE html>
  <html>
  <head>
    <meta charset="utf-8">
    <title>Crystal Live — Static Component</title>
    <script src="/crystal-live.js"></script>
  </head>
  <body>
    <h1>Static Live Component</h1>
    #{greeting.marker_html}
  </body>
  </html>
  HTML
end

Kemal.run
