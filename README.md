# Git-PsRadar

A (work-in-progress) PowerShell port of [git-radar](https://github.com/michaeldfallen/git-radar). A heads up display for git.

## Why

The most useful prompt I have seen for working with git repositories, I just had to have it!

### Standard prompt

The Git Radar prompt will automatically toggle after you import the `Git-PsRadar` module in to your session and `cd` in to a git repository.

![PowerShellPrompt]

### Local commits status

The prompt will show you the difference in commits between your branch and the
remote your branch is tracking. The examples below assume you are checked out on
`sfetch` and are tracking `origin/silent-fetch`.

Prompt              | Meaning
--------------------|--------
![LocalBranchAhead]  | We have 3 commits to push up
![RemoteBranchAhead] | We have 1 commit to pull down

## Installation

Download the Git-PsRadar.psm1 file, put it in a folder called Git-PsRadar and copy the folder it to your PowerShell module directory.The default location for this is .\WindowsPowerShell\Modules (relative to your Documents folder). You can also extract it to another directory listed in your $env:PSModulePath. The full installation path should be **\Documents\WindowsPowerShell\Modules\Git-PsRadar\Git-PsRadar.psm1**

Assuming you want Git-PsRadar to be avilable in every PowerShell session, open your profile script located at '$env:USERPROFILE\Documents\WindowsPowerShell\Microsoft.PowerShell_profile.ps1' and add the following line.

`Import-Module Git-PsRadar`

If the file Microsoft.PowerShell_profile.ps1 does not exist, you can simply create it and it will be executed the next time a PowerShell session starts.

## What's next

I'll be working on this script as time permits, but I am keen to bring across all features, especially background fetch.

[PowerShellPrompt]: https://raw.githubusercontent.com/vincpa/git-psradar/master/images/basic-usage.png
[LocalBranchAhead]: https://raw.githubusercontent.com/vincpa/git-psradar/master/images/local-branch-ahead.PNG
[RemoteBranchAhead]: https://raw.githubusercontent.com/vincpa/git-psradar/master/images/remote-branch-ahead.PNG
