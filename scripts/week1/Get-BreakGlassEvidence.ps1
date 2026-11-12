<#
.SYNOPSIS
    Captures evidence that the two emergency access (break-glass) accounts exist and hold Global Administrator.

.DESCRIPTION
    READ-ONLY against the tenant. Writes two local files:
      evidence/raw/<EvidenceId>_<date>_break-glass-ga.json     unredacted (gitignored)
      evidence/week1/<EvidenceId>_<date>_break-glass-ga.json   redacted copy (safe to commit)
    Prints the SHA-256 hash of the raw file for the evidence register.

    SC-300: implement and manage emergency access accounts.
    NIST SP 800-171 Rev 2: 3.1.1 (authorized accounts), 3.1.5 (privileged accounts limited and known).

.EXAMPLE
    ./scripts/week1/Get-BreakGlassEvidence.ps1
#>
[CmdletBinding()]
param(
    [string]$EvidenceId    = "EV-001",
    [string]$RepoRoot      = (Resolve-Path "$PSScriptRoot/../..").Path
)

# Real tenant values live in a gitignored local file (see config/lab.example.psd1).
$ConfigPath = Join-Path $RepoRoot "config/lab.local.psd1"
if (-not (Test-Path $ConfigPath)) { throw "Missing $ConfigPath. Copy config/lab.example.psd1 to it and fill in your values." }
$config        = Import-PowerShellDataFile $ConfigPath
$ExpectedAdmin = $config.ExpectedAdmin
$tenantPrefix  = $config.Domain.Split('.')[0]

# Read-only scopes only.
Connect-MgGraph -Scopes "User.Read.All", "RoleManagement.Read.Directory" -NoWelcome -ErrorAction Stop
$ctx = Get-MgContext
if ($ctx.Account -ne $ExpectedAdmin) { throw "Signed in as '$($ctx.Account)', expected '$ExpectedAdmin'." }

$gaTemplateId = "62e90394-69f5-4237-9190-012177145e10"   # Global Administrator (same in every tenant)
$ga      = Get-MgDirectoryRole -Filter "roleTemplateId eq '$gaTemplateId'"
$members = Get-MgDirectoryRoleMember -DirectoryRoleId $ga.Id -All |
           ForEach-Object { $_.AdditionalProperties.userPrincipalName } | Sort-Object

$eaUsers = Get-MgUser -Filter "startswith(userPrincipalName,'pcisd-ea')" `
    -Property DisplayName, UserPrincipalName, AccountEnabled, UserType, OnPremisesSyncEnabled, CreatedDateTime, Department, JobTitle |
    Sort-Object UserPrincipalName |
    ForEach-Object {
        [ordered]@{
            displayName          = $_.DisplayName
            userPrincipalName    = $_.UserPrincipalName
            accountEnabled       = $_.AccountEnabled
            userType             = $_.UserType
            cloudOnly            = -not [bool]$_.OnPremisesSyncEnabled
            createdDateTime      = $_.CreatedDateTime.ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")
            department           = $_.Department
            jobTitle             = $_.JobTitle
            holdsGlobalAdmin     = $members -contains $_.UserPrincipalName
        }
    }

$capturedAt = (Get-Date).ToUniversalTime()
$record = [ordered]@{
    evidenceId        = $EvidenceId
    capturedAtUtc     = $capturedAt.ToString("yyyy-MM-ddTHH:mm:ssZ")
    capturedBy        = $ctx.Account
    tenantId          = $ctx.TenantId
    method            = "Microsoft Graph PowerShell (read-only): Get-MgUser, Get-MgDirectoryRole, Get-MgDirectoryRoleMember"
    scopes            = $ctx.Scopes
    emergencyAccounts = @($eaUsers)
    globalAdminMembers = @($members)
    checks            = [ordered]@{
        twoEmergencyAccountsExist   = (@($eaUsers).Count -eq 2)
        bothHoldGlobalAdmin         = (@($eaUsers | Where-Object { $_.holdsGlobalAdmin }).Count -eq 2)
        bothCloudOnly               = (@($eaUsers | Where-Object { $_.cloudOnly }).Count -eq 2)
        bothEnabled                 = (@($eaUsers | Where-Object { $_.accountEnabled }).Count -eq 2)
    }
}

$name     = "{0}_{1}_break-glass-ga.json" -f $EvidenceId, $capturedAt.ToString("yyyy-MM-dd")
$rawPath  = Join-Path $RepoRoot "evidence/raw/$name"
$redPath  = Join-Path $RepoRoot "evidence/week1/$name"

$json = $record | ConvertTo-Json -Depth 5
Set-Content -Path $rawPath -Value $json -Encoding utf8NoBOM

# Redact: personal-account guest name, tenant domain, tenant ID.
$redacted = $json `
    -replace '[A-Za-z0-9._-]+#EXT#', '<personal-account>#EXT#' `
    -replace [regex]::Escape($tenantPrefix), '<tenant>' `
    -replace [regex]::Escape($ctx.TenantId), '<tenant-id>'
if ($redacted -match [regex]::Escape($tenantPrefix) -or $redacted -match 'gmail') { throw "Redaction incomplete; not writing redacted copy." }
Set-Content -Path $redPath -Value $redacted -Encoding utf8NoBOM

$hash = (Get-FileHash -Path $rawPath -Algorithm SHA256).Hash.ToLower()
"Raw:      evidence/raw/$name"
"Redacted: evidence/week1/$name"
"SHA-256 (raw): $hash"
""
$redacted
