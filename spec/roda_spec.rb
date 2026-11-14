require "rack/test"

module Autenticacion
  module Guardianes
    class GuardianQueRechazaTodo < Guardian
      def self.desde_el_entorno
        new
      end

      def autenticar_usando(token:, &)
        raise Error, "rechazado: #{token}"
      end
    end
  end
end

RSpec.describe("Plugin Roda :autenticacion") {
  include Rack::Test::Methods

  def construir_app(**opciones)
    Class.new(Roda) {
      plugin :autenticacion, **opciones

      route { |r|
        r.root {
          autenticado { "ok" }
        }
      }
    }
  end

  def token_valido
    JWT.encode({ "sub" => "123" }, "inseguro")
  end

  context("sin guardián configurado") {
    let(:app) { construir_app }

    it("autentica un token válido con Inseguro y ejecuta la acción") {
      header "Authorization", "Bearer #{token_valido}"

      get "/"

      expect(last_response.status).to eq(200)
      expect(last_response.body).to eq("ok")
    }

    it("responde 401 si no llega ningún token") {
      get "/"

      expect(last_response.status).to eq(401)
    }

    it("responde el 401 con un cuerpo que Rack puede recorrer") {
      # rack-test convierte un cuerpo String en uno válido: se llama a la app directamente para ver el cuerpo que
      # recibe el servidor.
      _status, _headers, cuerpo = app.call(Rack::MockRequest.env_for("/"))

      expect(cuerpo).to respond_to(:each)
    }
  }

  context("con el guardián activo") {
    let(:app) { construir_app(guardian: :GuardianQueRechazaTodo, activo: true) }

    it("construye el guardián nombrado y autentica con él") {
      header "Authorization", "Bearer #{token_valido}"

      get "/"

      expect(last_response.status).to eq(401)
    }
  }

  context("con el guardián inactivo") {
    let(:app) { construir_app(guardian: :GuardianQueRechazaTodo, activo: false) }

    it("ignora el guardián nombrado y usa Inseguro") {
      header "Authorization", "Bearer #{token_valido}"

      get "/"

      expect(last_response.status).to eq(200)
    }
  }
}
