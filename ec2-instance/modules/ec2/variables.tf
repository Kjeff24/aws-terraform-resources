variable "instance_config" {
	type = object({
		ami_id                   : string
		instance_type            : string
		subnet_id                : string
		security_group_ids       : list(string)
		key_name                 : string
		associate_public_ip      : bool
		iam_instance_profile     : string
		root_volume_size_gb      : number
		root_volume_type         : string
		disable_api_termination  : bool
	})
}