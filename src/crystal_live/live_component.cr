require "html"

module CrystalLive
  abstract class LiveComponent
    getter id : String
    getter session_id : String
    getter readonly : Bool

    def initialize(@id : String, @session_id : String, @readonly : Bool = false)
    end

    abstract def render : String

    def handle_event(event_name : String, payload : Hash(String, String)? = nil)
    end

    def on_error(error : Exception, event_name : String? = nil)
    end

    def on_mount
    end

    def on_disconnect
    end

    def marker_html : String
      LiveRegistry.register(self)
      readonly_attr = @readonly ? " data-live-readonly" : ""
      <<-HTML
      <!--?marker name="#{@id}"?-->
      <div data-live-component="#{@id}"#{readonly_attr}>
        #{shadow_root_html(render)}
      </div>
      HTML
    end

    def push_update
      stream_patch(render)
    end

    def push_fragment(selector : String, html : String, morph : Bool = false)
      stream_patch(html, target: selector, morph: morph)
    end

    def stream_patch(html : String, target : String? = nil, morph : Bool = false)
      patch = LivePatch.build(@id, html, target: target, morph: morph)
      broadcast(patch)
    end

    protected def live_event(name : String) : String
      %( data-live-event="#{HTML.escape(name)}")
    end

    protected def live_input(field : String) : String
      %( data-live-input="#{HTML.escape(field)}")
    end

    private def broadcast(patch : String)
      LiveManager.broadcast_patch(@session_id, @id, patch)
    end

    private def shadow_root_html(inner_html : String) : String
      <<-HTML
      <template shadowrootmode="open">
        <style>:host { display: block; }</style>
        #{inner_html}
      </template>
      HTML
    end
  end
end
