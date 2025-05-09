variable "keypair_config" {
  type = object({
    enabled              : bool
    key_pair_name         : string
    generate_key_pair     : bool
    public_key            : string
    public_key_path       : string
    key_algorithm         : string
    rsa_bits              : number
    ecdsa_curve           : string
    save_private_key_path : string
    save_public_key_path  : string
  })
}

variable "tags" {
  type = map(string)
}

locals {
  # Effective public key to upload to AWS EC2
  # - If generation is enabled, use the TLS-generated OpenSSH public key
  # - Otherwise prefer an inline public_key; if empty, read from public_key_path
  computed_public_key = (
    (var.keypair_config.enabled && var.keypair_config.generate_key_pair)
    ? tls_private_key.generated[0].public_key_openssh
    : (
        var.keypair_config.public_key != ""
        ? var.keypair_config.public_key
        : (var.keypair_config.public_key_path != "" ? file(var.keypair_config.public_key_path) : "")
      )
  )
}
