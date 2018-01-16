Function Install-X509CertificateToLinuxTrustedStore {
  [CmdletBinding()]
  Param(
    [Parameter(Mandatory = $True, ValueFromPipelineByPropertyName=$True, Position = 0)]
    [ValidateNotNullOrEmpty()]
    [Alias("CertificateObject", "X509CertificateObject", "X509Certificate2")]
    [System.Security.Cryptography.X509Certificates.X509Certificate2] $X509Certificate,
    [Parameter(Mandatory = $False, ValueFromPipelineByPropertyName=$True, Position = 1)]
    [Alias("FriendlyName", "Name", "Alias", "CertificateAlias")]
    [String] $CertAlias
  )

  throw ("Not yet implemented")

}