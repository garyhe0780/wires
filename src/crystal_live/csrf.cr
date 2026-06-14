module CrystalLive
  module Csrf
    @@tokens = {} of String => String

    def self.token_for(session_id : String) : String
      @@tokens[session_id]? || begin
        token = Random::Secure.hex(32)
        @@tokens[session_id] = token
        token
      end
    end

    def self.valid?(session_id : String, token : String?) : Bool
      return true unless CrystalLive.config.csrf_protection

      expected = @@tokens[session_id]?
      !expected.nil? && expected == token
    end

    def self.clear_session(session_id : String)
      @@tokens.delete(session_id)
    end

    def self.clear
      @@tokens.clear
    end
  end
end
