module Autenticacion
  module Guardianes
    class Guardian
      # :nocov:
      def self.desde_el_entorno
        raise NotImplementedError
      end

      def autenticar_usando(token:, &block)
        raise NotImplementedError
      end
      # :nocov:
    end
  end
end
