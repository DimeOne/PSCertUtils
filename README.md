# PSCertUtils - PowerShell Module for Certificates

This PowerShell module was designed to allow easy installation of trusted root certificates to the most common certificate stores.


## Features

  - Import certificates from local or remote sources with validation
  - Lookup of default key store locations by default
  - Install trusted root certificates to common certificate stores for:
    - Windows
    - Java
    - Git
    - Other pem bundled key stores
  - Easy to use functions that allows most custom scripts to be written with less then 10 lines of code
  - Modular design that allows for easy reuseablity
  - Generate standalone script that runs without having to install this module



## Usage (Examples)

### Install trusted certificate (simple)

Download, validate and install given certificates and intall them to all certificate stores found.
Since no friendly name was given, a reduced version of the common name is used as friendly name.

```powershell
Get-X509Certificate -CertificateUri https://crt.sh/?d=9314791 -ValidationThumbprint CABD2A79A1076A31F21D253635CB039D4329A5E8 | Install-X509CertificateToTrustedStores
```

### Install trusted certificates (simple)

Download, validate and install given certificates and intall them to all certificate stores found.

```powershell
@(
  (Get-X509Certificate -CertificateUri https://crt.sh/?d=9314791 -ValidationThumbprint CABD2A79A1076A31F21D253635CB039D4329A5E8 -FriendlyName "LE-Root"),
  (Get-X509Certificate -CertificateUri https://crt.sh/?d=9314792 -ValidationThumbprint E045A5A959F42780FA5BD7623512AF276CF42F20 -FriendlyName "Some CA")
) | Install-X509CertificateToTrustedStores
```

### Install trusted certificate (advanced)
```powershell
$Certificate = Get-X509Certificate -CertificateUri https://crt.sh/?d=9314791 -ValidationThumbprint CABD2A79A1076A31F21D253635CB039D4329A5E8 -FriendlyName "LE-Root"

$Certificate | Install-X509CertificateToTrustedStores -SkipGit
```

### Generate Standalone Script

```powershell

$CustomCode = {
@(
  (Get-X509Certificate -CertificateUri https://crt.sh/?d=9314791 -ValidationThumbprint CABD2A79A1076A31F21D253635CB039D4329A5E8 -FriendlyName "LE-Root"),
) | Install-X509CertificateToTrustedStores
}

New-PSCertUtilsStandaloneScript -CustomCode $CustomCode -InstallScript C:\install.ps1

```

## Setup

### Compatibility

While PowerShell Core and Linux have been in

Tested on the following platforms:

  - Windows 10.0.16299 - PowerShell 5.1.16299.98

### Dependencies

### Install


### Upgrade


### Uninstall

## Documentation

The documentation is almost nonexistent, the functions have properly named parameters,
but most do not have a synopsis. I would not expect that changing in the near future.

Basicly this is it.

## Certificate store lookup routines

### Java

### Git

## Testing


## Development


## Sources