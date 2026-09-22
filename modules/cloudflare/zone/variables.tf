variable "zone_name" {
  type = string
}

variable "records" {
  type = list(object({
    type     = string
    name     = string
    content  = string
    ttl      = optional(number, 1)
    proxied  = optional(bool, false)
    priority = optional(number)
  }))
  default = []
}
