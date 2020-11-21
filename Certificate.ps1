# resource attributes
Test-Path $env:resource_group
Test-Path $env:location
Test-Path $env:name
Test-Path $env:plan_id

Import-Module AzureHelpers
$InformationPreference = 'Continue'
$ErrorActionPreference = 'Stop'

function Invoke-AzAPI-Certificate {
    [CmdletBinding()]
    param([string]$method,[string]$body="",[string]$cert_name)
    return Invoke-AzAPI -method $method -body $body -URL "https://management.azure.com/subscriptions/$env:AzureSubscription/resourceGroups/$env:resource_group/providers/Microsoft.Web/certificates/$($cert_name)?api-version=2019-08-01"
}

function Invoke-AzAPI {
   [CmdletBinding()]
    param([string]$method,[string]$body="",[string]$URL)
    $token = Get-AzToken -AuthMethod ClientSecret
    $secure_token = ConvertTo-SecureString $token -AsPlainText -Force
    Write-Error "About to Invoke-RestMethod $URL..." -ErrorAction 'Continue'
    $result = Invoke-RestMethod -Method $method -Uri $URL -Authentication Bearer -Token $secure_token -Body $body -ContentType 'application/json'
    Write-Error "AzAPI Result: $(ConvertTo-Json $result)" -ErrorAction 'Continue'
    return $result
}

function Read-WebAppCert {
    [CmdletBinding()]
    param([Parameter(ValueFromPipeline)][string]$pipeline)

    #
    # The general approach for this function is to get a list
    # of certificates in the subscription and filter on 
    # $cert_name.
    # 
    # Ideally we would look the certificate up by name but
    # sometimes Azure puts a newly-created certificate in
    # a different resource group than the one we tell it to
    # use, so we have to go searching a bit.
    #

    # Not sure what this bit does, leaving it here just in case
    $cert_name = ""
    if (![String]::IsNullOrEmpty($pipeline)) {
        $cert_name = $(ConvertFrom-Json $pipeline).name
    } else {
        $cert_name = $env:name
    }
    Write-Error "Looking for cert named $cert_name..." -ErrorAction 'Continue'

    # Get list of certificates in subscription
    $r = Invoke-AzAPI -method 'get' -URL "https://management.azure.com/subscriptions/$env:AzureSubscription/providers/Microsoft.Web/certificates?api-version=2019-08-01"
    if (-not $r -or -not $r.value -or $r.value.count -le 0) {
        Write-Error "Read-WebAppCert: Response from Invoke-AzAPI was no good" -ErrorAction 'Continue'
        return $null
    }
    Write-Error "Found $($r.value.count) certificates in the subscription" -ErrorAction 'Continue'
    
    # Pick the one with the right name, if it exists
    $matching_certs = ($r.value | Where-Object {$_.name -eq $cert_name})
    if (-not $matching_certs) {
        Write-Error "Did not find matching certificate." -ErrorAction 'Continue'
        return $null
    }
    $cert_object = $matching_certs[0]
    Write-Error "cert_object: $(ConvertTo-Json $cert_object)" -ErrorAction 'Continue'
    
    # Compile state object to return
    $state = @{
        name  = $cert_object.name
        thumbprint = $cert_object.properties.thumbprint
    }

    $json = ConvertTo-Json $state
    Write-Output $json
}

function Set-WebAppCert {
    Remove-WebAppCert
    New-WebAppCert
}

function Remove-WebAppCert {
    Invoke-AzAPI-Certificate -method 'DELETE' -cert_name $env:name
    Read-WebAppCert
}

function New-WebAppCert {
    Write-Error "New-WebAppCert: starting..." -ErrorAction 'Continue'
    $body = @{
        location = $env:location
        properties = @{
            password = ""
            serverFarmId = $env:plan_id
            canonicalName = $env:name 
        }
    }
    $jsonBody = ConvertTo-Json -InputObject $body -Depth 3
    $result = Invoke-AzAPI-Certificate -method 'PUT' -body $jsonBody -cert_name $env:name
    # Validate output before returning
    $resultIsValid = $false
    $errorCount = 0
    # Allow 1 minute (12 x 5 seconds) for newly-created certificate to appear
    while ((-not $resultIsValid) -and ($errorCount -le 12)) {
        $ret = Read-WebAppCert
        if ($ret -and (ConvertFrom-Json $ret).thumbprint) {
            $resultIsValid = $true
        } else {
            Write-Error "Read-WebAppCert did not return thumbprint, sleeping for 5 seconds..." -ErrorAction 'Continue'
            Start-Sleep -Seconds 5
            $errorCount = $errorCount + 1
        }
    }
    if (-not $resultIsValid) {
        throw "Certificate does not have thumbprint, this is not going to work"
    } else {
        return $ret
    }
}
