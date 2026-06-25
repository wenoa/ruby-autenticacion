RSpec.describe(Autenticacion::Guardianes::Inseguro) {
  subject(:guardian) { described_class.new }

  it("ejecuta el bloque con un JWT firmado con el secreto «inseguro»") {
    expect { |probe|
      guardian.autenticar_usando(token: JWT.encode({ "sub" => "123" }, "inseguro"), &probe)
    }.to yield_with_no_args
  }

  it("falla con «Usuario desconocido» cuando el JWT está firmado con otro secreto") {
    expect {
      guardian.autenticar_usando(token: JWT.encode({ "sub" => "123" }, "otro secreto"))
    }.to raise_error(Autenticacion::Guardianes::Error, "Usuario desconocido")
  }

  it("falla con «Usuario desconocido» cuando el token no es un JWT") {
    expect {
      guardian.autenticar_usando(token: "no-es-un-jwt")
    }.to raise_error(Autenticacion::Guardianes::Error, "Usuario desconocido")
  }
}
