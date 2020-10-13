output "thumbprint" {
    value = shell_script.app_service_managed_cert.output.thumbprint
}