# Patch for Rails 6.0 + system Ruby 2.6 (openssl gem 2.1.2, LibreSSL 3.3).
# The old openssl bindings cannot set AAD on AEAD ciphers (aes-*-gcm), which
# breaks Rails 6.0's MessageEncryptor ("couldn't set additional authenticated
# data"). Swap each GCM cipher for the CBC cipher with the same key length;
# MessageEncryptor then falls back to encrypt-then-HMAC, which works fine.
# Dev-environment compatibility shim only.
require "active_support/message_encryptor"

module OpenSSL3GcmFix
  GCM_TO_CBC = { "aes-128-gcm" => "aes-128-cbc", "aes-256-gcm" => "aes-256-cbc" }.freeze

  def initialize(secret, *signature_key_or_options)
    options = signature_key_or_options.extract_options!
    cipher = options[:cipher] || ActiveSupport::MessageEncryptor.default_cipher
    if GCM_TO_CBC.key?(cipher.to_s)
      options[:cipher] = GCM_TO_CBC[cipher.to_s]
    end
    signature_key_or_options << options unless options.empty?
    super(secret, *signature_key_or_options)
  end
end

ActiveSupport::MessageEncryptor.prepend(OpenSSL3GcmFix)
ActiveSupport::MessageEncryptor.default_cipher = "aes-256-cbc" if ActiveSupport::MessageEncryptor.respond_to?(:default_cipher=)
