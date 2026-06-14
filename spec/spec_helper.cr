require "spec"
require "../src/crystal_live"

Spec.before_each do
  CrystalLive.reset_config!
  CrystalLive::LiveManager.clear
  CrystalLive::ComponentRegistry.clear
  CrystalLive::LiveRegistry.clear
  CrystalLive::LiveStream.clear
  CrystalLive::Csrf.clear
end
