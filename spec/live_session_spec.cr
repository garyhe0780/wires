require "./spec_helper"

describe CrystalLive::LiveSession do
  it "scopes broadcasts to session and component" do
    sent = [] of String
    connection = CrystalLive::Connection.new(->(message : String) { sent << message })

    CrystalLive::LiveSession.subscribe("user-1", "clock", connection)
    CrystalLive::LiveSession.broadcast("user-2", "clock", "hidden")
    CrystalLive::LiveSession.broadcast("user-1", "clock", "visible")

    sent.should eq(["visible"])
  end

  it "builds stable subscription keys" do
    CrystalLive::LiveSession.subscription_key("abc", "widget").should eq("abc:widget")
  end
end

describe CrystalLive::KemalExtensions do
  it "parses session cookie from request headers" do
    request = HTTP::Request.new("GET", "/")
    request.headers["Cookie"] = "crystal_live_session=abc123; other=value"
    context = HTTP::Server::Context.new(request, HTTP::Server::Response.new(IO::Memory.new))

    CrystalLive::KemalExtensions.session_id_from_request(context).should eq("abc123")
  end

  it "issues a session cookie when missing" do
    request = HTTP::Request.new("GET", "/")
    context = HTTP::Server::Context.new(request, HTTP::Server::Response.new(IO::Memory.new))

    session_id = CrystalLive::KemalExtensions.ensure_session_id(context)

    session_id.should_not be_empty
    context.response.headers["Set-Cookie"].should contain("crystal_live_session=#{session_id}")
  end
end
