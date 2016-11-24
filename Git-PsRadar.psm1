<#

.SYNOPSIS

   A heads up display for git. A port of https://github.com/michaeldfallen/git-radar

.DESCRIPTION

    Provides an at-a-glance information about your git repo.

.LINK

   https://github.com/vincpa/git-psradar

#>

$arrows = @{upArrow = '↑';downArrow = '↓';rightArrow = '→';leftArrow = '←'; leftRightArrow = '↔'}
$arrows = New-Object –TypeName PSObject –Prop $arrows

function Write-Chost($message = ""){

    if ( $message ){

        # predefined Color Array
        $colors = @("black","blue","cyan","darkblue","darkcyan","darkgray","darkgreen","darkmagenta","darkred","darkyellow","gray","green","magenta","red","white","yellow");    

        # Set CurrentColor to default Foreground Color
        $CurrentColor = $defaultFGColor

        # Split Messages
        $message = $message.split("#")

        # Iterate through splitted array
        foreach( $string in $message ){
            if ($string) {
                # If a string between #-Tags is equal to any predefined color, and is equal to the defaultcolor: set current color
                if ( $colors -contains $string.tolower()){
                    $CurrentColor = $string          
                }else{
                    # If string is a output message, than write string with current color (with no line break)
                    if ($CurrentColor -ne $null -and $CurrentColor -ne -1) {
                        write-host -nonewline -f $CurrentColor $string
                    } else {
                        write-host -nonewline $string
                    }
                }
            }
        }
    }
}

function Get-StatusString($porcelainString) {
    $results = @{
        Staged = @{
            Modified = 0;
            Deleted = 0;
            Added = 0;
            Renamed = 0;
            Copied = 0;
        };
        Unstaged = @{
            Modified = 0;
            Deleted = 0;
            Renamed = 0;
            Copied = 0;
        };
        Untracked = @{
            Added = 0;
        };
        Conflicted = @{
            ConflictUs = 0;
            ConflictThem = 0;
            Conflict = 0;
        }
    }

    if ($porcelainString -ne '' -and $porcelainStatus -ne $null) {

        $porcelainString.Split([Environment]::NewLine) | % {
            if ($_[0] -eq 'R') { $results.Staged.Renamed++; }
            elseif ($_[0] -eq 'A') { $results.Staged.Added++ }
            elseif ($_[0] -eq 'D') { $results.Staged.Deleted++ }
            elseif ($_[0] -eq 'M') { $results.Staged.Modified++ }
            elseif ($_[0] -eq 'C') { $results.Staged.Copied++ }

            if ($_[1] -eq 'R') { $results.Unstaged.Renamed++ }
            elseif ($_[1] -eq 'D') { $results.Unstaged.Deleted++ }
            elseif ($_[1] -eq 'M') { $results.Unstaged.Modified++ }
            elseif ($_[1] -eq 'C') { $results.Unstaged.Copied++ }
            if($_[1] -eq '?') { $results.Untracked.Added++ }

            elseif ($_[1] -eq 'U') { $results.Conflicted.ConflictUs++ }
            elseif ($_[1] -eq 'T') { $results.Conflicted.ConflictThem++ }
            elseif ($_[1] -eq 'B') { $results.Conflicted.Conflict++ }
        }
    }
    return $results
}

function Get-Staged($seed, $status, $color, $showNewFiles, $onlyShowNewFiles) {
    
    $result = (Get-StatusCountFragment $seed   $status.Added        'A' $color)
    $result = (Get-StatusCountFragment $result $status.Renamed      'R' $color)
    $result = (Get-StatusCountFragment $result $status.Deleted      'D' $color)
    $result = (Get-StatusCountFragment $result $status.Modified     'M' $color)
    $result = (Get-StatusCountFragment $result $status.Copied       'C' $color)
    $result = (Get-StatusCountFragment $result $status.ConflictUs   'U' $color)
    $result = (Get-StatusCountFragment $result $status.ConflictThem 'T' $color)
    $result = (Get-StatusCountFragment $result $status.Conflict     'B' $color)
    $result = (Get-StatusCountFragment $result $status.RemoteAhead  $arrows.downArrow $color)
    $result = (Get-StatusCountFragment $result $status.LocalAhead   $arrows.upArrow $color)

    if (-not [string]::IsNullOrWhiteSpace($result) -and $seed.Length -ne $result.Length) {
        $result += ' '
    }
    return $result
}

function Get-StatusCountFragment($seed, $count, $symbol, $color) {
    if ($count -gt 0) {
        return "$seed#white#$count#$color#$symbol"
    }
    return $seed;
}

function Get-FilesStatus() {
    
    $porcelainStatus = git status --porcelain;

    $status = Get-StatusString $porcelainStatus

    $result = (Get-Staged "" $status.Conflicted Yellow)
    $result = (Get-Staged $result $status.Staged Green)
    $result = (Get-Staged $result $status.Unstaged Magenta)
    $result = (Get-Staged $result $status.Untracked Gray)

    return ' ' + $result
}

function Get-RemoteBranchName($currentBranch, $gitRoot, $remoteName) {
    
    $remoteBranchName = git config --get "branch.$currentBranch.merge"
    
    if ($remoteBranchName -eq $null) {
    
        if ($currentBranch -eq 'master') {
            return 'master' # Need to find out how to determine the remote branch name when on the master branch
        }
        $head = (Get-Content -Path ("$gitRoot\.git\HEAD"))
        $currentRef = $head.SubString($head.LastIndexOf('/') + 1)
        if ((Test-Path -Path "$gitRoot\.git\refs\heads\$currentRef") -and 
            (Test-Path -Path "$gitRoot\.git\refs\remotes\$remoteName\$currentRef")) {
            return $currentRef
        }
    } else {
        return $remoteBranchName
    }
}

function Get-CommitStatus($currentBranch, $gitRoot) {

    $remoteAheadCount = 0
    $localAheadCount = 0
    $remoteBranchName = $null
    $masterBehindAhead = ''

    # get remote name of the current branch, i.e. origin
    $remoteName = git config --get "branch.$currentBranch.remote"
        
    if ($remoteName -eq $null) {
        $remoteName = 'origin' # Still haven't found a way to get the remote name when on the master branch
    }
    
    $remoteBranchName = Get-RemoteBranchName $currentBranch $gitRoot $remoteName

    if ($remoteBranchName -ne $null) {

        # We only need the remote branch name
        $remoteBranchName = $remoteBranchName.Substring($remoteBranchName.LastIndexOf('/') + 1)

        # Get remote commit count ahead of current branch
        $remoteAheadCount = git rev-list --left-only --count $remoteName'/'$remoteBranchName...HEAD
        $localAheadCount = git rev-list --right-only --count $remoteName'/'$remoteBranchName...HEAD

        $result = ""
        if ($remoteAheadCount -gt 0 -and $localAheadCount -gt 0) {
            $result = " #white#$remoteAheadCount#yellow#$($arrows.downArrow)$($arrows.upArrow)#white#$localAheadCount"
        } else {
            $remoteCounts = @{
                RemoteAhead = $remoteAheadCount;
            }
            
            $result = Get-Staged " " $remoteCounts Green

            $remoteCounts = @{
                LocalAhead = $localAheadCount;
            }
    
            $result = (Get-Staged $result $remoteCounts Magenta).TrimEnd()
        }
        
        # If the remote branch name isn't available it probably means it hasn't been pushed to the server yet
        $remoteAheadCount = git rev-list --left-only --count "origin/master...$remoteName/$remoteBranchName"
        $branchAheadCount = git rev-list --right-only --count "origin/master...$remoteName/$remoteBranchName"
        
        if ($remoteAheadCount -gt 0 -and $branchAheadCount -gt 0) { $masterBehindAhead = "m #white#$remoteAheadCount #yellow#$($arrows.leftRightArrow) #white#$branchAheadCount "  }
        elseif ($remoteAheadCount -gt 0) { $masterBehindAhead = "m #white#$remoteAheadCount #magenta#$($arrows.rightArrow) "}
        elseif ($branchAheadCount -gt 0) { $masterBehindAhead = "m #white#$branchAheadCount #green#$($arrows.leftArrow) "}
        
    } else {
        # If the remote branch name isn't available it probably means it hasn't been pushed to the server yet
        $remoteAheadCount = git rev-list --left-only --count "$remoteName/master...HEAD"
        $branchAheadCount = git rev-list --right-only --count "$remoteName/master...HEAD"
        
        if ($remoteAheadCount -gt 0 -and $branchAheadCount -gt 0) { $masterBehindAhead = "m #white#$remoteAheadCount #cyan#$($arrows.leftRightArrow) #white#$branchAheadCount "  }
        elseif ($remoteAheadCount -gt 0) { $masterBehindAhead = "m #white#$remoteAheadCount #cyan#$($arrows.rightArrow) "}
        elseif ($branchAheadCount -gt 0) { $masterBehindAhead = "m #white#$branchAheadCount #cyan#$($arrows.leftArrow) "}
    }
    $fileStatus = (Get-FilesStatus).TrimEnd()
    
    return "#darkgray#git:($masterBehindAhead#darkgray#$currentBranch$result#darkgray#)$fileStatus"
}

# Does not raise an error when outside of a git repo
function Test-GitRepo($location) {
    
    $directoryInfo = $location;

    if ($location -is [System.Management.Automation.PathInfo]) {
        if ($location.Provider.Name -eq 'FileSystem' -and (-not $location.ProviderPath.StartsWith('\\'))) {
            $directoryInfo = ([System.IO.DirectoryInfo]$location.Path)
        }
    }

    if ($directoryInfo -eq $null) { return }
    
    if ($directoryInfo -is [System.IO.DirectoryInfo]) {

        $gs = $directoryInfo.GetDirectories(".git");

        if ($gs.Length -eq 0)
        {
            return Test-GitRepo($directoryInfo.Parent);
        }
        return $directoryInfo.FullName;
    }
}

function TimeToUpdate($lastUpdatePath) {

    if ((Test-Path $lastUpdatePath)){
        return (Get-Date).Subtract((Get-Item $lastUpdatePath).LastWriteTime).TotalMinutes -gt 5
    }
    else {
        return $true
    }

    return $false
}

function Begin-SilentFetch($gitRepoPath) {

    $lastUpdatePath = $gitRepoPath + '\.git\lastupdatetime'

    if (TimeToUpdate $lastUpdatePath) {
        echo $null > $lastUpdatePath
        Remove-Job -Name 'gitfetch' -Force -ErrorAction SilentlyContinue

        Start-Job -Name 'gitfetch' -ArgumentList $gitRepoPath, $lastUpdatePath -ScriptBlock { param($gitRepoPath, $lastUpdatePath)
            git -C $gitRepoPath fetch --quiet
        }
    }
}

function Show-PsRadar($gitRoot, $currentPath) {

    if($gitRoot -ne $null) {
               
        #Get current branch name
        $currentBranch = git symbolic-ref --short HEAD

        if ($currentBranch -ne $NULL) {
            
            $commitStatus = Get-CommitStatus $currentBranch $gitRoot
            
            $repoName = ($gitRoot.Substring($gitRoot.LastIndexOf('\') + 1) + $currentPath.Substring($gitRoot.Length)).Replace('\', '/')

            Write-Host "$($arrows.rightArrow) " -NoNewline -ForegroundColor Green
            Write-Host "$repoName/ " -NoNewline -ForegroundColor DarkCyan
            Write-Chost "$commitStatus"

            Begin-SilentFetch $gitRepoPath

            return $true
        }
    }
    
    return $false
}

function Set-ArrowCharacters() {
    $arrowDefs = (Get-Content -Path "$Env:USERPROFILE\.git-psradar" -Encoding Unicode).Split("`n");
    $arrows.upArrow = $arrowDefs[0];$arrows.downArrow = $arrowDefs[1];$arrows.rightArrow = $arrowDefs[2];$arrows.leftArrow = $arrowDefs[3]; $arrows.leftRightArrow = $arrowDefs[4];
}

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
    } elseif ([int]::TryParse($set, [ref]$set)-and $set -eq 2) {
        Set-Content -Path "$Env:USERPROFILE\.git-psradar" -Value "$upArrowSet2`n$downArrowSet2`n$rightArrowSet2`n$leftArrowSet2`n$leftRightArrowSet2" -Encoding Unicode
    } elseif ([int]::TryParse($set, [ref]$set)-and $set -eq 3) {
        Set-Content -Path "$Env:USERPROFILE\.git-psradar" -Value "$upArrowSet3`n$downArrowSet3`n$rightArrowSet3`n$leftArrowSet3`n$leftRightArrowSet3" -Encoding Unicode
    } else {
        Set-Content -Path "$Env:USERPROFILE\.git-psradar" -Value "$upArrowSet1`n$downArrowSet1`n$rightArrowSet1`n$leftArrowSet1`n$leftRightArrowSet1" -Encoding Unicode
    }
    
    if ((Get-Command "git.exe" -ErrorAction SilentlyContinue) -eq $null) { 
        Write-Host "Git-PsRadar will not work unless git.exe is in your path" -ForegroundColor Red
    }
}

Set-ArrowCharacters

Export-ModuleMember -Function Show-GitPsRadar, Test-GitRepo -WarningAction SilentlyContinue -WarningVariable $null

# Get the existing prompt function
if ($Script:originalPrompt -eq $null) {
    $Script:originalPrompt = (Get-Item function:prompt).ScriptBlock
}

function global:prompt {

    $currentLocation = Get-Location
    $currentPath = $currentLocation.ProviderPath
    $gitRepoPath = Test-GitRepo $currentLocation

    # Change the prompt as soon as we enter a git repository
    if ($gitRepoPath -ne $null -and (Show-PsRadar $gitRepoPath $currentPath)) {
        return "> "
    } else {
        Invoke-Command $Script:originalPrompt
    }
}