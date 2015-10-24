<#

.SYNOPSIS

   A heads up display for git. A port of https://github.com/michaeldfallen/git-radar

.DESCRIPTION

    Provides an at-a-glance information about your git repo.

.LINK

   https://github.com/vincpa/git-psradar

#>
$upArrow 	= ([Convert]::ToChar(9650))
$rightArrow	= ([Convert]::ToChar(9658))

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

function Get-Staged($status, $color, $showNewFiles, $onlyShowNewFiles) {
	$hasChanged = $false;
	$hasChanged = $hasChanged -or (Write-GitStatus $status.Added 'A' $color)
	$hasChanged = $hasChanged -or (Write-GitStatus $status.Renamed 'R' $color)
	$hasChanged = $hasChanged -or (Write-GitStatus $status.Deleted 'D' $color)
	$hasChanged = $hasChanged -or (Write-GitStatus $status.Modified 'M' $color)
	$hasChanged = $hasChanged -or (Write-GitStatus $status.Copied 'C' $color)
	$hasChanged = $hasChanged -or (Write-GitStatus $status.ConflictUs 'U' $color)
	$hasChanged = $hasChanged -or (Write-GitStatus $status.ConflictThem 'T' $color)
	$hasChanged = $hasChanged -or (Write-GitStatus $status.Conflict 'B' $color)
	if ($hasChanged) {
		Write-Host ' ' -NoNewline
	}
}

function Write-GitStatus($count, $symbol, $color) {
	if ($count -gt 0) {
		Write-Host $count -ForegroundColor White -NoNewline
		Write-Host $symbol -ForegroundColor $color -NoNewline
		return $true;
	}
	return $false;
}

# Does not raise an error when outside of a git repo
function Test-GitRepo($directoryInfo = ([System.IO.DirectoryInfo](Get-Location).Path)) {

	if ($directoryInfo -eq $null) { return }

	$gs = $directoryInfo.GetDirectories(".git");

	if ($gs.Length -eq 0)
	{
		return Test-GitRepo($directoryInfo.Parent);
	}
	return $directoryInfo.FullName.Replace('\', '/');
}

function Show-PsRadar($gitRepoPath) {

	$currentPath = ([System.IO.DirectoryInfo](Get-Location).Path)

    if($gitRepoPath -ne $null) {
	  
        $gitResults = @{ 
		    GitRoot = $gitRepoPath;
			PorcelainStatus = git status --porcelain;
		}    
    
		$currentBranch = (git branch --contains HEAD).Split([Environment]::NewLine)[0]

        if ($currentBranch -ne $NULL) {
            if ($currentBranch[2] -eq '(') {
                $branch = $currentBranch.Substring(2)
            } else {
                $branch = '(' + $currentBranch.Substring(2) + ')'
            }
        }

	} else {
		return;
	}

    $gitRoot = $gitResults.GitRoot
	$repoName = $gitRoot.Substring($gitRoot.LastIndexOf('/') + 1) + $currentPath.FullName.Replace('\', '/').Replace($gitRoot, '')
    $porcelainStatus = $gitResults.PorcelainStatus

    Write-Host $rightArrow -NoNewline -ForegroundColor Green
	Write-Host " $repoName/" -NoNewline -ForegroundColor DarkCyan
	Write-Host " git:$branch" -NoNewline -ForegroundColor DarkGray

	$status = Get-StatusString $porcelainStatus

	Get-Staged $status.Conflicted Yellow
	Get-Staged $status.Staged Green
	Get-Staged $status.Unstaged Magenta
	Get-Staged $status.Untracked Gray
}

Export-ModuleMember -Function Show-GitPsRadar, Test-GitRepo -WarningAction SilentlyContinue -WarningVariable $null

# Get the existing prompt function
$originalPrompt = (Get-Item function:prompt).ScriptBlock

function global:prompt {
	
	$gitRepoPath = Test-GitRepo
	# Change the prompt as soon as we enter a git repository
	if ($gitRepoPath -ne $null) {
		Show-PsRadar $gitRepoPath
		return "$ "
	} else {
		Invoke-Command $originalPrompt
	}
}