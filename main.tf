locals {
  repo_regex    = "^(?:(?P<url>[^/]+))?(?:/(?P<image>[^:]*))??(?::(?P<tag>[^:]*))"
  main_image    = contains(keys(var.images), "main") ? regex(local.repo_regex, var.images.main) : {}
  kubectl_image = contains(keys(var.images), "kubectl") ? regex(local.repo_regex, var.images.kubectl) : {}

  main_pre_value    = "image"
  kubectl_pre_value = "kubectl.image"

  main_set_values    = local.main_image != {} ? [{ name = "${local.main_pre_value}.repository", value = "${local.main_image.url}/${local.main_image.image}" }, { name = "${local.main_pre_value}.tag", value = local.main_image.tag }] : []
  kubectl_set_values = local.kubectl_image != {} ? [{ name = "${local.kubectl_pre_value}.repository", value = "${local.kubectl_image.url}/${local.kubectl_image.image}" }, { name = "${local.kubectl_pre_value}.tag", value = local.kubectl_image.tag }] : []

  set_values = concat(var.set_values, local.main_set_values, local.kubectl_set_values)
}

resource "helm_release" "this" {
  name             = var.name
  repository       = var.repository
  chart            = var.chart
  namespace        = var.namespace
  create_namespace = var.create_namespace
  version          = var.release_version

  values = var.values

  dynamic "set" {
    iterator = each_item
    for_each = local.set_values

    content {
      name  = each_item.value.name
      value = each_item.value.value
      type  = try(each_item.value.type, null)
    }
  }

  dynamic "set_sensitive" {
    iterator = each_item
    for_each = var.set_sensitive_values

    content {
      name  = each_item.value.name
      value = each_item.value.value
      type  = try(each_item.value.type, null)
    }
  }
}
