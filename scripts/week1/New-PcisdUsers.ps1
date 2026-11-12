<#
.SYNOPSIS
    Bulk-creates Prairie Creek ISD users from data/pcisd-users.csv.

.DESCRIPTION
    Week 1 task: bulk user creation (SC-300: create, configure, and manage users, including bulk operations).
    - Skips anyone who already exists (safe to run more than once).
    - Generates a random password for each user IN MEMORY ONLY. Passwords are never displayed or saved.
      Reset a user's password in the portal (or issue a Temporary Access Pass) when you need to sign in as them.
    - Dates in the CSV are treated as midnight US Central time and stored in UTC, matching the portal.
    - Run with -WhatIf first to preview what would be created without changing anything.

.EXAMPLE
    ./scripts/week1/New-PcisdUsers.ps1 -WhatIf     # dry run: changes nothing
    ./scripts/week1/New-PcisdUsers.ps1             # creates the users
#>
[CmdletBinding(SupportsShouldProcess)]
param(
    [string]$CsvPath    = "$PSScriptRoot/../../data/pcisd-users.csv",
    [string]$ConfigPath = "$PSScriptRoot/../../config/lab.local.psd1"
)

# Real tenant values live in a gitignored local file (see config/lab.example.psd1).
if (-not (Test-Path $ConfigPath)) { throw "Missing $ConfigPath. Copy config/lab.example.psd1 to it and fill in your values." }
$config        = Import-PowerShellDataFile $ConfigPath
$Domain        = $config.Domain
$ExpectedAdmin = $config.ExpectedAdmin

# 1. Sign in with only the permissions this task needs.
Connect-MgGraph -Scopes "User.ReadWrite.All", "User-LifeCycleInfo.ReadWrite.All" -NoWelcome -ErrorAction Stop

# 2. Safety check: stop if signed in as anyone other than the lab admin.
$account = (Get-MgContext).Account
if ($account -ne $ExpectedAdmin) {
    throw "Signed in as '$account'. Expected '$ExpectedAdmin'. Stopping without changes."
}
Write-Host "Signed in as $account" -ForegroundColor Green

# 3. Helpers.
$central = [TimeZoneInfo]::FindSystemTimeZoneById("America/Chicago")
function ConvertTo-UtcIso([string]$date) {
    # "2018-08-13" -> midnight Central -> "2018-08-13T05:00:00Z"
    $local = [datetime]::ParseExact($date, "yyyy-MM-dd", $null)
    [TimeZoneInfo]::ConvertTimeToUtc($local, $central).ToString("yyyy-MM-ddTHH:mm:ssZ")
}
function New-RandomPassword {
    # 20 random characters from a cryptographically secure generator; retry until it has upper, lower, digit.
    $chars = 'ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz23456789!@#$%*-_'
    do {
        $pw = -join (1..20 | ForEach-Object { $chars[[Security.Cryptography.RandomNumberGenerator]::GetInt32($chars.Length)] })
    } until ($pw -cmatch '[A-Z]' -and $pw -cmatch '[a-z]' -and $pw -match '\d')
    $pw
}

# 4. Create each user.
$results = foreach ($row in Import-Csv -Path $CsvPath) {
    $upn = "$($row.UpnPrefix)@$Domain"

    if (Get-MgUser -Filter "userPrincipalName eq '$upn'" -ErrorAction SilentlyContinue) {
        [pscustomobject]@{ User = $upn; Result = "Skipped (already exists)" }
        continue
    }

    if (-not $PSCmdlet.ShouldProcess($upn, "Create user ($($row.JobTitle), $($row.Department))")) {
        [pscustomobject]@{ User = $upn; Result = "WhatIf (not created)" }
        continue
    }

    try {
        $body = @{
            accountEnabled    = $true
            displayName       = $row.DisplayName
            givenName         = $row.GivenName
            surname           = $row.Surname
            mailNickname      = $row.UpnPrefix
            userPrincipalName = $upn
            jobTitle          = $row.JobTitle
            department        = $row.Department
            employeeId        = $row.EmployeeId
            employeeHireDate  = ConvertTo-UtcIso $row.EmployeeHireDate
            usageLocation     = $row.UsageLocation
            passwordProfile   = @{
                password                      = New-RandomPassword
                forceChangePasswordNextSignIn = $true
            }
        }
        $user = New-MgUser -BodyParameter $body -ErrorAction Stop
        $note = "Created"

        # Leave date is set separately: it needs an extra permission and may fail on some licenses.
        if ($row.EmployeeLeaveDateTime) {
            try {
                Update-MgUser -UserId $user.Id -BodyParameter @{ employeeLeaveDateTime = ConvertTo-UtcIso $row.EmployeeLeaveDateTime } -ErrorAction Stop
                $note += " + leave date"
            } catch {
                $note += " (leave date FAILED: $($_.Exception.Message))"
            }
        }
        [pscustomobject]@{ User = $upn; Result = $note }
    } catch {
        [pscustomobject]@{ User = $upn; Result = "FAILED: $($_.Exception.Message)" }
    }
}

# 5. Summary to the terminal only (no log file, no passwords).
$results | Format-Table -AutoSize
$results | Group-Object { ($_.Result -split '[ (:]')[0] } | Select-Object Name, Count | Format-Table -AutoSize
