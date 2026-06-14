require "html"

module CrystalLive
  class LiveLayout
    def initialize(
      @title : String,
      @session_id : String,
      @nav : String = "",
      @brand : String = "Crystal Live",
    )
    end

    def render(body : String) : String
      shell = <<-HTML
      <header class="live-layout">
        <p class="live-layout__brand">#{HTML.escape(@brand)}</p>
        <p class="live-layout__title">#{HTML.escape(@title)}</p>
      </header>
      #{body}
      HTML

      if @nav.empty?
        KemalExtensions.page_html(@title, shell, session_id: @session_id)
      else
        KemalExtensions.navigation_shell(@title, @nav, shell, @session_id)
      end
    end

    def render_page(context : HTTP::Server::Context, body : String) : String
      shell = <<-HTML
      <header class="live-layout">
        <p class="live-layout__brand">#{HTML.escape(@brand)}</p>
        <p class="live-layout__title">#{HTML.escape(@title)}</p>
      </header>
      #{body}
      HTML

      LiveNavigation.render(context, @title, @nav, shell, @session_id)
    end
  end
end
