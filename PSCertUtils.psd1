@{

  RootModule = 'PSCertUtils.psm1'
  ModuleVersion = '0.3.0'

  GUID = '245cc162-e088-4295-81e4-febbb16ca4bf'
  Author = 'Dominic S.'
  CompanyName = 'ME'
  Description = 'PowerShell module with functions for X509Certificate handling and easy installation of trusted root certificates.'
  #ProjectUri = 'https://github.com/DimeOne/PSCertUtils'
  #LicenseUri = 'https://github.com/DimeOne/PSCertUtils/blob/master/LICENSE'
  #IconUri = 'https://raw.githubusercontent.com/DimeOne/PSCertUtils/master/assets/PSCertUtils.png'

  NestedModules = @(
    "PSCertUtils.Helpers.psm1",
    "PSCertUtils.Bundles.psm1",
    "PSCertUtils.Windows.psm1",
    "PSCertUtils.Linux.psm1",
    "PSCertUtils.Java.psm1",
    "PSCertUtils.Git.psm1"
  )

  FunctionsToExport = @(
    'Get-X509Certificate',
    'Export-X509Certificate',
    'Export-X509CertificatePfx',
    "Get-X509CommonNameFromSubject",
    "Install-X509CertificateToTrustedStores",
    "Install-X509CertificateToWindowsCertStore",
    "Install-X509CertificateToLinuxTrustedStore",
    "Install-X509CertificateToJavaTrustedCaKeystores",
    "Install-X509CertificateToGitTrustedCaBundle",
    "Get-SafeCertificateAlias",
    "Get-JavaHomes",
    "Get-JavaHomeCertStoreLocations",
    "Get-JavaCertStores",
    "Import-TrustedCaCertificateToJavaKeystore",
    "Add-TrustedCaCertificateToJavaKeystore",
    "Test-CertificateExistsWithinJavaKeystore",
    "Get-GitCurlBundlePath",
    "Import-X509CertificateToBundle",
    "Add-X509CertificateToBundle",
    "Test-X509CertificateExistsWithinBundle",
    "New-PSCertUtilsStandaloneScript"
  )

  CmdletsToExport = @()
  VariablesToExport = @()
  AliasesToExport = @()

  PrivateData = @{
    PSData = @{
      Tags = @("Certitifcate", "Cert", "CertUtils", "Install", "Setup", "Security", "Trust", "Root")
      LicenseUri = 'https://github.com/DimeOne/PSCertUtils/blob/master/LICENSE'
      ProjectUri = 'https://github.com/DimeOne/PSCertUtils'
      IconUri = 'https://raw.githubusercontent.com/DimeOne/PSCertUtils/master/assets/PSCertUtils.png'
      # ReleaseNotes = ''
    }
  }

}
