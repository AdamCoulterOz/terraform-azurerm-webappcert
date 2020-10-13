# Certificate can be created in a resource group
# specifically for the Web App, but it targets the
# app service plan, hence why both WebAppRG and
# ServicePlanRG are specified.

resource "shell_script" "app_service_managed_cert" {
  environment = {
    name           = var.name
    plan_id        = var.app_service_plan_id
    resource_group = var.resource_group
    location       = var.location
  }
  lifecycle_commands {
    create = ". ${path.module}/Certificate.ps1; New-WebAppCert"
    read   = ". ${path.module}/Certificate.ps1; Read-WebAppCert"
    update = ". ${path.module}/Certificate.ps1; Set-WebAppCert"
    delete = ". ${path.module}/Certificate.ps1; Remove-WebAppCert"
  }
}
