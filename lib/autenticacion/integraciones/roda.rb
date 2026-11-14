require "roda"
require_relative "../../autenticacion"

class Roda
  module RodaPlugins
    module Autenticacion
      def self.load_dependencies(app, _opts = {})
        app.plugin :halt
      end

      def self.configure(app, opts = {})
        nombre = opts.fetch(:activo, true) ? opts.fetch(:guardian, :Inseguro) : :Inseguro
        app.opts[:guardian] = ::Autenticacion::Guardianes.construir(nombre)
      end

      module InstanceMethods
        def autenticado(&)
          bearer = request.get_header("HTTP_AUTHORIZATION").to_s
          token = bearer.sub("Bearer ", "")
          opts.fetch(:guardian).autenticar_usando(token:, &)
        rescue ::Autenticacion::Guardianes::Error
          request.halt(401)
        end
      end
    end

    register_plugin(:autenticacion, Autenticacion)
  end
end
