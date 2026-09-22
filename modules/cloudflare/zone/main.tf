data "cloudflare_zone" "this" {
  filter = {
    name = var.zone_name
  }
}

resource "cloudflare_dns_record" "this" {
  for_each = {
    for r in var.records :
    "${r.type}-${r.name}-${substr(sha1(r.content), 0, 8)}" => r
  }

  zone_id  = data.cloudflare_zone.this.id
  type     = each.value.type
  name     = each.value.name
  content  = each.value.content
  ttl      = each.value.ttl
  proxied  = contains(["A", "AAAA", "CNAME"], each.value.type) ? each.value.proxied : null
  priority = each.value.priority
}
