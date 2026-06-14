require "html"

module CrystalLive
  abstract class LiveForm < LiveComponent
    getter fields : Hash(String, String)

    def initialize(@id : String, @session_id : String)
      super(@id, @session_id)
      @fields = {} of String => String
    end

    def handle_event(event_name : String, payload : Hash(String, String)? = nil)
      payload ||= {} of String => String

      case event_name
      when "input"
        track_input(payload)
      when "submit"
        submitted(@fields.dup)
        push_update
      else
        super
      end
    end

    protected def track_input(payload : Hash(String, String))
      field = payload["field"]?
      return unless field

      value = payload["value"]? || ""
      @fields[field] = value
      changed(field, value)
    end

    protected def changed(field : String, value : String)
    end

    abstract def submitted(fields : Hash(String, String))

    protected def form_open : String
      %(<form data-live-form>)
    end

    protected def form_close : String
      %(</form>)
    end

    protected def text_field(name : String, label : String, type : String = "text") : String
      value = HTML.escape(@fields[name]? || "")
      field_name = HTML.escape(name)
      <<-HTML
      <label>
        #{HTML.escape(label)}
        <input type="#{HTML.escape(type)}" name="#{field_name}" value="#{value}"#{live_input(name)}>
      </label>
      HTML
    end

    protected def submit_button(label : String = "Submit") : String
      %(<button type="submit">#{HTML.escape(label)}</button>)
    end
  end
end
