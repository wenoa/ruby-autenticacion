# Autenticación

Autenticación de tokens con guardianes intercambiables: `Inseguro` (desarrollo) y `Auth0` (producción).

## Instalación

```ruby
gem "autenticacion", github: "wenoa/ruby-autenticacion"
```

## Uso con Roda

```ruby
require "autenticacion/integraciones/roda"

class App < Roda
  plugin :autenticado, guardian: :Auth0, activo: ENV["ENV"] == "production"

  route do |r|
    r.on "privado" do
      autenticado do
        # ...
      end
    end
  end
end
```

`activo: false` (o sin `guardian:`) usa `Inseguro`. `autenticado` responde `401` si el token no es válido.
