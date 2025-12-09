resource "azurerm_resource_group" "default" {
  name     = "rg-cdn"
  location = var.location
}

resource "azurerm_storage_account" "default" {
  name                          = "stactioncdn"
  resource_group_name           = azurerm_resource_group.default.name
  location                      = azurerm_resource_group.default.location
  account_tier                  = "Standard"
  account_replication_type      = "LRS"
  account_kind                  = "StorageV2"
  public_network_access_enabled = true
}

resource "azurerm_storage_account_static_website" "default" {
  storage_account_id = azurerm_storage_account.default.id
  index_document     = "index.html"
  error_404_document = "index.html"
}

resource "azurerm_storage_container" "web" {
  name                  = "$web"
  storage_account_id    = azurerm_storage_account.default.id
  container_access_type = "blob"
}

resource "azurerm_storage_blob" "index_html" {
  name                   = "index.html"
  storage_account_name   = azurerm_storage_account.default.name
  storage_container_name = azurerm_storage_container.web.name
  type                   = "Block"
  source_content         = file("${path.module}/html/index.html")
  content_type           = "text/html"

  lifecycle {
    action_trigger {
      actions = [action.azurerm_cdn_front_door_cache_purge.index_html]
      events  = [after_update]
    }
  }
}

action "azurerm_cdn_front_door_cache_purge" "index_html" {
  config {
    front_door_endpoint_id = azurerm_cdn_frontdoor_endpoint.web.id
    content_paths          = ["/*"]
    timeout                = "2m"
  }
}

resource "azurerm_cdn_frontdoor_profile" "web" {
  name                = "web"
  resource_group_name = azurerm_resource_group.default.name
  sku_name            = "Standard_AzureFrontDoor"
}

resource "azurerm_cdn_frontdoor_endpoint" "web" {
  name                     = "web"
  cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.web.id
}

resource "azurerm_cdn_frontdoor_origin_group" "web" {
  name                     = "origin-group-storage-web"
  cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.web.id
  session_affinity_enabled = false

  load_balancing {
    sample_size                 = 4
    successful_samples_required = 3
  }

  health_probe {
    protocol            = "Https"
    request_type        = "GET"
    interval_in_seconds = 120
    path                = "/"
  }
}

locals {
  storage_static_hostname = azurerm_storage_account.default.primary_web_host
}

resource "azurerm_cdn_frontdoor_origin" "web" {
  name                           = "storage-static-site-origin"
  cdn_frontdoor_origin_group_id  = azurerm_cdn_frontdoor_origin_group.web.id
  certificate_name_check_enabled = false
  host_name                      = local.storage_static_hostname
  http_port                      = 80
  https_port                     = 443
  origin_host_header             = local.storage_static_hostname
  priority                       = 1
  weight                         = 1000
}

resource "azurerm_cdn_frontdoor_route" "web" {
  name                          = "route-root-to-storage"
  cdn_frontdoor_endpoint_id     = azurerm_cdn_frontdoor_endpoint.web.id
  cdn_frontdoor_origin_group_id = azurerm_cdn_frontdoor_origin_group.web.id
  cdn_frontdoor_origin_ids      = [azurerm_cdn_frontdoor_origin.web.id]
  supported_protocols           = ["Http", "Https"]
  # Match everything on the endpoint
  patterns_to_match = ["/*"]

  forwarding_protocol    = "MatchRequest"
  https_redirect_enabled = true

  link_to_default_domain = true # Use the default *.z01.azurefd.net domain
  enabled                = true

  cache {
    query_string_caching_behavior = "IgnoreQueryString"
    content_types_to_compress = [
      "text/html",
    ]
  }
}


