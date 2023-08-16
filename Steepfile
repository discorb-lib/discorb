# frozen_string_literal: true

D = Steep::Diagnostic

target :lib do
  signature "sig"

  check "lib"

  configure_code_diagnostics(D::Ruby.lenient)
  configure_code_diagnostics do |config|
    config[D::Ruby::UnsupportedSyntax] = nil
    config[D::Ruby::UnexpectedSuper] = nil
    config[D::Ruby::UnexpectedPositionalArgument] = nil
    config[D::Ruby::InsufficientPositionalArguments] = nil
    config[D::Ruby::UnknownInstanceVariable] = nil
    config[D::Ruby::UnknownGlobalVariable] = nil
  end
end

# target :test do
#   signature "sig"
#   signature "examples/sig"

#   check "examples/**/*.rb"

#   library "net-http", "timeout"
# end
