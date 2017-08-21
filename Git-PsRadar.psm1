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

# Needs to get actual remote branch name when the local name you're tracking is
# different from the remote branch nbame
function Get-RemoteBranchName($currentBranch, $gitRoot, $remoteName) {

    $head = [System.IO.File]::ReadAllText("$gitRoot\.git\HEAD")
    
    # Branch names can contain paths
    $currentRef = $head.Replace("ref: refs/heads/", "").Replace("/", "\").TrimEnd()

    if ((Test-Path -Path "$gitRoot\.git\logs\refs\heads\$currentRef") -and
        (Test-Path -Path "$gitRoot\.git\logs\refs\remotes\$remoteName\$currentRef")) {
        return $currentRef.Replace("\", "/")
    }
    return ''
}

function Get-ConfigValue($repo, $configKey) { 

    $result = $repo.Config | ? { $_.Key -eq $configKey }

    if ($result -eq $null) {
        return ''
    }
    return $result.Value;
} 

function Get-ParentBranch($gitRoot, $currentBranch, $parentSha) {
    
    # Path will not exist for new repositories
    if ((Test-Path -Path "$gitRoot\.git\logs\refs\heads")) {
    
      $files=[System.IO.Directory]::GetFiles("$gitRoot\.git\logs\refs\heads")

      for($i = 0; $i -lt $files.Length;$i++){

          $fileName = $files[$i]

          # Real all lines even though we only need the first because sometimes the file is left open
          # git fails temporarily
          $first = [System.IO.File]::ReadAllLines($fileName) | select -First 1

          if ($first.Contains($parentSha)) { continue }

          if ([System.IO.File]::ReadAllText($fileName).Contains($parentSha)) {

              return $fileName.Substring($fileName.LastIndexOf('\') + 1)
          }
      }
    }
    return 'master'
}

function Get-BranchRemote($repo, $currentBranch, $gitRoot) {

    # get remote name of the current branch, i.e. origin
    $remoteName = Get-ConfigValue $repo "branch.$currentBranch.remote"

    if ($remoteName -eq $null -or $remoteName.Trim() -eq '' -or $remoteName -eq '.') {
        
        # To handle branch names with slashes such as 'features/foo-branch' or 'work/bugs/foo-branch'
        $parentBranchLastIndex = $currentBranch.LastIndexOf('/')
        $parentBranchFolder = ''
        if ($parentBranchLastIndex -gt 0) { $parentBranchFolder = $currentBranch.SubString(0, $parentBranchLastIndex) }
        $currentBranch = $currentBranch.SubString($currentBranch.LastIndexOf('/') + 1)

        $file = [System.IO.Directory]::GetFiles("$gitRoot\.git\logs\refs\remotes", $currentBranch, 'AllDirectories')
        if ($file.Length -gt 0) {
            $fullName = (get-item $file[0]).Directory.FullName
            
            if ($parentBranchLastIndex -gt 0) { $fullName = $fullName.Substring(0, $fullName.Length - $parentBranchFolder.Length -1) }

            return $fullName.Substring($fullName.LastIndexOf('\') + 1)
        } else {
            return ''
        }
    }
    

    return $remoteName
}

function Get-ParentBranchSha($gitRoot, $currentBranch) {

    $branchPath = "$gitRoot\.git\logs\refs\heads\$currentBranch"
    
    # Path will not exist for new repositories
    if ((Test-Path -Path $branchPath)) {
      $firstLine = [System.IO.File]::ReadAllLines("$gitRoot\.git\logs\refs\heads\$currentBranch") | select -First 1
      return $firstLine.SubString(41, 40)
    }
    return ''
}

function Get-CommitStatus($currentBranch, $gitRoot) {

    $repo = New-Object LibGit2Sharp.Repository($gitRoot)

    $remoteAheadCount = 0
    $localAheadCount = 0
    $remoteBranchName = $null
    $masterBehindAhead = ''

    $remoteName = Get-BranchRemote $repo $currentBranch $gitRoot
    $remoteBranchName = Get-RemoteBranchName $currentBranch $gitRoot $remoteName

    $parentSha = Get-ParentBranchSha $gitRoot $currentBranch
    $parentBranchName = Get-ParentBranch $gitRoot $currentBranch $parentSha
    
    Write-Host "RemoteName:$remoteName | RemoteBranch:$remoteBranchName | ParentBranch:$parentBranchName"

    $parentBranchDisplayPrefix = $parentBranchName

    if ($parentBranchName.Length -ge 2) {
        $parentBranchDisplayPrefix = $parentBranchName.Substring(0, 2)
    }

    if ($remoteName -ne '' -and $remoteBranchName -ne '') {

        # Get remote commit count ahead of current branch
        $branchDiff = (CachedExceptCommits $repo "HEAD" "$remoteName/$remoteBranchName").Split("`t")
        
        $localAheadCount = $branchDiff[0]
        $remoteAheadCount = $branchDiff[1]

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
        
        $branchDiff = (CachedExceptCommits $repo "$remoteName/$remoteBranchName" "$remoteName/$parentBranchName").Split("`t")
        
        $remoteAheadCount = $branchDiff[1]
        $branchAheadCount = $branchDiff[0]

        if ($remoteAheadCount -gt 0 -and $branchAheadCount -gt 0) { $masterBehindAhead = "$parentBranchDisplayPrefix #white#$remoteAheadCount #yellow#$($arrows.leftRightArrow) #white#$branchAheadCount "  }
        elseif ($remoteAheadCount -gt 0) { $masterBehindAhead = "$parentBranchDisplayPrefix #white#$remoteAheadCount #magenta#$($arrows.rightArrow) "}
        elseif ($branchAheadCount -gt 0) { $masterBehindAhead = "$parentBranchDisplayPrefix #white#$branchAheadCount #green#$($arrows.leftArrow) "}

    } else {
        $branchDiff = (CachedExceptCommits $repo "HEAD" "$remoteName/$parentBranchName").Split("`t")
        
        $branchAheadCount = $branchDiff[0]
        $remoteAheadCount = $branchDiff[1]
  
        if ($remoteAheadCount -gt 0 -and $branchAheadCount -gt 0) { $masterBehindAhead = "$parentBranchDisplayPrefix #white#$remoteAheadCount #cyan#$($arrows.leftRightArrow) #white#$branchAheadCount "  }
        elseif ($remoteAheadCount -gt 0) { $masterBehindAhead = "$parentBranchDisplayPrefix #white#$remoteAheadCount #cyan#$($arrows.rightArrow) "}
        elseif ($branchAheadCount -gt 0) { $masterBehindAhead = "$parentBranchDisplayPrefix #white#$branchAheadCount #cyan#$($arrows.leftArrow) "}
    }

    $fileStatus = (Get-FilesStatus $repo).TrimEnd()

    $repo.Dispose();

    return "#darkgray#git:($masterBehindAhead#darkgray#$currentBranch$result#darkgray#)$fileStatus"
}

function CachedExceptCommits($repo, $remoteBranch1, $remoteBranch2, $parentSha) {

    if ($remoteBranch1 -eq $remoteBranch2) { return "0`t0" }

    # If the local version of a remote branch is updated then the cache key changes
    # This would happen after a local branch is pushed to a remote
    $branch1ShaTip = $repo.Branches[$remoteBranch1].Tip.Sha
    $branch2ShaTip = $repo.Branches[$remoteBranch2].Tip.Sha
    
    # New repositories
    if ($branch1ShaTip -eq $null -or $branch2ShaTip -eq $null) { return "0`t0" }

    $cachedResults = $remoteCacheCounts[($branch1ShaTip + $branch2ShaTip)];

    if ($cachedResults -eq $null) {
        $count = ExceptCommits $repo $remoteBranch1 $remoteBranch2 $parentSha

        $cachedResults = $remoteCacheCounts[($branch1ShaTip + $branch2ShaTip)] = $count
    }

    return $cachedResults
}

function ExceptCommits($repo, $leftBranch, $rightBranch, $parentSha) {

    $count = "0`t0";

    $null = .{
        $rightBranch = $rightBranch.TrimStart('/')
        $leftBranch = $leftBranch.TrimStart('/')
        
        $rightCommits = $repo.Branches[$rightBranch].Commits
        $leftCommits = $repo.Branches[$leftBranch].Commits

        try {

            $firstLeft = ($leftCommits | select -First 1)
            $firstRight = ($rightCommits | select -First 1)

            if ($firstLeft -eq $firstRight) { return 0 };

        } catch {

            return 0; # Exception will be thown in new repositories with no commits
        }

        $count = (git rev-list --left-right --count "$leftBranch...$rightBranch")
    }

    $count
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

# Load external functions
Get-ChildItem -Path (Join-Path -Path $ScriptRoot -ChildPath 'Functions' -Resolve) -Filter '*.ps1' |
            ForEach-Object { . $_.FullName }

Set-FirstTimeUserPrefs

Set-ArrowCharacters

Load-LibGit2Sharp $ScriptRoot

Export-ModuleMember -Function '' -WarningAction SilentlyContinue -WarningVariable $null

# Get the existing prompt function
if ($Script:originalPrompt -eq $null) {
    $Script:originalPrompt = (Get-Item function:prompt).ScriptBlock
}

function global:prompt {

    $currentLocation = Get-Location
    $currentPath = $currentLocation.ProviderPath
    $gitRepoPath = Test-GitRepo $currentLocation

    if ($gitRepoPath -ne $null) {

      if (Get-Command "git.exe" -ErrorAction SilentlyContinue) {

          # Change the prompt as soon as we enter a git repository
          if ((Show-PsRadar $gitRepoPath $currentPath)) {
              return "> "
          }
      } else {
          Write-Host "Git-PsRadar will not work unless git.exe is in your path" -ForegroundColor Red
      }
    }
    Invoke-Command $Script:originalPrompt
}