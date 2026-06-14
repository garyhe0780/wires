# Registers a live component factory under a symbolic name.
#
# ```
# register_live_component :clock, Clock
# register_live_component :alice do |session_id|
#   UserCard.new(session_id, 42, "Alice")
# end
# ```
macro register_live_component(name, klass)
  {% unless klass.is_a?(Const) || klass.is_a?(Path) %}
    {% klass = klass.id %}
  {% end %}

  ::CrystalLive::ComponentRegistry.register({{ name }}) do |session_id|
    {{ klass.id }}.new(session_id)
  end
end

macro register_live_component(name, &block)
  ::CrystalLive::ComponentRegistry.register({{ name }}) do |session_id|
    {{ block.body }}
  end
end

# Renders a registered live component for the current session.
#
# ```
# get "/" do |context|
#   session_id = CrystalLive::KemalExtensions.ensure_session_id(context)
#   live_component :clock, session_id
# end
# ```
macro live_component(name, session_id)
  ::CrystalLive::ComponentRegistry.render({{ name }}, {{ session_id }})
end
