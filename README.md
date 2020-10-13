## Additional Requirements

### PowerShell Dependencies

As this module uses PowerShell it requires that PowerShell Core and the following modules are installed on the deployment agent:

- PowerShell Core (~>7.0)
- PS Module: `AzureHelpers` (~>0.2.1)
- Please also install any dependencies of `AzureHelpers`

```powershell
Install-Module "AzureHelpers"
```

## Usage Example

```terraform
module "webapp_data" {
  source            = "AdamCoulterOz/webappcert/azurerm"
  
  resource_group = "myresourcegroup"
  location = "australiaeast"
  app_service_plan_id = "/subscriptions/00000000-0000-0000-0000-000000000001/resourceGroups/myresourcegroup2/providers/Microsoft.Web/serverfarms/myappserviceplan"
  name = "mycertdomain.com"

  client_id         = "00000000-0000-0000-0000-000000000002"
  client_secret     = "abc123"
  tenant_id         = "00000000-0000-0000-0000-000000000003"
  subscription_id   = "00000000-0000-0000-0000-000000000001"
}
```
