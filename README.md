# Crystal Live

Server-driven live components for Crystal and Kemal. Inspired by Hotwire, Phoenix LiveView, and Laravel Livewire.

Crystal Live keeps all component state on the server, renders HTML with Declarative Shadow DOM for style isolation, and streams updates over WebSocket using the `<?marker?>` / `<template for>` patch protocol.

## Installation

Add to your `shard.yml`:

```yaml
dependencies:
  wires:
    github: your-org/wires
```

Then run `shards install`.

## Quick start

```crystal
require "kemal"
require "crystal_live"

class Clock < CrystalLive::LiveComponent
  def initialize(session_id : String)
    super("clock", session_id)
    spawn { loop { sleep 1.seconds; push_update } }
  end

  def render : String
    "<p>#{Time.utc.to_s("%H:%M:%S")}</p>"
  end
end

CrystalLive::KemalExtensions.mount!

get "/" do |context|
  session_id = CrystalLive::KemalExtensions.ensure_session_id(context)
  CrystalLive::KemalExtensions.page_html("Clock", Clock.new(session_id).marker_html)
end

Kemal.run
```

## Registry macros

```crystal
register_live_component :clock, Clock

get "/" do |context|
  session_id = CrystalLive::KemalExtensions.ensure_session_id(context)
  live_component :clock, session_id
end
```

## Configuration

```crystal
CrystalLive.configure do |config|
  config.ws_path = "/live"
  config.stream_path = "/live/stream"
  config.heartbeat_interval_ms = 30_000
end

CrystalLive::KemalExtensions.mount!
```

`page_html` embeds `window.CrystalLiveConfig` for the polyfill automatically.

Set `config.debug = true` to log WebSocket/SSE protocol activity on server and client.

See [CHANGELOG.md](CHANGELOG.md) for release history.

## Examples

```bash
crystal run examples/static_component/app.cr
crystal run examples/clock/app.cr
crystal run examples/user_card/app.cr
crystal run examples/dashboard/app.cr
crystal run examples/counter/app.cr
crystal run examples/contact_form/app.cr
crystal run examples/targeted/app.cr
crystal run examples/readonly_stream/app.cr
crystal run examples/resilient/app.cr
crystal run examples/layout/app.cr
crystal run examples/docs_site/app.cr
```

## Documentation

- [Guide](docs/guide.md)
- [API reference](docs/api.md)
- [Architecture ADR](docs/adr/crystal_live_component.md)

Run the documentation site locally:

```bash
crystal run examples/docs_site/app.cr
# open http://localhost:3000/docs/
```

## Development

```bash
crystal spec
```

## License

MIT
