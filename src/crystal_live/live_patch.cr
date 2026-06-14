require "html"
require "json"

module CrystalLive
  module LivePatch
    def self.build(
      component_id : String,
      inner_html : String,
      target : String? = nil,
      morph : Bool = false,
      full_replace : Bool = true,
    ) : String
      attrs = [] of String
      if selector = target
        attrs << %(data-live-target="#{HTML.escape(selector)}")
      end
      if morph
        attrs << %(data-live-morph="true")
      end

      attr_string = attrs.empty? ? "" : " #{attrs.join(" ")}"
      body = if target || !full_replace
               inner_html
             else
               wrap_component(component_id, inner_html)
             end

      <<-HTML
      <template for="#{HTML.escape(component_id)}"#{attr_string}>
        #{body}
      </template>
      HTML
    end

    def self.wrap_component(component_id : String, inner_html : String) : String
      <<-HTML
      <div data-live-component="#{HTML.escape(component_id)}">
        <template shadowrootmode="open">
          <style>:host { display: block; }</style>
          #{inner_html}
        </template>
      </div>
      HTML
    end

    struct Parsed
      getter component_id : String
      getter html : String
      getter target : String?
      getter morph : Bool

      def initialize(@component_id : String, @html : String, @target : String? = nil, @morph : Bool = false)
      end
    end

    def self.parse_template(html : String) : Parsed?
      container = html.strip
      return unless container.starts_with?("<template")

      component_id = extract_attribute(container, "for")
      return unless component_id

      target = extract_attribute(container, "data-live-target")
      morph = extract_attribute(container, "data-live-morph") == "true"
      inner = extract_inner_html(container)

      Parsed.new(component_id, inner, target, morph)
    end

    def self.to_sse_data(component_id : String, patch_html : String) : String
      {
        component: component_id,
        html:      patch_html,
      }.to_json
    end

    private def self.extract_attribute(html : String, name : String) : String?
      pattern = "#{name}=\""
      start = html.index(pattern)
      return unless start

      start += pattern.size
      finish = html.index('"', start)
      return unless finish

      html[start...finish]
    end

    private def self.extract_inner_html(html : String) : String
      start = html.index(">")
      return "" unless start

      start += 1
      finish = html.rindex("</template>")
      return "" unless finish

      html[start...finish]
    end
  end
end
