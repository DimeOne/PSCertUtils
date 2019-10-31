Function Install-X509CertificateToWindowsCertStore {
  [CmdletBinding()]
  Param(
    [Parameter(Mandatory = $True, ValueFromPipelineByPropertyName = $True, Position = 0)]
    [ValidateNotNullOrEmpty()]
    [Alias("CertificateObject", "X509CertificateObject", "X509Certificate2", "X509Certificate")]
    [System.Security.Cryptography.X509Certificates.X509Certificate2[]] $X509Certificates,
    [Parameter(Mandatory = $False, Position = 1)]
    [ValidateSet("LocalMachine", "CurrentUser")]
    [Alias("StoreScope", "CertificateStoreScope")]
    [String] $Scope = "LocalMachine",
    [Parameter(Mandatory = $False, Position = 2)]
    [ValidateSet("AddressBook", "AuthRoot", "CA", "Disallowed", "My", "Root", "TrustedPeople", "TrustedPublisher")]
    [Alias("StoreLocation", "CertificateStoreLocation", "Location")]
    [String] $LocationName = "Root"
  )
  BEGIN { }
  PROCESS {
  
    Foreach ($X509Certificate in $X509Certificates) {
  
      $RealLocation = $LocationName
      # Prevent non-root certificates beeing installed in the root certificate store
      If (($RealLocation -eq "root") -and ($X509Certificate.Issuer -ne $X509Certificate.Subject)) {
        Write-Verbose ('Mismatching issuer and subject on certificate: {0} expected: {1}' -f $X509Certificate.Issuer, $X509Certificate.Subject)
        Write-Warning "Only self-signed certificates may be added to the trusted root certificate store, this certificate is not. Installing to intermediate ca store."
        $RealLocation = "CA"
      }
  
      $X509CertificateStore = New-Object System.Security.Cryptography.X509Certificates.X509Store "$RealLocation", "$Scope"
  
      # Check if Certificate with the given thumbprint already exists in given store
      Try {
        $X509CertificateStore.Open("ReadOnly") | Out-Null
        $X509CertificateInStore = $X509CertificateStore.Certificates | Where-Object { $_.Thumbprint -eq $X509Certificate.Thumbprint }
        $X509CertificateStore.Close() | Out-Null
      }
      Catch {
        Throw('Unable to add Certificate to Windows Certificate Store, could not open X509CertificateStore - EXCEPTION: {0}' -f $_.Exception.InnerException.Message)
      }
  
      If ($X509CertificateInStore) {
        Write-Verbose "Certificate with given Thumbprint is already installed in given Store: $Scope\$RealLocation  - skipping install"
      }
      Else {
        # Add Certificate to the Store
        Try {
          $X509CertificateStore.Open("ReadWrite") | Out-Null
          $X509CertificateStore.Add($X509Certificate) | Out-Null
          $X509CertificateStore.Close() | Out-Null
        }
        Catch {
          Throw("Unable to add certificate to Windows Certificate Store: $Scope\$RealLocation, received exception during import: {0}" -f $_.Exception.InnerException.Message)
        }
      }
    }
  
  }
  END { }
  
}