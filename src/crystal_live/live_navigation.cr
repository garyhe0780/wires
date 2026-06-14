require "html"

module CrystalLive
  module LiveNavigation
    NAVIGATE_ATTR = "data-live-navigate"
    MAIN_ATTR       = "data-live-main"
    NAV_HEADER      = "Crystal-Live-Navigation"
    TITLE_HEADER    = "Crystal-Live-Title"

    def self.navigation_request?(context : HTTP::Server::Context) : Bool
      context.request.headers[NAV_HEADER]? == "true"
    end

    def self.link(href : String, label : String, active : Bool = false) : String
      classes = active ? "live-nav__link is-active" : "live-nav__link"
      %(<a href="#{HTML.escape(href)}" class="#{classes}" #{NAVIGATE_ATTR}>#{HTML.escape(label)}</a>)
    end

    def self.nav(links : String) : String
      %(<nav class="live-nav" data-live-nav>#{links}</nav>)
    end

    def self.main(content : String) : String
      %(<div #{MAIN_ATTR}>#{content}</div>)
    end

    def self.fragment(main_content : String) : String
      main_content
    end

    def self.render(
      context : HTTP::Server::Context,
      title : String,
      nav : String,
      main_content : String,
      session_id : String,
    ) : String
      if navigation_request?(context)
        context.response.headers[TITLE_HEADER] = title
        fragment(main_content)
      else
        KemalExtensions.navigation_shell(title, nav, main_content, session_id)
      end
    end
  end
end
