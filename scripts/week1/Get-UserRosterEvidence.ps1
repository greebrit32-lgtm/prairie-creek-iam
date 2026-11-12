<#
.SYNOPSIS
    Captures evidence that the roster users exist with correct attributes, reconciled against data/pcisd-users.csv.

.DESCRIPTION
    READ-ONLY against the tenant. Writes:
      evidence/raw/<EvidenceId>_<date>_user-roster.json     unredacted (gitignored)
      evidence/week1/<EvidenceId>_<date>_user-roster.json   redacted copy (safe to commit)

    Checks: every CSV row exists; jobTitle/department/employeeId/hire date/leave date match;
    no unexpected users with an employeeId; no roster user holds a directory (admin) role.

    SC-300: create, configure, and manage users, including bulk operations.
    NIST SP 800-171 Rev 2: 3.5.1 (unique identification), 3.5.9 (temporary passwords changed at first sign-in),
    3.1.5 (regular users hold no privileged roles).
#>
[CmdletBinding()]
param(
    [string]$EvidenceId    = "EV-002",
    [string]$RepoRoot      = (Resolve-Path "$PSScriptRoot/../..").Path
)

# Real tenant values live in a gitignored local file (see config/lab.example.psd1).
$ConfigPath = Join-Path $RepoRoot "config/lab.local.psd1"
if (-not (Test-Path $ConfigPath)) { throw "Missing $ConfigPath. Copy config/lab.example.psd1 to it and fill in your values." }
$config        = Import-PowerShellDataFile $ConfigPath
$Domain        = $config.Domain
$ExpectedAdmin = $config.ExpectedAdmin
$tenantPrefix  = $Domain.Split('.')[0]

Connect-MgGraph -Scopes "User.Read.All", "User-LifeCycleInfo.Read.All", "RoleManagement.Read.Directory" -NoWelcome -ErrorAction Stop
$ctx = Get-MgContext
if ($ctx.Account -ne $ExpectedAdmin) { throw "Signed in as '$($ctx.Account)', expected '$ExpectedAdmin'." }

$central = [TimeZoneInfo]::FindSystemTimeZoneById("America/Chicago")
function To-CentralDate($dt) {
    if (-not $dt) { return "" }
    [TimeZoneInfo]::ConvertTimeFromUtc(([datetime]$dt).ToUniversalTime(), $central).ToString("yyyy-MM-dd")
}

$csv = Import-Csv (Join-Path $RepoRoot "data/pcisd-users.csv")

# Every user that has an employeeId (the roster population).
$props = "Id,DisplayName,UserPrincipalName,JobTitle,Department,EmployeeId,EmployeeHireDate,EmployeeLeaveDateTime,UsageLocation,AccountEnabled,UserType,CreatedDateTime,PasswordProfile"
$tenantUsers = Get-MgUser -All -Property $props | Where-Object { $_.EmployeeId }

# Everyone who holds any activated directory role.
$roleHolders = @{}
foreach ($role in Get-MgDirectoryRole -All) {
    foreach ($m in Get-MgDirectoryRoleMember -DirectoryRoleId $role.Id -All) {
        $upn = $m.AdditionalProperties.userPrincipalName
        if (-not $upn) { continue }
        if (-not $roleHolders.ContainsKey($upn)) { $roleHolders[$upn] = [System.Collections.Generic.List[string]]::new() }
        $roleHolders[$upn].Add($role.DisplayName)
    }
}

$rows = foreach ($r in $csv) {
    $upn = "$($r.UpnPrefix)@$Domain"
    $u = $tenantUsers | Where-Object { $_.UserPrincipalName -eq $upn }
    $mismatch = @()
    if ($u) {
        if ($u.JobTitle   -ne $r.JobTitle)   { $mismatch += "jobTitle" }
        if ($u.Department -ne $r.Department) { $mismatch += "department" }
        if ($u.EmployeeId -ne $r.EmployeeId) { $mismatch += "employeeId" }
        if ((To-CentralDate $u.EmployeeHireDate) -ne $r.EmployeeHireDate) { $mismatch += "employeeHireDate" }
        if ((To-CentralDate $u.EmployeeLeaveDateTime) -ne $r.EmployeeLeaveDateTime) { $mismatch += "employeeLeaveDateTime" }
        if ($u.UsageLocation -ne $r.UsageLocation) { $mismatch += "usageLocation" }
    }
    [ordered]@{
        employeeId                    = $r.EmployeeId
        displayName                   = $r.DisplayName
        userPrincipalName             = $upn
        existsInTenant                = [bool]$u
        jobTitle                      = $u.JobTitle
        department                    = $u.Department
        employeeHireDate              = To-CentralDate $u.EmployeeHireDate
        employeeLeaveDate             = To-CentralDate $u.EmployeeLeaveDateTime
        usageLocation                 = $u.UsageLocation
        accountEnabled                = $u.AccountEnabled
        userType                      = $u.UserType
        forceChangePasswordNextSignIn = $u.PasswordProfile.ForceChangePasswordNextSignIn
        directoryRoles                = if ($roleHolders.ContainsKey($upn)) { @($roleHolders[$upn]) } else { @() }
        mismatches                    = $mismatch
    }
}

$csvUpns    = $csv | ForEach-Object { "$($_.UpnPrefix)@$Domain" }
$unexpected = @($tenantUsers | Where-Object { $_.UserPrincipalName -notin $csvUpns } | ForEach-Object UserPrincipalName)

$capturedAt = (Get-Date).ToUniversalTime()
$record = [ordered]@{
    evidenceId     = $EvidenceId
    capturedAtUtc  = $capturedAt.ToString("yyyy-MM-ddTHH:mm:ssZ")
    capturedBy     = $ctx.Account
    tenantId       = $ctx.TenantId
    method         = "Microsoft Graph PowerShell (read-only): Get-MgUser, Get-MgDirectoryRole, Get-MgDirectoryRoleMember; reconciled against data/pcisd-users.csv"
    source         = "data/pcisd-users.csv ($(@($csv).Count) rows)"
    checks         = [ordered]@{
        csvRows                    = @($csv).Count
        foundInTenant              = @($rows | Where-Object { $_.existsInTenant }).Count
        allCsvUsersPresent         = -not ($rows | Where-Object { -not $_.existsInTenant })
        allAttributesMatch         = -not ($rows | Where-Object { $_.mismatches.Count })
        uniqueUpns                 = (@($rows.userPrincipalName | Select-Object -Unique).Count -eq @($rows).Count)
        unexpectedUsersWithEmpId   = $unexpected
        rosterUsersWithAdminRoles  = @($rows | Where-Object { $_.directoryRoles.Count } | ForEach-Object { $_.userPrincipalName })
    }
    users          = @($rows)
}

$name    = "{0}_{1}_user-roster.json" -f $EvidenceId, $capturedAt.ToString("yyyy-MM-dd")
$rawPath = Join-Path $RepoRoot "evidence/raw/$name"
$redPath = Join-Path $RepoRoot "evidence/week1/$name"

$json = $record | ConvertTo-Json -Depth 6
Set-Content -Path $rawPath -Value $json -Encoding utf8NoBOM
$redacted = $json `
    -replace '[A-Za-z0-9._-]+#EXT#', '<personal-account>#EXT#' `
    -replace [regex]::Escape($tenantPrefix), '<tenant>' `
    -replace [regex]::Escape($ctx.TenantId), '<tenant-id>'
if ($redacted -match [regex]::Escape($tenantPrefix) -or $redacted -match 'gmail') { throw "Redaction incomplete; not writing redacted copy." }
Set-Content -Path $redPath -Value $redacted -Encoding utf8NoBOM

"Raw:      evidence/raw/$name"
"Redacted: evidence/week1/$name"
"SHA-256 (raw): $((Get-FileHash -Path $rawPath -Algorithm SHA256).Hash.ToLower())"
""
$record.checks | ConvertTo-Json -Depth 3
""
$rows | ForEach-Object { [pscustomobject]$_ } |
    Select-Object employeeId, displayName, jobTitle, department, employeeHireDate, employeeLeaveDate, forceChangePasswordNextSignIn, @{n="mismatches";e={$_.mismatches -join ","}} |
    Format-Table -AutoSize | Out-String -Width 220
