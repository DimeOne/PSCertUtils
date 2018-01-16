
Function Get-GitCurlBundlePath {
  [CmdletBinding()]

  $GitSSL = ""

  try {
    $GitSSL = $(git config http.sslcainfo)
  }
  catch {
    Write-Error "Git is not installed."
  }

  return $GitSSL

}


Function Install-X509CertificateToGitTrustedCaBundle {
  [CmdletBinding()]
  Param(
    [Parameter(Mandatory = $True, ValueFromPipelineByPropertyName=$True, Position = 0)]
    [ValidateNotNullOrEmpty()]
    [Alias("CertificateObject", "X509CertificateObject", "X509Certificate2")]
    [System.Security.Cryptography.X509Certificates.X509Certificate2] $X509Certificate,
    [Parameter(Mandatory = $False, ValueFromPipelineByPropertyName=$True, Position = 1)]
    [Alias("FriendlyName", "Name", "Alias", "CertificateAlias")]
    [String] $CertAlias,
    [Parameter(Mandatory = $False, Position = 2)]
    [String[]] $GitCaBundles = $(Get-GitCurlBundlePath)
  )

  PROCESS {

    If ("$GitCaBundles" -eq "") {
      Write-Output "Unable to find any GitCaBundles."
      return
    }

    # Use the common name as alias if no alias has been given
    If ([String]::IsNullOrWhiteSpace($CertAlias)) {
      $CertAlias = Get-X509CommonNameFromSubject -X509Subject $X509Certificate.Subject
    }

    # Remove invalid characters from alias
    $CertAlias = Get-SafeCertificateAlias $CertAlias

    if ($GitCaBundles.Count -gt 0) {
      # Import the certificate to all given java keystores
      Foreach ($CaBundle in $GitCaBundles) {
        Import-X509CertificateToBundle -X509Certificate $X509Certificate -CertAlias $CertAlias -KeyStore "$CaBundle"
      }
    }
    else {
      Write-Warning "No git ca bundles found to add certficate to."
    }

  }

}
