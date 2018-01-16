

# Installs an X509Certificate to all default java keystore certca files found on the system
Function Install-X509CertificateToJavaTrustedCaKeystores {
  [CmdletBinding()]
  Param(
    [Parameter(Mandatory = $True, ValueFromPipelineByPropertyName=$True, Position = 0)]
    [ValidateNotNullOrEmpty()]
    [Alias("CertificateObject", "X509CertificateObject", "X509Certificate2")]
    [System.Security.Cryptography.X509Certificates.X509Certificate2] $X509Certificate,
    [Parameter(Mandatory = $False, ValueFromPipelineByPropertyName=$True, Position = 1)]
    [Alias("FriendlyName", "Name", "Alias", "CertificateAlias")]
    [String] $CertAlias,
    [Parameter(Mandatory = $True, Position = 3)]
    [ValidateNotNullOrEmpty()]
    [Alias("StorePassword", "StorePass", "Password", "Pass")]
    [String] $KeyStorePass = "changeit"
  )

  BEGIN {

    # Gather all java keystores - this is only required once when running multiple times
    $JavaKeystores = Get-JavaCertStores
  }

  PROCESS {

    # Use the common name as alias if no alias has been given
    If ([String]::IsNullOrWhiteSpace($CertAlias)) {
      $CertAlias = Get-X509CommonNameFromSubject -X509Subject $X509Certificate.Subject
    }

    # Remove invalid characters from alias
    $CertAlias = Get-SafeCertificateAlias $CertAlias

    # Export certificate to temporary file
    $TempCertFile = Export-X509Certificate -X509Certificate $X509Certificate

    Try {
      # Import the certificate to all given java keystores
      $JavaKeyStores | Import-TrustedCaCertificateToJavaKeystore -CertAlias $CertAlias -CertFile $TempCertFile -KeyStorePass $KeyStorePass
    }
    Finally {
      # Remove the exported certificate after importing to all stores
      Remove-Item $TempCertFile
    }

  }

}


# Check if certificate exists before adding it
Function Import-TrustedCaCertificateToJavaKeystore {
  [CmdletBinding()]
  Param(
    [Parameter(Mandatory = $True, Position = 0)]
    [ValidateNotNullOrEmpty()]
    [Alias("File", "Certificate", "CertificateFile")]
    [String] $CertFile,
    [Parameter(Mandatory = $True, Position = 1)]
    [ValidateNotNullOrEmpty()]
    [Alias("FriendlyName", "Name", "Alias", "CertificateAlias")]
    [String] $CertAlias,
    [Parameter(Mandatory = $True, ValueFromPipelineByPropertyName=$True, Position = 2)]
    [ValidateNotNullOrEmpty()]
    [Alias("Store", "CertificateStore", "cacerts")]
    [String] $KeyStore,
    [Parameter(Mandatory = $True, ValueFromPipelineByPropertyName=$True, Position = 3)]
    [ValidateNotNullOrEmpty()]
    [Alias("StorePassword", "StorePass", "Password", "Pass")]
    [String] $KeyStorePass = "changeit",
    [Parameter(Mandatory = $True, ValueFromPipelineByPropertyName=$True, Position = 4)]
    [ValidateNotNullOrEmpty()]
    [Alias("JavaKeyTool", "Command")]
    [String] $KeyTool = "keytool"
  )

  If (Test-CertificateExistsWithinJavaKeystore -CertAlias $CertAlias -KeyStore $KeyStore -KeyStorePass $KeyStorePass -KeyTool $KeyTool) {
    Write-Verbose ("Certificate with the alias {0} already exists in {1}." -f $CertAlias, $KeyStore)
    return
  }

  Add-TrustedCaCertificateToJavaKeystore -CertFile $CertFile -CertAlias $CertAlias -KeyStore $KeyStore -KeyStorePass $KeyStorePass -KeyTool $KeyTool

}


# Add certificate to java keystore
Function Add-TrustedCaCertificateToJavaKeystore {
  [CmdletBinding()]
  Param(
    [Parameter(Mandatory = $True, Position = 0)]
    [ValidateNotNullOrEmpty()]
    [Alias("File", "Certificate", "CertificateFile")]
    [String] $CertFile,
    [Parameter(Mandatory = $True, Position = 1)]
    [ValidateNotNullOrEmpty()]
    [Alias("FriendlyName", "Name", "Alias", "CertificateAlias")]
    [String] $CertAlias,
    [Parameter(Mandatory = $True, Position = 2)]
    [ValidateNotNullOrEmpty()]
    [Alias("Store", "CertificateStore", "cacerts")]
    [String] $KeyStore,
    [Parameter(Mandatory = $True, Position = 3)]
    [ValidateNotNullOrEmpty()]
    [Alias("StorePassword", "StorePass", "Password", "Pass")]
    [String] $KeyStorePass,
    [Parameter(Mandatory = $True, Position = 4)]
    [ValidateNotNullOrEmpty()]
    [Alias("JavaKeyTool", "Command")]
    [String] $KeyTool
  )

  $KeyToolCommand = Get-Command "$KeyTool" -ErrorAction Stop

  Try {
    $ExecutionResult = $(& $KeyToolCommand -import -noprompt -trustcacerts -keystore "$KeyStore" -alias "$CertAlias" -file "$CertFile" -storepass "$KeyStorePass")
  }
  Catch {
    Throw ("Encountered problems while trying to import trusted root certificate with alias: {0} to java certificate store {1} - Exception: {2}" -f $CertAlias, $KeyStore, $_.Exception.Message)
  }

  If ($LastExitCode -ne 0) {
    Write-Error ("Unable to import certificate with given alias: {0} to {1}. Keytool Output: `n{2}" -f $CertAlias, $KeyStore, $ExecutionResult)
  }

}


# Test if a certificate with the given alias exists in a java keystore
Function Test-CertificateExistsWithinJavaKeystore {
  [CmdletBinding()]
  Param(
    [Parameter(Mandatory = $True, Position = 0)]
    [ValidateNotNullOrEmpty()]
    [Alias("FriendlyName", "Name", "Alias", "CertificateAlias")]
    [String] $CertAlias,
    [Parameter(Mandatory = $True, Position = 1)]
    [ValidateNotNullOrEmpty()]
    [Alias("Store", "CertificateStore", "cacerts")]
    [String] $KeyStore,
    [Parameter(Mandatory = $True, Position = 2)]
    [ValidateNotNullOrEmpty()]
    [Alias("StorePassword", "StorePass", "Password", "Pass")]
    [String] $KeyStorePass,
    [Parameter(Mandatory = $True, Position = 3)]
    [ValidateNotNullOrEmpty()]
    [Alias("JavaKeyTool", "Command")]
    [String] $KeyTool
  )

  $KeyToolCommand = Get-Command "$KeyTool" -ErrorAction Stop

  Try {
    $ExecutionResult = $(& $KeyToolCommand -list -noprompt -keystore "$KeyStore" -alias "$CertAlias" -storepass "$KeyStorePass")
  }
  Catch {
    Throw ("Encountered problems while trying to check if given alias: {0} is already present in java certificate store {1} - Exception: {2}" -f $CertAlias, $KeyStore, $_.Exception.Message)
  }

  If ($LastExitCode -eq 0) { return $True }

  Write-Verbose ("Unable to find a certificate with given alias: {0} in {1}. Keytool Output: `n{2}" -f $CertAlias, $KeyStore, $ExecutionResult)
  return $False

}


# Returns a list of all java installations within windows default application paths
Function Get-JavaHomes {

  $ValidRoots = @("C:/Program Files/Java", "C:/Program Files (x86)/Java") |
    Where-Object { Test-Path -Path "$_" -PathType Container }

  return Get-ChildItem -Path $ValidRoots -Directory |
    Where-Object { Test-Path -Path $(Join-Path -Path $_.FullName -ChildPath "bin/java.exe") -PathType Leaf } |
    Select-Object -ExpandProperty FullName

}


# Returns a list of cacert keystore files and keytool within a java home under windows
Function Get-JavaHomeCertStoreLocations {
  [CmdletBinding()]
  Param(
    [Parameter(Mandatory = $True, ValueFromPipeline = $True, Position = 0)]
    [String] $JavaHome
  )

  Process {

    # do not check if directory does not exist
    If (!(Test-Path -Path $JavaHome)) { return }

    # use keytool as executeable if no keytool.exe can be found within bin/keytool.exe of java home
    $KeyTool = $(Join-Path -Path $JavaHome -ChildPath "/bin/keytool.exe")
    If (!(Test-Path -Path $KeyTool -PathType Leaf)) { $KeyTool = "keytool" }

    # find existing cacerts files at different locations within java home
    $KeyStores = @("lib/security/cacerts", "jre/lib/security/cacerts") |
      Foreach-Object { Join-Path -Path $JavaHome -ChildPath $_ } |
      Where-Object { Test-Path -Path $_ -PathType Leaf }

    # return PSCustomObject with keystore and keytool locations
    $KeyStores | ForEach-Object { [PSCustomObject] @{
      KeyStore = $_
      KeyTool = $KeyTool
    }}

  }

}


# Returns a list of cacert keystore files and keytool within default windows application paths
Function Get-JavaCertStores {
  Get-JavaHomes | Get-JavaHomeCertStoreLocations
}

