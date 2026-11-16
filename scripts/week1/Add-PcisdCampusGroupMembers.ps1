<#
.SYNOPSIS
    Adds every enabled roster user from one campus (Department attribute) to that campus's static staff group.

.DESCRIPTION
    Week 1 task: attribute-based group assignment (joiner automation).
    SC-300: create, configure, and manage groups; automate with Microsoft Graph PowerShell.
    NIST SP 800-171 Rev 2: 3.1.1 / 3.1.2 (access granted through controlled group membership).

    - Matches on TWO attributes: Department (campus) and JobTitle. Students share the campus Department
      value with staff, so job titles in -ExcludeJobTitle (default: Student) are left out. The first dry
      run (2026-11-15) caught this: department alone would have put 3 students in a staff group.
    - Adds only. It never removes anyone; users in the group who no longer match are REPORTED for a human
      to review (mover/leaver handling comes later in the lab).
    - Skips users who are already members (safe to run more than once).
    - Refuses to touch role-assignable groups or any group with "Restricted" in its name: restricted
      membership is a human decision, not an attribute match.
    - Run with -WhatIf first to preview without changing anything.

.EXAMPLE
    ./scripts/week1/Add-PcisdCampusGroupMembers.ps1 -GroupName "Bluebonnet Middle School - Staff" -Department "Bluebonnet Middle School" -WhatIf
#>
[CmdletBinding(SupportsShouldProcess)]
param(
    [Parameter(Mandatory)] [string]$GroupName,
    [Parameter(Mandatory)] [string]$Department,
    # Department is the campus, which students share with staff. Staff groups must exclude these job titles.
    [string[]]$ExcludeJobTitle = @('Student'),
    [string]$ConfigPath = "$PSScriptRoot/../../config/lab.local.psd1"
)

# Real tenant values live in a gitignored local file (see config/lab.example.psd1).
if (-not (Test-Path $ConfigPath)) { throw "Missing $ConfigPath. Copy config/lab.example.psd1 to it and fill in your values." }
$config = Import-PowerShellDataFile $ConfigPath

# 1. Sign in with least privilege: read users, change group membership only (not group settings).
Connect-MgGraph -Scopes "User.Read.All", "GroupMember.ReadWrite.All" -NoWelcome -ErrorAction Stop

# 2. Safety check: stop if signed in as anyone other than the lab admin.
$account = (Get-MgContext).Account
if ($account -ne $config.ExpectedAdmin) { throw "Signed in as '$account'. Expected the lab admin. Stopping without changes." }
Write-Host "Signed in as the lab admin" -ForegroundColor Green

# 3. Find exactly one group with this exact name, and refuse sensitive groups.
$safeName = $GroupName.Replace("'", "''")
$groups = @(Get-MgGroup -Filter "displayName eq '$safeName'" -Property Id, DisplayName, SecurityEnabled, IsAssignableToRole, MembershipRule)
if ($groups.Count -ne 1) { throw "Expected exactly 1 group named '$GroupName', found $($groups.Count). Stopping." }
$group = $groups[0]
if ($group.IsAssignableToRole)  { throw "'$GroupName' is role-assignable. This script won't modify it." }
if ($group.MembershipRule)      { throw "'$GroupName' is a dynamic group; Entra manages its members." }
if ($GroupName -match 'Restricted') { throw "'$GroupName' is a restricted group. Add members by hand after approval." }

# 4. Who SHOULD be in it: enabled member users with an employeeId (roster) in this department,
#    minus excluded job titles (students share the campus Department value with staff).
$safeDept = $Department.Replace("'", "''")
$targets = @(Get-MgUser -All -Filter "department eq '$safeDept' and accountEnabled eq true and userType eq 'Member'" `
    -ConsistencyLevel eventual -CountVariable n -Property Id, DisplayName, UserPrincipalName, JobTitle, EmployeeId |
    Where-Object { $_.EmployeeId -and $_.JobTitle -notin $ExcludeJobTitle })
if ($targets.Count -eq 0) { throw "No enabled roster users found with department '$Department'. Check the spelling. Stopping." }

# 5. Who IS in it now. (Property access, not ForEach-Object, so -WhatIf doesn't print noise.)
#    Where-Object drops the $null you'd otherwise get from an empty group (@($null) has Count 1).
$currentIds = @((Get-MgGroupMember -GroupId $group.Id -All).Id | Where-Object { $_ })

# 6. Add anyone missing.
$results = foreach ($u in $targets) {
    if ($currentIds -contains $u.Id) {
        [pscustomobject]@{ User = $u.DisplayName; JobTitle = $u.JobTitle; Result = "Skipped (already a member)" }
        continue
    }
    if (-not $PSCmdlet.ShouldProcess("$($u.DisplayName) ($($u.JobTitle))", "Add to '$GroupName'")) {
        [pscustomobject]@{ User = $u.DisplayName; JobTitle = $u.JobTitle; Result = "WhatIf (not added)" }
        continue
    }
    try {
        New-MgGroupMember -GroupId $group.Id -DirectoryObjectId $u.Id -ErrorAction Stop
        [pscustomobject]@{ User = $u.DisplayName; JobTitle = $u.JobTitle; Result = "Added" }
    } catch {
        [pscustomobject]@{ User = $u.DisplayName; JobTitle = $u.JobTitle; Result = "FAILED: $($_.Exception.Message)" }
    }
}

# 7. Report (never remove) members who don't match the department rule.
$targetIds = @($targets.Id)
$extras = @($currentIds | Where-Object { $_ -notin $targetIds })

# 8. Summary to the terminal only.
$results | Format-Table -AutoSize
$results | Group-Object { ($_.Result -split '[ (:]')[0] } | Select-Object Name, Count | Format-Table -AutoSize
if ($extras.Count) {
    Write-Warning "$($extras.Count) current member(s) do not match department '$Department'. Review them by hand (not removed):"
    $extras | ForEach-Object { (Get-MgDirectoryObject -DirectoryObjectId $_).AdditionalProperties.displayName }
} else {
    "No unexpected members."
}
