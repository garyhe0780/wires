require "kemal"
require "../../src/crystal_live"

class DashboardClock < CrystalLive::LiveComponent
  def initialize(session_id : String)
    super("dashboard-clock", session_id)

    spawn do
      loop do
        sleep 1.seconds
        push_update
      end
    end
  end

  def render : String
    <<-HTML
    <section class="panel">
      <h2>Server Time</h2>
      <p class="metric">#{Time.utc.to_s("%H:%M:%S")}</p>
    </section>
    HTML
  end
end

class ActivityFeed < CrystalLive::LiveComponent
  MESSAGES = [
    "Deployment finished",
    "New signup from Tokyo",
    "Cache warmed",
    "Invoice paid",
    "Alert resolved",
  ]

  def initialize(session_id : String)
    super("activity-feed", session_id)

    spawn { update_loop }
  end

  def render : String
    <<-HTML
    <section class="panel">
      <h2>Activity</h2>
      <p>#{@message}</p>
      <small>Updated at #{@updated_at.to_s("%H:%M:%S")}</small>
    </section>
    HTML
  end

  private def update_loop
    loop do
      sleep 4.seconds
      @message = MESSAGES.sample
      @updated_at = Time.utc
      push_update
    end
  end

  @message : String = MESSAGES.first
  @updated_at : Time = Time.utc
end

class OnlineUsers < CrystalLive::LiveComponent
  def initialize(session_id : String)
    super("online-users", session_id)

    spawn { update_loop }
  end

  def render : String
    <<-HTML
    <section class="panel">
      <h2>Online Users</h2>
      <p class="metric">#{@count}</p>
    </section>
    HTML
  end

  private def update_loop
    loop do
      sleep 2.seconds
      @count = Random.rand(80..140)
      push_update
    end
  end

  @count : Int32 = 100
end

register_live_component :clock, DashboardClock
register_live_component :activity, ActivityFeed
register_live_component :users, OnlineUsers

CrystalLive::KemalExtensions.mount!

get "/" do |context|
  session_id = CrystalLive::KemalExtensions.ensure_session_id(context)
  body = <<-HTML
  <header>
    <h1>Live Dashboard</h1>
    <p>Three independent components, one WebSocket connection.</p>
  </header>
  <div class="grid">
    #{live_component :clock, session_id}
    #{live_component :users, session_id}
    #{live_component :activity, session_id}
  </div>
  HTML

  CrystalLive::KemalExtensions.page_html("Crystal Live Dashboard", body)
end

Kemal.run
