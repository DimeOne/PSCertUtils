
Function Get-X509Certificate {
  [CmdletBinding()]
  Param(
    [Parameter(Mandatory = $True, Position = 0)]
    [ValidateNotNullOrEmpty()]
    [String] $CertificateUri,
    [Parameter(Mandatory = $False, Position = 1)]
    [String] $ValidationThumbprint,
    [Parameter(Mandatory = $False, Position = 2)]
    [securestring] $CertificatePassword,
    [Parameter(Mandatory = $False, Position = 3)]
    [String] $FriendlyName,
    [Parameter(Mandatory = $False, Position = 4)]
    [Switch] $InSecure
  )

  # Parse CertificateUri as Uri
  $X509CertificateUri = $CertificateUri -as [System.URI]

  # If there is no AbsoluteURI, the URI is using the wrong format
  if ($X509CertificateUri.AbsoluteURI -eq $null) { throw ("Unable to get certificate file from {0}" -f $CertificateUri) }

  # Download Certificate File if the URI given is using HTTP or HTTPS
  if ($X509CertificateUri.AbsoluteURI -ne $null -and $X509CertificateUri.Scheme -match '[http|https]') {

    try {
      # Request certificate from server
      $WebResponse = Invoke-WebRequest -Uri $X509CertificateUri.AbsoluteURI -ErrorAction Stop -UseBasicParsing
    }
    catch {
      throw ('Unable to download certificate file from ["{0}"] - EXCEPTION: {1}' -f $X509CertificateUri.AbsoluteURI, $_.Exception.Message)
    }

    try {
      $X509Certificate = New-Object System.Security.Cryptography.X509Certificates.X509Certificate2($WebResponse.Content, $CertificatePassword, 'Exportable')
    }
    catch {
      throw("Unable to load Certificate from WebResponse - EXCEPTION: {1}" -f $CertificateFile, $_.Exception.InnerException.Message)
    }

  }
  elseif (Test-Path -Path "$CertificateUri" -PathType Leaf) {
    Write-Verbose -Message ('Loading certificate from file: "{0}".' -f $CertificateUri)
    # Load Certificate from File to X509Certificate2 object
    Try
    {
      $X509Certificate = New-Object System.Security.Cryptography.X509Certificates.X509Certificate2($CertificateUri, $CertificatePassword, 'Exportable')
    }
    Catch
    {
      throw("Unable to load the certificate from {0} - Exception: {1}" -f $CertificateUri, $_.Exception.InnerException.Message)
    }
  }
  Else
  {
    throw ('Unable to find or download the certificate from "{0}.' -f $CertificateUri)
  }

  If ([String]::IsNullOrWhiteSpace($ValidationThumbprint))
  {
    If (!$InSecure)
    {
      throw("No ValidationThumbprint has been supplied, unable to verify certificate. Use -InSecure parameter to force import without validation.")
    }
    Else
    {
      Write-Warning ('No ValidationThumbprint has been supplied, unable to verify certificate.')
    }
  }
  Elseif ($ValidationThumbprint -ne $X509Certificate.Thumbprint)
  {
    throw("Unable to validate certificate from {0}, thumbprint validation mismatch {1} != {2}" -f $CertificateUri, $ValidationThumbprint, $X509Certificate.Thumbprint)
  }

  $CommonName = Get-X509CommonNameFromSubject -X509Subject $X509Certificate.Subject

  # Set friendly name to a safe version of the common name if none was given
  If ([String]::IsNullOrWhiteSpace($FriendlyName)) {
    $FriendlyName = Get-SafeCertificateAlias $CommonName
  }
  Else {
    $FriendlyName = Get-SafeCertificateAlias $FriendlyName
  }

  # Set the friendly name of the X509CertificateObject
  $X509Certificate.FriendlyName = $FriendlyName

  # Return a PSCustomObject with some information in addition to the X509Certificate object
  return [PSCustomObject] @{
    CommonName = $CommonName
    FriendlyName = $FriendlyName
    Source = $X509CertificateUri
    ValidatedThumbprint = $ValidationThumbprint
    X509Certificate = $X509Certificate
  }

}


Function Export-X509Certificate {
  [CmdletBinding()]
  Param(
    [Parameter(Mandatory = $True, Position = 0)]
    [ValidateNotNullOrEmpty()]
    [System.Security.Cryptography.X509Certificates.X509Certificate2] $X509Certificate,
    [Parameter(Mandatory = $False, Position = 1)]
    [String] $CertificateFile = '{0}.crt'-f [System.IO.Path]::GetTempFileName(),
    [Parameter(Mandatory = $False, Position = 2)]
    [Alias('Password', 'Pass', 'SecurePassword')]
    [securestring] $CertificatePassword,
    [Parameter(Mandatory = $False, Position = 3)]
    [Switch] $AddToBundle = $False,
    [Parameter(Mandatory = $False, Position = 4)]
    [Switch] $Force = $False
  )

  if ($X509Certificate.GetType().FullName -ne "System.Security.Cryptography.X509Certificates.X509Certificate2") {
    throw ('Unknown X509Certificate object type: "{0}" expected "System.Security.Cryptography.X509Certificates.X509Certificate2".' -f $X509Certificate.GetType().FullName)
  }

  if (-not $AddToBundle -and -not $Force -and (Test-Path $CertificateFile)) {
    throw('Unable to export X509Certificate to "{0}". File exists and neither Force nor AddToBundle were set.' -f $CertificateFile)
  }

  try {
    if ($AddToBundle) {
        "-----BEGIN CERTIFICATE-----" | Add-Content $CertificateFile -ErrorAction Stop
    }
    else {
        "-----BEGIN CERTIFICATE-----" | Set-Content $CertificateFile -Encoding String -ErrorAction Stop
    }
    [System.Convert]::ToBase64String($X509Certificate.Export('cert', $CertificatePassword), "InsertLineBreaks") | Add-Content $CertificateFile
    "-----END CERTIFICATE-----" | Add-Content $CertificateFile
  }
  catch {
    throw("Unable to export X509Certificate to {0} - {1}" -f $CertificateFile, $_)
  }

  return $CertificateFile
}


Function Export-X509CertificatePfx {
  [CmdletBinding()]
  Param(
    [Parameter(Mandatory = $True, Position = 0)]
    [ValidateNotNullOrEmpty()]
    [System.Security.Cryptography.X509Certificates.X509Certificate2] $X509Certificate,
    [Parameter(Mandatory = $False, Position = 1)]
    [String] $CertificateFile = '{0}.pfx'-f [System.IO.Path]::GetTempFileName(),
    [Parameter(Mandatory = $False, Position = 2)]
    [securestring] $CertificatePassword
  )

  if ($X509Certificate.GetType().FullName -ne "System.Security.Cryptography.X509Certificates.X509Certificate2") {
    throw ('Unknown X509Certificate object type: "{0}" expected "System.Security.Cryptography.X509Certificates.X509Certificate2".' -f $X509Certificate.GetType().FullName)
  }

  if (Test-Path -Path $CertificateFile) {
    throw('Unable to export X509Certificate to "{0}". File exists.' -f $CertificateFile)
  }

  try {
    $CertBytes = $X509Certificate.Export('pfx', $CertificatePassword)
    [io.file]::WriteAllBytes($CertificateFile, $CertBytes)
  }
  catch {
    throw ('Unable to export X509Certificate. Exception: {0}' -f $_.Exception.InnerException.Message)
  }

  return $CertificateFile

}


Function Install-X509CertificateToTrustedStores {
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
    [ValidateNotNullOrEmpty()]
    [Alias("StorePassword", "StorePass", "Password", "Pass")]
    [String] $KeyStorePass = "changeit",
    [Parameter(Mandatory = $False, Position = 3)]
    [Alias("SkipGitStore", "SkipGitTrustedStore", "NoGit")]
    [Switch] $SkipGit,
    [Parameter(Mandatory = $False, Position = 3)]
    [Alias("SkipJavaStore", "SkiJavaTrustedStore", "NoJava")]
    [Switch] $SkipJava
  )

  If ($IsLinux) {

    Install-X509CertificateToLinuxTrustedStore -X509Certificate $X509Certificate -CertAlias $CertAlias

  }
  Else {

    Try {
      Install-X509CertificateToWindowsCertStore -X509Certificate $X509Certificate -Scope "LocalMachine" -LocationName "Root"
    }
    Catch {
      Write-Warning "Failed to install certificate to Windows LocalMachine\Root store, trying again in CurrentUser\Root."
      Install-X509CertificateToWindowsCertStore -X509Certificate $X509Certificate -Scope "CurrentUser" -LocationName "Root"
    }

    If (!$SkipGit) {
      Install-X509CertificateToGitTrustedCaBundle -X509Certificate $X509Certificate -CertAlias $CertAlias
    }

    If (!$SkipJava) {
      Install-X509CertificateToJavaTrustedCaKeystores -X509Certificate $X509Certificate -CertAlias $CertAlias -KeyStorePass $KeyStorePass
    }

  }

}
