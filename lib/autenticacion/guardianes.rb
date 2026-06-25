require_relative "guardianes/error"
require_relative "guardianes/guardian"
require_relative "guardianes/inseguro"
require_relative "guardianes/auth0"

module Autenticacion
  module Guardianes
    def self.construir(nombre)
      const_get(nombre).desde_el_entorno
    end
  end
end
