require "jwt"

module Autenticacion
  module Guardianes
    class Inseguro < Guardian
      def self.desde_el_entorno
        new
      end

      def autenticar_usando(token:, &block)
        JWT.decode token, "inseguro", true, algorithm: "HS256"
      rescue JWT::DecodeError
        raise Error, "Usuario desconocido"
      else
        block.call(:inseguro)
      end
    end
  end
end
