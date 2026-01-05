#requires -version 7.0
[CmdletBinding()]
param(
    [ValidateSet('Enforce', 'Allow')]
    [string]$Mode = 'Enforce'
)

$expectedMajor = 7
if ($PSVersionTable.PSVersion.Major -ne $expectedMajor) {
    Write-Error "This script requires PowerShell 7.x."
    exit 1
}

$ErrorActionPreference = 'Stop'

Import-Module NetSecurity -ErrorAction Stop

$isAdmin = ([Security.Principal.WindowsPrincipal] `
    [Security.Principal.WindowsIdentity]::GetCurrent() `
).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if (-not $isAdmin) {
    Write-Error "Run this script as Administrator."
    exit 1
}

$group = 'SurgeFirewall'
$rulePrefix = 'SurgeAllow'
$fqdns = @(
    "*.aadcdn.microsoftonline-p.com"
    "*.aaplimg.com"
    "*.apple-cloudkit.com"
    "*.apple-dns.net"
    "*.apple-mapkit.com"
    "*.apple.com"
    "*.apple.com.cn"
    "*.apple.news"
    "*.applemusic.com"
    "*.appstore.com"
    "*.azure.com"
    "*.bing.com"
    "*.bing.net"
    "*.cdn-apple.com"
    "*.cdn.office.net"
    "*.enterpriseregistration.windows.net"
    "*.icloud-content.com"
    "*.icloud.com"
    "*.itunes.com"
    "*.live.com"
    "*.mac.com"
    "*.me.com"
    "*.microsoft.com"
    "*.microsoftonline.com"
    "*.microsoftstore.com"
    "*.microsoftupdate.com"
    "*.msauth.net"
    "*.msauthimages.net"
    "*.msftauth.net"
    "*.msftauthimages.net"
    "*.msn.com"
    "*.mzstatic.com"
    "*.office.com"
    "*.office365.com"
    "*.outlook.com"
    "*.skype.com"
    "*.surface.com"
    "*.windows.com"
    "*.windowsupdate.com"
    "*.xbox.com"
    "*.xboxlive.com"
    "aadcdn.microsoftonline-p.com"
    "aaplimg.com"
    "account.microsoft.com"
    "apple-cloudkit.com"
    "apple-dns.net"
    "apple-mapkit.com"
    "apple.com"
    "apple.com.cn"
    "apple.news"
    "applemusic.com"
    "appstore.com"
    "azure.com"
    "bing.com"
    "bing.net"
    "cdn-apple.com"
    "cdn.office.net"
    "device.login.microsoftonline.com"
    "docs.microsoft.com"
    "download.microsoft.com"
    "download.windowsupdate.com"
    "enrollment.manage.microsoft.com"
    "enterpriseenrollment.manage.microsoft.com"
    "enterpriseregistration.windows.net"
    "graph.microsoft.com"
    "graph.windows.net"
    "hosting.portal.azure.net"
    "icloud-content.com"
    "icloud.com"
    "itunes.com"
    "learn.microsoft.com"
    "live.com"
    "login.live.com"
    "login.microsoft.com"
    "login.microsoftonline.com"
    "login.windows.net"
    "mac.com"
    "manage.microsoft.com"
    "management.azure.com"
    "me.com"
    "microsoft.com"
    "microsoftonline.com"
    "microsoftstore.com"
    "microsoftupdate.com"
    "msauth.net"
    "msauthimages.net"
    "msftauth.net"
    "msftauthimages.net"
    "msn.com"
    "mzstatic.com"
    "office.com"
    "office365.com"
    "officecdn.microsoft.com"
    "outlook.com"
    "portal.azure.com"
    "portal.manage.microsoft.com"
    "reactblade.portal.azure.net"
    "skype.com"
    "support.microsoft.com"
    "surface.com"
    "update.microsoft.com"
    "windows.com"
    "windowsupdate.com"
    "xbox.com"
    "xboxlive.com"
)

Get-NetFirewallRule -Group $group -ErrorAction SilentlyContinue | Remove-NetFirewallRule

New-NetFirewallRule -DisplayName "$rulePrefix-DNS-UDP" -Group $group `
    -Direction Outbound -Action Allow -Protocol UDP -RemotePort 53 | Out-Null
New-NetFirewallRule -DisplayName "$rulePrefix-DNS-TCP" -Group $group `
    -Direction Outbound -Action Allow -Protocol TCP -RemotePort 53 | Out-Null

$chunkSize = 50
for ($i = 0; $i -lt $fqdns.Count; $i += $chunkSize) {
    $end = [Math]::Min($i + $chunkSize - 1, $fqdns.Count - 1)
    $chunk = $fqdns[$i..$end]
    New-NetFirewallRule -DisplayName "$rulePrefix-FQDN-$i" -Group $group `
        -Direction Outbound -Action Allow -RemoteFqdn $chunk | Out-Null
}

if ($Mode -eq 'Enforce') {
    Set-NetFirewallProfile -Profile Domain,Public,Private -DefaultOutboundAction Block | Out-Null
} else {
    Set-NetFirewallProfile -Profile Domain,Public,Private -DefaultOutboundAction Allow | Out-Null
}

Write-Host "Windows firewall rules applied (mode: $Mode)."
