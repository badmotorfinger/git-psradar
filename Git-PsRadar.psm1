<#

.SYNOPSIS

   A heads up display for git. A port of https://github.com/michaeldfallen/git-radar

.DESCRIPTION

    Provides an at-a-glance information about your git repo.

.LINK

   https://github.com/vincpa/git-psradar

#>
$upDownArrow = ([Convert]::ToChar(23))
$upArrow 	= ([Convert]::ToChar(24))
$downArrow 	= ([Convert]::ToChar(25))
$rightArrow	= ([Convert]::ToChar(26))

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
                    if ($CurrentColor -ne -1) {
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
    $result = (Get-StatusCountFragment $result $status.RemoteAhead  $downArrow $color)
    $result = (Get-StatusCountFragment $result $status.LocalAhead   $upArrow $color)

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

    return $result
}

function Get-CommitStatus($currentBranch) {

    $remoteAheadCount = 0
    $localAheadCount = 0
    $remoteBranchName = $null

    # get remote name of the current branch, i.e. origin
	$remoteName = git config --get "branch.$currentBranch.remote"
        
    if ($remoteName -eq $null) {
        $remoteName = 'origin' # Still haven't found a way to get the remote name when on the master branch
    }
    
    $remoteBranchName = git config --get "branch.$currentBranch.merge"

    if ($remoteBranchName -eq $null -and $currentBranch -eq 'master') {
        $remoteBranchName = 'master' # Need to find out how to determine the remote branch name when on the master branch
    }

    if ($remoteBranchName -ne $null) {

        # We only need the remote branch name
        $remoteBranchName = $remoteBranchName.Substring($remoteBranchName.LastIndexOf('/') + 1)

        # Get remote commit count ahead of current branch
        $remoteAheadCount = git rev-list --left-only --count $remoteName'/'$remoteBranchName...HEAD
        $localAheadCount = git rev-list --right-only --count $remoteName'/'$remoteBranchName...HEAD

        $result = ""
        if ($remoteAheadCount -gt 0 -and $localAheadCount -gt 0) {
            $result = " #white#$remoteAheadCount#yellow#$upDownArrow#white#$localAheadCount"
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
    }

    return "#darkgray#git:($currentBranch$result#darkgray#) "
}

# Does not raise an error when outside of a git repo
function Test-GitRepo($directoryInfo = ([System.IO.DirectoryInfo](Get-Location).Path)) {

	if ($directoryInfo -eq $null) { return }

	$gs = $directoryInfo.GetDirectories(".git");

	if ($gs.Length -eq 0)
	{
		return Test-GitRepo($directoryInfo.Parent);
	}
	return $directoryInfo.FullName;
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

    Remove-Job -Name 'gitfetch' -Force -ErrorAction SilentlyContinue

    $lastUpdatePath = $gitRepoPath + '\.git\lastupdatetime'

    if (TimeToUpdate $lastUpdatePath) {

        Start-Job -Name 'gitfetch' -ArgumentList $gitRepoPath, $lastUpdatePath -ScriptBlock { param($gitRepoPath, $lastUpdatePath)
            echo $null > $lastUpdatePath
            git -C $gitRepoPath fetch --quiet
        }
    }
}

function Show-PsRadar($gitRoot, $currentPath) {

    if($gitRoot -ne $null) {
               
        #Get current branch name
		$currentBranch = git symbolic-ref --short HEAD

        if ($currentBranch -ne $NULL) {
            
            $commitStatus = Get-CommitStatus $currentBranch
			$fileStatus = (Get-FilesStatus).TrimEnd()

            $repoName = ($gitRoot.Substring($gitRoot.LastIndexOf('\') + 1) + $currentPath.FullName.Substring($gitRoot.Length)).Replace('\', '/')

    	    Write-Host "$rightArrow " -NoNewline -ForegroundColor Green
    	    Write-Host "$repoName/ " -NoNewline -ForegroundColor DarkCyan
            Write-Chost $commitStatus
            Write-Chost $fileStatus

            Begin-SilentFetch $gitRepoPath

            return $true
        }
    }
    
    return $false
}

Export-ModuleMember -Function Show-GitPsRadar, Test-GitRepo -WarningAction SilentlyContinue -WarningVariable $null

# Get the existing prompt function
if ($Script:originalPrompt -eq $null) {
    $Script:originalPrompt = (Get-Item function:prompt).ScriptBlock
}

function global:prompt {

    $currentPath = ([System.IO.DirectoryInfo](Get-Location).Path)
	$gitRepoPath = Test-GitRepo $currentPath

	# Change the prompt as soon as we enter a git repository
	if ((Test-GitRepo) -and (Show-PsRadar $gitRepoPath $currentPath)) {
		return "> "
	} else {
		Invoke-Command $Script:originalPrompt
	}
}

