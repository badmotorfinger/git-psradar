<#

.SYNOPSIS

   Tracks your most used directories, based on 'frecency'. This is done by storing your CD command history and ranking it over time.

.DESCRIPTION

    After  a  short  learning  phase, z will take you to the most 'frecent'
    directory that matches the regex given on the command line.

.PARAMETER JumpPath

A regular expression of the directory name to jump to.

.PARAMETER Option

Frecency - Match by frecency (default)
Rank - Match by rank only
Time - Match by recent access only
List - List only
CurrentDirectory - Restrict matches to subdirectories of the current directory

.PARAMETER $ProviderDrives

A comma separated string of drives to match on. If none is specified, it will use a drive list from the currently selected provider.

For example, the following command will run the regular expression 'foo' against all folder names where the drive letters in your history match HKLM:\ C:\ or D:\

z foo -p HKLM,C,D

.PARAMETER $Remove

Remove the current directory from the datafile

.NOTES

Current PowerShell implementation is very crude and does not yet support all of the options of the original z bash script.
Although tracking of frequently used directories is obtained through the continued use of the "cd" command, the Windows registry is also scanned for frequently accessed paths.

.LINK

   https://github.com/vincpa/z

.EXAMPLE

CD to the most frecent directory matching 'foo'

z foo

.EXAMPLE

CD to the most recently accessed directory matching 'foo'

z foo -o Time

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

	if ($directoryInfo -eq $null) { return $false; }

	$gs = $directoryInfo.GetDirectories(".git");

	if ($gs.Length -eq 0)
	{
		return Test-GitRepo($directoryInfo.Parent);
	}
	return $true;
}

function Show-PsRadar {

	#git symbolic-ref --short HEAD

    if((Test-GitRepo)) {

      $currentBranch = git branch --contains HEAD

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

	$gitRoot = git rev-parse --show-toplevel
	$repoName = $gitRoot.Substring($gitRoot.LastIndexOf('/') + 1)
	$porcelainStatus = git status --porcelain

	$status = Get-StatusString $porcelainStatus

	Write-Host $rightArrow -NoNewline -ForegroundColor Green
	Write-Host " $repoName/" -NoNewline -ForegroundColor DarkCyan
	Write-Host " git:$branch" -NoNewline -ForegroundColor DarkGray

	Get-Staged $status.Conflicted Yellow
	Get-Staged $status.Staged Green
	Get-Staged $status.Unstaged Magenta
	Get-Staged $status.Untracked Gray
}

Export-ModuleMember -Function Show-GitPsRadar, Test-GitRepo -WarningAction SilentlyContinue -WarningVariable $null

# Get the existing prompt function
$originalPrompt = (Get-Item function:prompt).ScriptBlock

function global:prompt {
	
	# Change the prompt as soon as we enter a git repository
	if ((Test-GitRepo)) {
		Show-PsRadar
		return "$ "
	} else {
		Invoke-Command $originalPrompt
	}
}