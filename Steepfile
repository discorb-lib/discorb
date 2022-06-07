# frozen_string_literal: true

D = Steep::Diagnostic

target :lib do
  signature "sig"

  check "lib"

  library "net-http", "timeout"

  configure_code_diagnostics(D::Ruby.lenient)
  configure_code_diagnostics do |config|
    config[D::Ruby::UnsupportedSyntax] = nil
    config[D::Ruby::UnexpectedSuper] = nil
    config[D::Ruby::UnexpectedPositionalArgument] = nil
    config[D::Ruby::InsufficientPositionalArguments] = nil
  end
end

target :test do
  signature "sig"
  signature "examples/sig"

  check "examples/**/*.rb"

  library "net-http", "timeout"
end
