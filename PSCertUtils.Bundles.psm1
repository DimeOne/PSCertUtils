
Function Import-X509CertificateToBundle {
  [CmdletBinding()]
    Param(
    [Parameter(Mandatory = $True, ValueFromPipelineByPropertyName=$True, Position = 0)]
    [ValidateNotNullOrEmpty()]
    [Alias("CertificateObject", "X509CertificateObject", "X509Certificate2")]
    [System.Security.Cryptography.X509Certificates.X509Certificate2] $X509Certificate,
    [Parameter(Mandatory = $False, ValueFromPipelineByPropertyName=$True, Position = 1)]
    [Alias("FriendlyName", "Name", "Alias", "CertificateAlias")]
    [String] $CertAlias,
    [Parameter(Mandatory = $True, Position = 2)]
    [ValidateNotNullOrEmpty()]
    [Alias("Store", "CertificateStore", "Bundle")]
    [String] $KeyStore
  )

  If (Test-X509CertificateExistsWithinBundle -CertAlias $CertAlias -KeyStore $KeyStore) {
    Write-Verbose ("Certificate with the alias {0} already exists in {1}." -f $CertAlias, $KeyStore)
    return
  }

  Add-X509CertificateToBundle -X509Certificate $X509Certificate -CertAlias $CertAlias -KeyStore $KeyStore

}


# Add certificate to bundle keystore
Function Add-X509CertificateToBundle {
  [CmdletBinding()]
  Param(
    [Parameter(Mandatory = $True, ValueFromPipelineByPropertyName=$True, Position = 0)]
    [ValidateNotNullOrEmpty()]
    [Alias("CertificateObject", "X509CertificateObject", "X509Certificate2")]
    [System.Security.Cryptography.X509Certificates.X509Certificate2] $X509Certificate,
    [Parameter(Mandatory = $False, ValueFromPipelineByPropertyName=$True, Position = 1)]
    [Alias("FriendlyName", "Name", "Alias", "CertificateAlias")]
    [String] $CertAlias,
    [Parameter(Mandatory = $True, Position = 2)]
    [ValidateNotNullOrEmpty()]
    [Alias("Store", "CertificateStore", "Bundle")]
    [String] $KeyStore
  )

  "#$CertAlias" | Add-Content $KeyStore
  Export-X509Certificate -X509Certificate $X509Certificate -CertificateFile $KeyStore -AddToBundle | Out-Null

}


# Test if a certificate with the given alias exists in a bundle keystore - there has to be a comment with the alias
Function Test-X509CertificateExistsWithinBundle {
  [CmdletBinding()]
  Param(
    [Parameter(Mandatory = $True, Position = 0)]
    [ValidateNotNullOrEmpty()]
    [Alias("FriendlyName", "Name", "Alias", "CertificateAlias")]
    [String] $CertAlias,
    [Parameter(Mandatory = $True, Position = 1)]
    [ValidateNotNullOrEmpty()]
    [Alias("Store", "CertificateStore", "Bundle")]
    [String] $KeyStore
  )

  return (Get-Content $KeyStore | Select-String "^#$CertAlias$") -ne $null

}
