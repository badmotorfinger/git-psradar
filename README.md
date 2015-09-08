# Git-PsRadar

A (work-in-progress) PowerShell port of [git-radar](https://github.com/michaeldfallen/git-radar). A heads up display for git.

## Why

The most useful prompt I have seen for working with git repositories, I just had to have it!

Standard prompt

![PowerShell Prompt 1](https://github.com/vincpa/git-psradar/raw/master/images/basic-usage.png)

Standard prompt in a subdirectory of a git repo

![PowerShell Prompt 2](https://github.com/vincpa/git-psradar/raw/master/images/repo-relative-path.png)

## Current Feature Set

1. Automatic prompt - Once you import the `Git-PsRadar` module in to your session, the prompt will automatically change once you enter a git repository and revert back to the standard prompt when you go to a different directory.

2. Detect unstaged and staged changes. This includes all status types.

3. Coloured indicators for staged, unstaged and conflicted items.

## Installation

Download the Git-PsRadar.psm1 file, put it in a folder called Git-PsRadar and copy the folder it to your PowerShell module directory.The default location for this is .\WindowsPowerShell\Modules (relative to your Documents folder). You can also extract it to another directory listed in your $env:PSModulePath. The full installation path should be **\Documents\WindowsPowerShell\Modules\Git-PsRadar\Git-PsRadar.psm1**

Assuming you want Git-PsRadar to be avilable in every PowerShell session, open your profile script located at '$env:USERPROFILE\Documents\WindowsPowerShell\Microsoft.PowerShell_profile.ps1' and add the following line.

Import-Module Git-PsRadar

If the file Microsoft.PowerShell_profile.ps1 does not exist, you can simply create it and it will be executed the next time a PowerShell session starts.

## What's next

I'll be working on this script as time permits, but I am keen to bring across all features, especially background fetch.
