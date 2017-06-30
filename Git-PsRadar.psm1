<#

.SYNOPSIS

   A heads up display for git. A port of https://github.com/michaeldfallen/git-radar

.DESCRIPTION

    Provides an at-a-glance information about your git repo.

.LINK

   https://github.com/vincpa/git-psradar

#>

$arrows = @{upArrow = '↑';downArrow = '↓';rightArrow = '→';leftArrow = '←'; leftRightArrow = '↔'; stash = '≡'}
$arrows = New-Object –TypeName PSObject –Prop $arrows

$ScriptRoot = (Split-Path $MyInvocation.MyCommand.Definition)
if ($ScriptRoot -eq '') { $ScriptRoot = $PSScriptRoot }

$remoteCacheCounts = @{}

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

function Get-StatusString($repoStatus) {
    
    $results = @{
        Staged = @{
            Modified = 0;
            Deleted = 0;
            Added = 0;
            Renamed = 0;
        };
        Unstaged = @{
            Modified = 0;
            Deleted = 0;
            Renamed = 0;
        };
        Untracked = @{
            Added = ($repoStatus.Untracked | ? { $_.State -eq [LibGit2Sharp.FileStatus]::NewInWorkdir }).Count;
        };
        Conflicted = @{
            ConflictUs = 0;
            ConflictThem = 0;
            Conflict = 0;
        }
    }

    SetStatusCounts-ForRepo $repoStatus.Staged $results.Staged
    SetStatusCounts-ForRepo $repoStatus.Added $results.Staged
    SetStatusCounts-ForRepo $repoStatus.RenamedInIndex $results.Staged
    SetStatusCounts-ForRepo $repoStatus.Removed $results.Staged

    SetStatusCounts-ForRepo $repoStatus.Modified $results.Unstaged
    SetStatusCounts-ForRepo $repoStatus.Missing $results.Unstaged
           
    return $results
}

function SetStatusCounts-ForRepo($fileStateLocation, $resultToPopulate) {
    # Use hashtable lookup for increments instead of a bunch of if statements
    ForEach($stausEntry in $fileStateLocation) {
        if ($stausEntry.State.HasFlag([LibGit2Sharp.FileStatus]::ModifiedInWorkdir) -or $stausEntry.State.HasFlag([LibGit2Sharp.FileStatus]::ModifiedInIndex)) { $resultToPopulate.Modified++ }
        if ($stausEntry.State.HasFlag([LibGit2Sharp.FileStatus]::DeletedFromWorkdir) -or $stausEntry.State.HasFlag([LibGit2Sharp.FileStatus]::DeletedFromIndex)) { $resultToPopulate.Deleted++ }
        if ($stausEntry.State.HasFlag([LibGit2Sharp.FileStatus]::RenamedInIndex)) { $resultToPopulate.Renamed++ }
        if ($stausEntry.State.HasFlag([LibGit2Sharp.FileStatus]::NewInWorkdir) -or $stausEntry.State.HasFlag([LibGit2Sharp.FileStatus]::NewInIndex)) { $resultToPopulate.Added++ }
    }
}

function Get-StatusFor($seed, $status, $color, $showNewFiles, $onlyShowNewFiles) {
    
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

function Get-StashStatus($result, $repo) {
    $count = ($repo.Stashes | measure).Count;
    return (Get-StatusCountFragment $result $count $arrows.stash Yellow)
}

function Get-FilesStatus($repo) {
    
    $statusOptions = New-Object LibGit2Sharp.StatusOptions -Property  @{ IncludeIgnored = $false };
    $repoStatus = $repo.RetrieveStatus($statusOptions)

    $status = Get-StatusString $repoStatus

    $result = (Get-StatusFor "" $status.Conflicted Yellow)
    $result = (Get-StatusFor $result $status.Staged Green)
    $result = (Get-StatusFor $result $status.Unstaged Magenta)
    $result = (Get-StatusFor $result $status.Untracked Gray)
    $result = (Get-StashStatus $result $repo)
    
    return ' ' + $result
}

function Get-RemoteBranchName($currentBranch, $gitRoot, $remoteName, $repo) {
    
    $remoteBranchName = Get-ConfigValue $repo "branch.$currentBranch.merge"
    
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

function Get-ConfigValue($repo, $configKey) {

    $result = $repo.Config | ? { $_.Key -eq $configKey }
    if ($result -ne $null) {
        return $result.Value
    }
}

function Get-CommitStatus($currentBranch, $gitRoot) {
    
    $repo = New-Object LibGit2Sharp.Repository($gitRoot)

    $remoteAheadCount = 0
    $localAheadCount = 0
    $remoteBranchName = $null
    $masterBehindAhead = ''

    # get remote name of the current branch, i.e. origin
    $remoteName = Get-ConfigValue $repo "branch.$currentBranch.remote"

    if ($remoteName -eq $null) {
        $remoteName = 'origin' # Still haven't found a way to get the remote name when on the master branch
    }
    
    $remoteBranchName = Get-RemoteBranchName $currentBranch $gitRoot $remoteName $repo

    if ($remoteBranchName -ne $null) {

        # We only need the remote branch name
        $remoteBranchName = $remoteBranchName.Substring($remoteBranchName.LastIndexOf('/') + 1)

        # Get remote commit count ahead of current branch
        $remoteAheadCount = CachedExceptCommits $repo "HEAD" "$remoteName/$remoteBranchName"
        $localAheadCount = CachedExceptCommits $repo "$remoteName/$remoteBranchName" "HEAD"

        $result = ""
        if ($remoteAheadCount -gt 0 -and $localAheadCount -gt 0) {
            $result = " #white#$remoteAheadCount#yellow#$($arrows.downArrow)$($arrows.upArrow)#white#$localAheadCount"
        } else {
            $remoteCounts = @{
                RemoteAhead = $remoteAheadCount;
            }
            
            $result = Get-StatusFor " " $remoteCounts Green

            $remoteCounts = @{
                LocalAhead = $localAheadCount;
            }
    
            $result = (Get-StatusFor $result $remoteCounts Magenta).TrimEnd()
        }

        # If the remote branch name isn't available it probably means it hasn't been pushed to the server yet
        $remoteAheadCount = CachedExceptCommits $repo "$remoteName/$remoteBranchName" "origin/master"
        $branchAheadCount = CachedExceptCommits $repo "origin/master" "$remoteName/$remoteBranchName"


        if ($remoteAheadCount -gt 0 -and $branchAheadCount -gt 0) { $masterBehindAhead = "m #white#$remoteAheadCount #yellow#$($arrows.leftRightArrow) #white#$branchAheadCount "  }
        elseif ($remoteAheadCount -gt 0) { $masterBehindAhead = "m #white#$remoteAheadCount #magenta#$($arrows.rightArrow) "}
        elseif ($branchAheadCount -gt 0) { $masterBehindAhead = "m #white#$branchAheadCount #green#$($arrows.leftArrow) "}
        
    } else {
        # If the remote branch name isn't available it probably means it hasn't been pushed to the server yet
        $remoteAheadCount = CachedExceptCommits $repo "HEAD" "$remoteName/master"
        $branchAheadCount = CachedExceptCommits $repo "$remoteName/master" "HEAD"
        
        if ($remoteAheadCount -gt 0 -and $branchAheadCount -gt 0) { $masterBehindAhead = "m #white#$remoteAheadCount #cyan#$($arrows.leftRightArrow) #white#$branchAheadCount "  }
        elseif ($remoteAheadCount -gt 0) { $masterBehindAhead = "m #white#$remoteAheadCount #cyan#$($arrows.rightArrow) "}
        elseif ($branchAheadCount -gt 0) { $masterBehindAhead = "m #white#$branchAheadCount #cyan#$($arrows.leftArrow) "}
    }
    $fileStatus = (Get-FilesStatus $repo).TrimEnd()
    $repo.Dispose();

    return "#darkgray#git:($masterBehindAhead#darkgray#$currentBranch$result#darkgray#)$fileStatus"
}

function CachedExceptCommits($repo, $remoteBranch1, $remoteBranch2) {
    
    if ($remoteBranch1 -eq $remoteBranch2) { return 0 }
    
    # If the local version of a remote branch is updated then the cache key changes
    # This would happen after a local branch is pushed to a remote
    $branch1ShaTip = $repo.Branches[$remoteBranch1].Tip.Sha
    $branch2ShaTip = $repo.Branches[$remoteBranch2].Tip.Sha
    
    $cachedResults = $remoteCacheCounts[($branch1ShaTip + $branch2ShaTip)];

    if ($cachedResults -eq $null) {
        $count = ExceptCommits $repo $remoteBranch1 $remoteBranch2
                
        $cachedResults = $remoteCacheCounts[($branch1ShaTip + $branch2ShaTip)] = $count
    }
    return $cachedResults
}

function ExceptCommits($repo, $leftBranch, $rightBranch) {

    $set = {@()}.Invoke();

    $null = .{
        $rightCommits = $repo.Branches[$rightBranch].Commits
        $leftCommits = $repo.Branches[$leftBranch].Commits

        $firstLeft = ($leftCommits | select -First 1)
        $firstRight = ($rightCommits | select -First 1)
        if ($firstLeft -eq $firstRight) { return 0 };

        foreach($i in $rightCommits) { $set.Add($i) }
        foreach($i in $leftCommits) { $set.Remove($i) }
    }
    @($set).Count
}

# Does not raise an error when outside of a git repo
function Test-GitRepo($location) {
    
    $directoryInfo = $location;

    if ($location -is [System.Management.Automation.PathInfo]) {
        if ($location.Provider.Name -eq 'FileSystem' -and (-not $location.ProviderPath.StartsWith('\\'))) {
            $directoryInfo = ([System.IO.DirectoryInfo]$location.Path)
        }
    }
    
    $actualGitLocation = [LibGit2Sharp.Repository]::Discover($location)

    if ($actualGitLocation -eq $null) { return }
    
     (New-Object System.IO.FileInfo $actualGitLocation).Directory.Parent.FullName
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

        $remoteCacheCounts.Clear()

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

# Load external functions
Get-ChildItem -Path (Join-Path -Path $ScriptRoot -ChildPath 'Functions' -Resolve) -Filter '*.ps1' |
            ForEach-Object { . $_.FullName }

Set-FirstTimeUserPrefs

Set-ArrowCharacters

Load-LibGit2Sharp $ScriptRoot

Export-ModuleMember -Function Show-GitPsRadar, Test-GitRepo -WarningAction SilentlyContinue -WarningVariable $null

# Get the existing prompt function
if ($Script:originalPrompt -eq $null) {
    $Script:originalPrompt = (Get-Item function:prompt).ScriptBlock
}

function global:prompt {
    
    if (Get-Command "git.exe" -ErrorAction SilentlyContinue) { 
        
        $currentLocation = Get-Location
        $currentPath = $currentLocation.ProviderPath
        $gitRepoPath = Test-GitRepo $currentLocation
        
        # Change the prompt as soon as we enter a git repository
        if ($gitRepoPath -ne $null -and (Show-PsRadar $gitRepoPath $currentPath)) {
            return "> "
        }
    } else {
        Write-Host "Git-PsRadar will not work unless git.exe is in your path" -ForegroundColor Red
    }
    Invoke-Command $Script:originalPrompt
}