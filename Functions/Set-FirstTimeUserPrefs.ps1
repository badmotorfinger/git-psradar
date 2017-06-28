function Set-FirstTimeUserPrefs() {

    if (-not (Test-Path -Path "$Env:USERPROFILE\.git-psradar")) {

    $upArrowSet1            = '↑' # 24 
    $downArrowSet1          = '↓' # 25
    $rightArrowSet1         = '→' # 26
    $leftArrowSet1          = '←' # 27
    $leftRightArrowSet1     = '↔' # 29

    $upArrowSet2            = '▲' # 30
    $downArrowSet2          = '▼' # 31
    $rightArrowSet2         = '►' # 16
    $leftArrowSet2          = '◄' # 17
    $leftRightArrowSet2     = '◄►'# 29

    $upArrowSet3            = '⬆' # 2B06
    $downArrowSet3          = '⬇' # 2B07
    $rightArrowSet3         = '➡' # 27A1
    $leftArrowSet3          = '⬅' # 2B05
    $leftRightArrowSet3     = '↔' # 2194

    $quest = @"

You are using git-psradar for the first time. Please select the character set which looks best to you:
1. $upArrowSet1 $downArrowSet1 $rightArrowSet1 $leftArrowSet1 $leftRightArrowSet1
2. $upArrowSet2 $downArrowSet2 $rightArrowSet2 $leftArrowSet2 $leftRightArrowSet2
3. $upArrowSet3 $downArrowSet3 $rightArrowSet3 $leftArrowSet3 $leftRightArrowSet3
"@

        $set = Read-Host -Prompt $quest

        if ([int]::TryParse($set, [ref]$set)-and $set -eq 1) {
            Set-Content -Path "$Env:USERPROFILE\.git-psradar" -Value "$upArrowSet1`n$downArrowSet1`n$rightArrowSet1`n$leftArrowSet1`n$leftRightArrowSet1" -Encoding Unicode
        } elseif ([int]::TryParse($set, [ref]$set)-and $set -eq 3) {
            Set-Content -Path "$Env:USERPROFILE\.git-psradar" -Value "$upArrowSet3`n$downArrowSet3`n$rightArrowSet3`n$leftArrowSet3`n$leftRightArrowSet3" -Encoding Unicode
        } else {
            Set-Content -Path "$Env:USERPROFILE\.git-psradar" -Value "$upArrowSet2`n$downArrowSet2`n$rightArrowSet2`n$leftArrowSet2`n$leftRightArrowSet2" -Encoding Unicode
        }
    
        if ((Get-Command "git.exe" -ErrorAction SilentlyContinue) -eq $null) { 
            Write-Host "Git-PsRadar will not work unless git.exe is in your path" -ForegroundColor Red
        }
    }
}