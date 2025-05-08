variable "networking" {
  description = "Networking configuration for the VPC module"
  type = object({
    vpc_cidr             : string
    public_subnet_count  : number
    private_subnet_count : number
    subnet_prefix_length : number
  })
}
