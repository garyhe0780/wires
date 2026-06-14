require "./spec_helper"

class EventCounter < CrystalLive::LiveComponent
  property count = 0
  property last_event : String? = nil

  def initialize(session_id : String)
    super("event-counter", session_id)
  end

  def handle_event(event_name : String, payload : Hash(String, String)? = nil)
    @last_event = event_name
    case event_name
    when "increment" then @count += 1
    when "decrement" then @count -= 1
    end
  end

  def render : String
    "count=#{@count}"
  end
end

class TestContactForm < CrystalLive::LiveForm
  property submitted_fields : Hash(String, String)? = nil

  def initialize(session_id : String)
    super("contact-form", session_id)
  end

  def submitted(fields : Hash(String, String))
    @submitted_fields = fields
  end

  def render : String
    if fields = @submitted_fields
      "sent=#{fields["email"]}"
    else
      form_open + text_field("email", "Email") + form_close
    end
  end
end

describe CrystalLive::LiveProtocol do
  it "parses event messages with optional JSON payload" do
    parsed = CrystalLive::LiveProtocol.parse_event(
      "event:counter:increment:{\"field\":\"value\"}"
    )

    parsed.should_not be_nil
    parsed.not_nil!.component_id.should eq("counter")
    parsed.not_nil!.event_name.should eq("increment")
    parsed.not_nil!.payload["field"].should eq("value")
  end

  it "parses event messages without payload" do
    parsed = CrystalLive::LiveProtocol.parse_event("event:clock:tick")

    parsed.should_not be_nil
    parsed.not_nil!.event_name.should eq("tick")
    parsed.not_nil!.payload.should be_empty
  end

  it "returns nil for non-event messages" do
    CrystalLive::LiveProtocol.parse_event("subscribe:clock").should be_nil
  end

  it "defines heartbeat messages" do
    CrystalLive::LiveProtocol::PING.should eq("ping")
    CrystalLive::LiveProtocol::PONG.should eq("pong")
  end
end

describe CrystalLive::LiveEventRegistry do
  it "dispatches events to registered components" do
    component = EventCounter.new("session-a")
    component.marker_html
    component.count.should eq(0)

    CrystalLive::LiveEventRegistry.dispatch("session-a", "event-counter", "increment")

    component.count.should eq(1)
    component.last_event.should eq("increment")
  end

  it "ignores events for other sessions" do
    component = EventCounter.new("session-a")
    component.marker_html

    CrystalLive::LiveEventRegistry.dispatch("session-b", "event-counter", "increment")

    component.count.should eq(0)
  end
end

describe CrystalLive::LiveForm do
  it "tracks input events and submits accumulated fields" do
    form = TestContactForm.new("session-a")
    form.marker_html

    form.handle_event("input", {"field" => "email", "value" => "a@example.com"})
    form.fields["email"].should eq("a@example.com")

    form.handle_event("submit")
    form.submitted_fields.not_nil!["email"].should eq("a@example.com")
  end
end
