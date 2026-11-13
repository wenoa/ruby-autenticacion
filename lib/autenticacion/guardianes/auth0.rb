require "jwt"
require "json"
require "net/http"
require "base64"
require "openssl"

module Autenticacion
  module Guardianes
    class Auth0 < Guardian
      VIGENCIA_DE_LAS_CLAVES_POR_DEFECTO = 900

      def self.desde_el_entorno
        new(
          domain: ENV.fetch("AUTH0_DOMAIN"),
          audience: ENV.fetch("AUTH0_AUDIENCE"),
          vigencia: ENV.fetch("AUTH0_KEYS_TTL", VIGENCIA_DE_LAS_CLAVES_POR_DEFECTO).to_i,
        )
      end

      def initialize(
        domain:,
        audience:,
        reloj: -> { Process.clock_gettime(Process::CLOCK_MONOTONIC) },
        vigencia: VIGENCIA_DE_LAS_CLAVES_POR_DEFECTO
      )
        super()
        @domain = domain
        @audience = audience
        @reloj = reloj
        @vigencia = vigencia
        @vence_en = 0
        @claves = {}
        @mutex = Mutex.new
      end

      def autenticar_usando(token:, &block)
        payload, _encabezado = verify(token)
      rescue JWT::DecodeError
        raise Error, "Usuario desconocido"
      else
        block.call(payload.fetch("sub"))
      end

      private

      def verify(token)
        JWT.decode(
          token,
          "",
          true,
          algorithms: "RS256",
          verify_iss: true,
          verify_iat: true,
          verify_aud: true,
          iss: "https://#{@domain}/",
          aud: @audience,
        ) { |header| jwk(header["kid"]) }
      end

      def jwk(kid)
        @mutex.synchronize {
          recargar_las_claves_si_vencieron
          @claves[kid]
        }
      end

      def recargar_las_claves_si_vencieron
        return if @reloj.call < @vence_en

        @claves = load_jwks
        @vence_en = @reloj.call + @vigencia
      end

      def load_jwks
        jwks_raw = Net::HTTP.get URI("https://#{@domain}/.well-known/jwks.json")
        jwks_keys = JSON.parse(jwks_raw)["keys"]
        jwks_keys.to_h { |k|
          [
            k["kid"],
            OpenSSL::X509::Certificate.new(
              Base64.decode64(k["x5c"].first)
            ).public_key,
          ]
        }
      end
    end
  end
end
