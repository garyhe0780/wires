require "html"
require "kemal"
require "../../src/crystal_live"

class ContactForm < CrystalLive::LiveForm
  def initialize(session_id : String)
    super("contact-form", session_id)
  end

  def submitted(fields : Hash(String, String))
    @confirmation = "Thanks #{fields["name"]? || "friend"}! We'll reply to #{fields["email"]? || "you"}."
  end

  def render : String
    if confirmation = @confirmation
      return %(<p class="confirmation">#{HTML.escape(confirmation)}</p>)
    end

    form_open +
      text_field("name", "Name") +
      text_field("email", "Email", "email") +
      submit_button("Send message") +
      form_close
  end

  @confirmation : String? = nil
end

CrystalLive::KemalExtensions.mount!

get "/" do |context|
  session_id = CrystalLive::KemalExtensions.ensure_session_id(context)
  form = ContactForm.new(session_id)
  CrystalLive::KemalExtensions.page_html("Contact Form", form.marker_html)
end

Kemal.run
