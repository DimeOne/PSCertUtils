Function Install-X509CertificateToWindowsCertStore {
[CmdletBinding()]
Param(
  [Parameter(Mandatory = $True, ValueFromPipelineByPropertyName=$True, Position = 0)]
  [ValidateNotNullOrEmpty()]
  [Alias("CertificateObject", "X509CertificateObject", "X509Certificate2")]
  [System.Security.Cryptography.X509Certificates.X509Certificate2] $X509Certificate,
  [Parameter(Mandatory = $False, Position = 1)]
  [ValidateSet("LocalMachine","CurrentUser")]
  [Alias("StoreScope", "CertificateStoreScope")]
  [String] $Scope = "LocalMachine",
  [Parameter(Mandatory = $False, Position = 2)]
  [ValidateSet("AddressBook", "AuthRoot", "CA", "Disallowed", "My", "Root", "TrustedPeople", "TrustedPublisher")]
  [Alias("StoreLocation", "CertificateStoreLocation", "Location")]
  [String] $LocationName = "Root"
)
  BEGIN {}
  PROCESS {

    $X509CertificateStore = New-Object System.Security.Cryptography.X509Certificates.X509Store "$LocationName", "$Scope"

    # Check if Certificate with the given Thumbprint already exists in given store
    Try {
      $X509CertificateStore.Open("ReadOnly") | Out-Null
      $X509CertificateInStore = $X509CertificateStore.Certificates | Where-Object { $_.Thumbprint -eq $X509Certificate.Thumbprint }
      $X509CertificateStore.Close() | Out-Null
    }
    Catch {
      Throw('Unable to add Certificate to Windows Trusted Root Certificate Store, could not open X509CertificateStore - EXCEPTION: {0}' -f $_.Exception.InnerException.Message)
    }

    If ($X509CertificateInStore) {
      Write-Verbose "Certificate with given Thumbprint is already installed as Trusted Root Certificate Authority in given Store: $LocationName\$Scope  - skipping install"
    }
    Else {
      # Add Certificate to the Store
      Try {
        $X509CertificateStore.Open("ReadWrite") | Out-Null
        $X509CertificateStore.Add($X509Certificate) | Out-Null
        $X509CertificateStore.Close() | Out-Null
      }
      Catch {
        Throw('Unable to add Certificate to Windows Trusted Root Certificate Store, received exception during import: {0}' -f $_.Exception.InnerException.Message)
      }
    }

  }
  END {}

}