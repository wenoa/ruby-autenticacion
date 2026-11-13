require "base64"
require "openssl"

RSpec.describe(Autenticacion::Guardianes::Auth0) {
  subject(:guardian) { described_class.new(domain: "dummy.auth0.com", audience: "dummy-api") }

  let(:clave_privada) {
    OpenSSL::PKey::RSA.generate 2048
  }

  let(:otra_clave) {
    OpenSSL::PKey::RSA.generate 2048
  }

  let(:certificado_raiz) {
    raiz = OpenSSL::X509::Certificate.new
    raiz.public_key = clave_privada.public_key
    raiz.not_before = Time.now
    raiz.not_after = Time.now + 60
    raiz.sign clave_privada, OpenSSL::Digest.new("SHA1")
  }

  let(:jwk) {
    JWT::JWK.new(clave_privada, "a-kid")
  }

  let(:jwks) {
    {
      keys: [
        {
          use: "sig",
          **jwk.export,
          x5c: [certificado_raiz.to_pem.split("\n")[1...-1].join("\n")],
        },
      ],
    }
  }

  let(:payload_valido) {
    {
      "aud" => ["dummy-api"],
      "iss" => "https://dummy.auth0.com/",
      "sub" => "auth0|123",
      "iat" => Time.now.to_i,
      "exp" => Time.now.to_i + 60,
    }
  }

  def token_con(payload)
    JWT.encode payload, clave_privada, "RS256", { kid: jwk.kid }
  end

  def token_con_kid_desconocido
    JWT.encode payload_valido, otra_clave, "RS256", { kid: "kid-desconocido" }
  end

  def esperar_usuario_desconocido(payload)
    expect { guardian.autenticar_usando(token: token_con(payload)) }
      .to raise_error(Autenticacion::Guardianes::Error, "Usuario desconocido")
  end

  before(:each) {
    stub_request(:get, "https://dummy.auth0.com/.well-known/jwks.json")
      .to_return(body: jwks.to_json)
  }

  it("se construye desde las variables de entorno") {
    stub_const("ENV", "AUTH0_DOMAIN" => "dummy.auth0.com", "AUTH0_AUDIENCE" => "dummy-api")

    expect(described_class.desde_el_entorno).to be_a(described_class)
  }

  it("ejecuta el bloque con el id del usuario del token cuando tiene firma, emisor, audiencia y vigencia válidas") {
    expect { |probe|
      guardian.autenticar_usando(token: token_con(payload_valido), &probe)
    }.to yield_with_args("auth0|123")
  }

  it("falla con «Usuario desconocido» cuando el token está vencido") {
    esperar_usuario_desconocido payload_valido.merge("exp" => Time.now.to_i)
  }

  it("falla con «Usuario desconocido» cuando el emisor del token no es el esperado") {
    esperar_usuario_desconocido payload_valido.merge("iss" => "wtf")
  }

  it("falla con «Usuario desconocido» cuando la audiencia del token no es la esperada") {
    esperar_usuario_desconocido payload_valido.merge("aud" => "wtf")
  }

  it("no reconsulta las claves de Auth0 ante un token con un kid desconocido") {
    guardian.autenticar_usando(token: token_con(payload_valido)) {}

    expect {
      guardian.autenticar_usando(token: token_con_kid_desconocido)
    }.to raise_error(Autenticacion::Guardianes::Error)

    expect(a_request(:get, "https://dummy.auth0.com/.well-known/jwks.json"))
      .to have_been_made.once
  }

  it("respeta la vigencia de las claves indicada al construirlo") {
    tiempo = 0.0
    guardian = described_class.new(
      domain: "dummy.auth0.com", audience: "dummy-api", reloj: -> { tiempo }, vigencia: 60
    )

    guardian.autenticar_usando(token: token_con(payload_valido)) {}
    tiempo += 61
    guardian.autenticar_usando(token: token_con(payload_valido)) {}

    expect(a_request(:get, "https://dummy.auth0.com/.well-known/jwks.json"))
      .to have_been_made.twice
  }

  it("vuelve a consultar las claves de Auth0 cuando expiró su vigencia") {
    tiempo = 0.0
    guardian = described_class.new(
      domain: "dummy.auth0.com", audience: "dummy-api", reloj: -> { tiempo }
    )

    guardian.autenticar_usando(token: token_con(payload_valido)) {}
    tiempo += described_class::VIGENCIA_DE_LAS_CLAVES_POR_DEFECTO + 1
    guardian.autenticar_usando(token: token_con(payload_valido)) {}

    expect(a_request(:get, "https://dummy.auth0.com/.well-known/jwks.json"))
      .to have_been_made.twice
  }

  it("toma la vigencia de las claves de las variables de entorno") {
    stub_const("ENV", {
      "AUTH0_DOMAIN" => "dummy.auth0.com",
      "AUTH0_AUDIENCE" => "dummy-api",
      "AUTH0_KEYS_TTL" => "0",
    })
    guardian = described_class.desde_el_entorno

    guardian.autenticar_usando(token: token_con(payload_valido)) {}
    guardian.autenticar_usando(token: token_con(payload_valido)) {}

    expect(a_request(:get, "https://dummy.auth0.com/.well-known/jwks.json"))
      .to have_been_made.twice
  }
}
