output "url" {
  value = "https://${azurerm_cdn_frontdoor_endpoint.web.host_name}"
}
