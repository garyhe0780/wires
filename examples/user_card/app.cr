require "kemal"
require "../../src/crystal_live"

class UserCard < CrystalLive::LiveComponent
  STATUSES = ["online", "away", "busy", "offline"]

  def initialize(session_id : String, @user_id : Int32, @name : String)
    super("user-card-#{@user_id}", session_id)

    spawn { update_loop }
  end

  def render : String
    <<-HTML
    <article class="user-card">
      <h2>#{@name}</h2>
      <p>Status: <strong>#{@status}</strong></p>
      <p>Last seen: #{@last_seen.to_s("%H:%M:%S")}</p>
    </article>
    HTML
  end

  private def update_loop
    loop do
      sleep 3.seconds
      @status = STATUSES.sample
      @last_seen = Time.utc
      push_update
    end
  end

  @status : String = "online"
  @last_seen : Time = Time.utc
end

CrystalLive::KemalExtensions.serve_static
CrystalLive::KemalExtensions.setup_live_ws

USERS = {
  42 => "Alice Chen",
  57 => "Bob Martinez",
}

get "/" do |context|
  session_id = CrystalLive::KemalExtensions.ensure_session_id(context)
  cards = USERS.map do |id, name|
    UserCard.new(session_id, id, name).marker_html
  end.join("\n")

  <<-HTML
  <!DOCTYPE html>
  <html>
  <head>
    <meta charset="utf-8">
    <title>Crystal Live — User Cards</title>
    <script src="/crystal-live.js"></script>
  </head>
  <body>
    <h1>Live User Cards</h1>
    #{cards}
  </body>
  </html>
  HTML
end

Kemal.run
