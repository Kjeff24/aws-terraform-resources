variable "networking" {
  description = "Networking configuration for the VPC module"
  type = object({
    vpc_cidr                : string
    public_subnet_count     : number
    private_subnet_count    : number
    subnet_prefix_length   : number
    enable_dns_hostnames    : bool
    enable_dns_support      : bool
    public_subnet_index_start  : optional(number, 0)
    private_subnet_index_start : optional(number)
  })
}
