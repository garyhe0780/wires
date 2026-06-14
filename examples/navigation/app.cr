require "kemal"
require "../../src/crystal_live"

abstract class PageWidget < CrystalLive::LiveComponent
  @running = false

  def on_disconnect
    @running = false
  end

  protected def start_updates(&block : ->)
    @running = true
    spawn do
      while @running
        block.call
        sleep 1.seconds
      end
    end
  end
end

class HomeWidget < PageWidget
  def initialize(session_id : String)
    super("home-widget", session_id)
    @visits = 1
    start_updates { push_update }
  end

  def render : String
    <<-HTML
    <section>
      <h2>Home</h2>
      <p>Welcome! Page refreshes: #{@visits}</p>
    </section>
    HTML
  end

  def push_update
    @visits += 1
    super
  end

  @visits : Int32
end

class StatsWidget < PageWidget
  def initialize(session_id : String)
    super("stats-widget", session_id)
    @value = Random.rand(1..100)
    start_updates do
      @value = Random.rand(1..100)
      push_update
    end
  end

  def render : String
    <<-HTML
    <section>
      <h2>Stats</h2>
      <p class="metric">Live metric: #{@value}</p>
    </section>
    HTML
  end

  @value : Int32
end

class SettingsWidget < CrystalLive::LiveComponent
  def initialize(session_id : String)
    super("settings-widget", session_id)
  end

  def render : String
    <<-HTML
    <section>
      <h2>Settings</h2>
      <p>Navigation swaps the main region without a full page reload.</p>
      <p>WebSocket stays connected; old components receive <code>detach:</code> cleanup.</p>
    </section>
    HTML
  end
end

CrystalLive::KemalExtensions.mount!

def nav_for(active : String) : String
  CrystalLive::LiveNavigation.nav(
    CrystalLive::LiveNavigation.link("/", "Home", active == "home") +
    CrystalLive::LiveNavigation.link("/stats", "Stats", active == "stats") +
    CrystalLive::LiveNavigation.link("/settings", "Settings", active == "settings")
  )
end

get "/" do |context|
  session_id = CrystalLive::KemalExtensions.ensure_session_id(context)
  content = HomeWidget.new(session_id).marker_html
  CrystalLive::LiveNavigation.render(context, "Home", nav_for("home"), content, session_id)
end

get "/stats" do |context|
  session_id = CrystalLive::KemalExtensions.ensure_session_id(context)
  content = StatsWidget.new(session_id).marker_html
  CrystalLive::LiveNavigation.render(context, "Stats", nav_for("stats"), content, session_id)
end

get "/settings" do |context|
  session_id = CrystalLive::KemalExtensions.ensure_session_id(context)
  content = SettingsWidget.new(session_id).marker_html
  CrystalLive::LiveNavigation.render(context, "Settings", nav_for("settings"), content, session_id)
end

Kemal.run
