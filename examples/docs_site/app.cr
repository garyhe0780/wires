require "kemal"
require "../../src/crystal_live"

class DocsDemoClock < CrystalLive::LiveComponent
  def initialize(session_id : String)
    super("docs-demo-clock", session_id)

    spawn do
      loop do
        sleep 1.seconds
        push_update
      end
    end
  end

  def render : String
    <<-HTML
    <div class="demo-clock">#{Time.utc.to_s("%H:%M:%S")} UTC</div>
    HTML
  end
end

register_live_component :docs_demo_clock, DocsDemoClock

CrystalLive::KemalExtensions.serve_static("./static")
CrystalLive::KemalExtensions.setup_live_ws

DOCS_SITE = "./docs/site"

get "/" do |context|
  context.redirect "/docs/"
end

get "/docs/" do |context|
  session_id = CrystalLive::KemalExtensions.ensure_session_id(context)
  docs_html = File.read(File.join(DOCS_SITE, "index.html"))
  demo = live_component :docs_demo_clock, session_id
  docs_html.sub("<!-- LIVE_DEMO -->", demo)
end

get "/docs/guide" do |context|
  context.response.content_type = "text/markdown; charset=utf-8"
  File.read(File.join("docs", "guide.md"))
end

get "/docs/api" do |context|
  context.response.content_type = "text/markdown; charset=utf-8"
  File.read(File.join("docs", "api.md"))
end

get "/docs/:file" do |context|
  file = context.params.url["file"]
  path = File.join(DOCS_SITE, file)
  unless File.exists?(path)
    context.response.status_code = 404
    next "Not found"
  end

  context.response.content_type = case File.extname(path)
                                  when ".css"  then "text/css"
                                  when ".html" then "text/html"
                                  else               "application/octet-stream"
                                  end

  File.read(path)
end

Kemal.run
