---
inclusion: fileMatch
fileMatchPattern: "**/*.{ps1,psm1}"
---

# Microsoft 365 Tenant Manager

Expert guidance for Microsoft 365 Global Administrators. Use this context when working on PowerShell scripts for M365 tenant setup, Azure AD user management, Exchange Online, Teams, Conditional Access, license management, and compliance.

---

## Core Conventions

- Always use **Microsoft Graph PowerShell SDK** (`Microsoft.Graph` module) — not legacy `MSOnline` or `AzureAD` modules
- Connect with least-privilege scopes; declare required scopes explicitly at the top of every script
- Wrap all user-impacting operations in `try/catch` with `Write-Warning` on failure — never silently swallow errors
- Use `-ErrorAction Stop` on critical operations so exceptions are catchable
- Prefer `-Filter` on Graph calls over client-side `Where-Object` for performance
- Always test Conditional Access policies in `enabledForReportingButNotEnforced` before switching to `enabled`
- Use `Write-Host` for progress, `Write-Warning` for non-fatal issues, `throw` for fatal errors

---

## Authentication Pattern

```powershell
# Declare scopes at the top of every script
$requiredScopes = @(
    "Directory.Read.All",
    "Policy.Read.All",
    "AuditLog.Read.All"
)
Connect-MgGraph -Scopes $requiredScopes
```

---

## Workflow 1: New Tenant Setup

**Step 1 — Verify DNS propagation before bulk operations**
```powershell
$domain = "company.com"
Resolve-DnsName -Name "_msdcs.$domain" -Type NS -ErrorAction SilentlyContinue
# DNS can take up to 48h — do not proceed with user creation until verified
```

**Step 2 — Apply security baseline**
```powershell
# Block legacy authentication via Conditional Access
$policy = @{
    DisplayName  = "Block Legacy Authentication"
    State        = "enabled"
    Conditions   = @{ ClientAppTypes = @("exchangeActiveSync", "other") }
    GrantControls = @{ Operator = "OR"; BuiltInControls = @("block") }
}
New-MgIdentityConditionalAccessPolicy -BodyParameter $policy

# Enable unified audit log (Exchange Online)
Set-AdminAuditLogConfig -UnifiedAuditLogIngestionEnabled $true
```

**Step 3 — Bulk provision users from CSV**

CSV must have columns: `DisplayName`, `UserPrincipalName`, `Department`, `LicenseSku`

```powershell
$licenseSku = (Get-MgSubscribedSku |
    Where-Object { $_.SkuPartNumber -eq "ENTERPRISEPACK" }).SkuId

Import-Csv .\employees.csv | ForEach-Object {
    try {
        $user = New-MgUser -DisplayName $_.DisplayName `
            -UserPrincipalName $_.UserPrincipalName `
            -AccountEnabled `
            -PasswordProfile @{
                Password                      = (New-Guid).ToString().Substring(0, 12) + "!"
                ForceChangePasswordNextSignIn = $true
            }
        Set-MgUserLicense -UserId $user.Id `
            -AddLicenses @(@{ SkuId = $licenseSku }) `
            -RemoveLicenses @()
        Write-Host "Provisioned: $($_.UserPrincipalName)"
    } catch {
        Write-Warning "Failed $($_.UserPrincipalName): $_"
    }
}
```

---

## Workflow 2: Conditional Access Policies

Always start in report-only mode. Review sign-in logs before enforcing.

```powershell
# Require MFA for all admin roles — report-only first
$adminRoleIds = (Get-MgDirectoryRole |
    Where-Object { $_.DisplayName -match "Admin" }).Id

$policy = @{
    DisplayName   = "Require MFA for Admins"
    State         = "enabledForReportingButNotEnforced"
    Conditions    = @{ Users = @{ IncludeRoles = $adminRoleIds } }
    GrantControls = @{ Operator = "OR"; BuiltInControls = @("mfa") }
}
New-MgIdentityConditionalAccessPolicy -BodyParameter $policy
# Switch State to "enabled" only after reviewing report-only sign-in logs
```

---

## Workflow 3: Security Audit

```powershell
# Users without MFA registered
Get-MgUser -All | ForEach-Object {
    $methods = Get-MgUserAuthenticationMethod -UserId $_.Id
    if ($methods.Count -le 1) {
        Write-Warning "No MFA: $($_.UserPrincipalName)"
    }
}

# Guest users — review for stale or unnecessary access
Get-MgUser -Filter "userType eq 'Guest'" |
    Select-Object DisplayName, UserPrincipalName, CreatedDateTime

# Global Administrator role members — should be minimal
$gaRole = Get-MgDirectoryRole | Where-Object { $_.DisplayName -eq "Global Administrator" }
Get-MgDirectoryRoleMember -DirectoryRoleId $gaRole.Id
```

---

## Common Admin Tasks

| Task | Command |
|------|---------|
| Check license usage | `Get-MgSubscribedSku \| Select-Object SkuPartNumber, ConsumedUnits, @{N="Total";E={$_.PrepaidUnits.Enabled}}` |
| Reset password | `Update-MgUser -UserId $id -PasswordProfile @{ Password = "..."; ForceChangePasswordNextSignIn = $true }` |
| Disable account | `Update-MgUser -UserId $id -AccountEnabled $false` |
| Add user to group | `New-MgGroupMember -GroupId $gid -DirectoryObjectId $uid` |
| Assign license | `Set-MgUserLicense -UserId $id -AddLicenses @(@{ SkuId = $sku }) -RemoveLicenses @()` |
| Revoke active sessions | `Revoke-MgUserSignInSession -UserId $id` |

---

## Security Checklist

Before considering a tenant configuration complete, verify:

- [ ] Legacy authentication blocked via Conditional Access
- [ ] MFA required for all administrator roles
- [ ] MFA required for all users
- [ ] Unified audit log enabled
- [ ] Guest access reviewed and restricted
- [ ] Privileged role assignments minimized (principle of least privilege)
- [ ] All Conditional Access policies validated in report-only before enforcing
- [ ] Break-glass (emergency access) accounts configured and excluded from CA policies
