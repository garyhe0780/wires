require "html"
require "kemal"
require "../../src/crystal_live"

class SearchBox < CrystalLive::LiveComponent
  def initialize(session_id : String)
    super("search-box", session_id)
    @query = ""
    @status = "Type to search"
  end

  def handle_event(event_name : String, payload : Hash(String, String)? = nil)
    return unless event_name == "input"

    @query = payload.try(&.["value"]?) || ""
    @status = @query.empty? ? "Type to search" : "Filtering for \"#{@query}\"..."
    push_fragment(".status", %(<p class="status">#{HTML.escape(@status)}</p>), morph: true)
  end

  def render : String
    <<-HTML
    <section class="search-box">
      <label>
        Search
        <input type="search" name="query" value="#{HTML.escape(@query)}"#{live_input("query")}>
      </label>
      <p class="status">#{HTML.escape(@status)}</p>
    </section>
    HTML
  end
end

CrystalLive::KemalExtensions.mount!

get "/" do |context|
  session_id = CrystalLive::KemalExtensions.ensure_session_id(context)
  search = SearchBox.new(session_id)
  CrystalLive::KemalExtensions.page_html("Targeted Updates", search.marker_html)
end

Kemal.run
