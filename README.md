# Git-PsRadar

A (work-in-progress) PowerShell port of [git-radar](https://github.com/michaeldfallen/git-radar). A heads up display for git.

## Why

The most useful prompt I have seen for working with git repositories, I just had to have it!

### Standard prompt

The Git Radar prompt will automatically toggle after you import the `Git-PsRadar` module in to your session and `cd` in to a git repository. The example below shows the mater branch with 1 modified file staged for commit, 1 deleted, 1 modified and 2 new files not yet staged for commit.

![PowerShellPrompt]

> Tip! Git-PsRadar works best with font Lucida Console at size 16.

### Local commits status

The prompt will show you the difference in commits between your branch and the
remote your branch is tracking. The examples below assume you are checked out on
`master` and are tracking `origin/master`.

### Prompt & Meaning

![LocalBranchAhead]

There are 4 commits to push up, 1 modified and 3 new files not yet staged to commit

![RemoteBranchAhead] 

There is 1 commit to pull down, 1 new and 1 modified files staged for commit

![BranchDiverged]

master and origin/master have diverged. We have 1 change to pull down and 3 to push.

![BothRemotesDivergedAndLocalDiverged]

origin/master and origin/tmp have diverged. Our local tmp branch also has 15 changes to pull and 1 to push up to origin/tmp. Essentally the arrows in the middle show branch diversion on the server and the arrows to the right show diversions between the local branch and the remote branch it's tracking.

![ShowStashCount]

There is 1 item in our stash stack

![OriginMasterDiveredTmp]

origin/master has divered by 1 commit from our local tmp branch

![TmpAheadOriginMaster]

tmp branch is locally ahead by 1 commit from origin/master (blue arrow)

![OriginTmpAheadOriginMaster]

origin/tmp ahead by 1 commit from origin/master (green arrow). The arrow changes colour after pushing the branch to the remote.

### Background fetch

When entering a git repository at the command line, Git-PsRadar will place a 0 length file in your `.git` directory called `lastupdatetime`. If the modified date shows it's older than 5 minutes, a background `git fetch` (which won't affect your current working copy) will be performed which will then show pending changes in the PowerShell HUD prompt. It's a feature I intend to make configurable in the near future.

### PowerShell installation

#### The easy way

For those with Windows 10 and above, you can issue a `Install-Module -Name Git-PsRadar` command.

For those with Windows Vista or 7 who are using PowerShell version 3 or 4, you'll need to install [PackageManagement](http://go.microsoft.com/fwlink/?LinkID=746217&clcid=0x409) first before executing `Install-Module -Name Git-PsRadar`.

See the module listing in the [official PowerShell gallary](https://www.powershellgallery.com/packages/Git-PsRadar/)

Once complete, run the command `Import-Module Git-PsRada`. For ease of use I recomend placing this command in your [PowerShell startup profile](https://technet.microsoft.com/en-us/library/bb613488(v=vs.85).aspx). Typically `$env:USERPROFILE\Documents\WindowsPowerShell\Microsoft.PowerShell_profile.ps1`

#### The hard way  

Download the Git-PsRadar.psm1 file, put it in a folder called Git-PsRadar and copy the folder it to your PowerShell module directory. `$env:USERPROFILE\Documents\WindowsPowerShell\Modules` (relative to your Documents folder). You can also extract it to another directory listed in your $env:PSModulePath. The full installation path should be `$env:USERPROFILE\Documents\WindowsPowerShell\Modules\Git-PsRadar\Git.PsRadar.psm1`.

Assuming you want Git-PsRadar to be avilable in every PowerShell session, open your profile script located at `$env:USERPROFILE\Documents\WindowsPowerShell\Microsoft.PowerShell_profile.ps1` and add the following line.

`Import-Module Git-PsRadar`

If the file Microsoft.PowerShell_profile.ps1 does not exist, you can simply create it and it will be executed the next time a PowerShell session starts.

## What's next

I'll be working on this script as time permits, but I am keen to bring across all features.


[PowerShellPrompt]: https://raw.githubusercontent.com/vincpa/git-psradar/master/images/basic-usage.png
[LocalBranchAhead]: https://raw.githubusercontent.com/vincpa/git-psradar/master/images/local-branch-ahead.PNG
[RemoteBranchAhead]: https://raw.githubusercontent.com/vincpa/git-psradar/master/images/remote-branch-ahead.PNG
[BranchDiverged]: https://raw.githubusercontent.com/vincpa/git-psradar/master/images/remote-local-diverged.PNG
[BothRemotesDivergedAndLocalDiverged]: https://raw.githubusercontent.com/vincpa/git-psradar/master/images/gitps-remote-branch-remote-origin-diverged-changes-to-pull-down.PNG
[ShowStashCount]: https://raw.githubusercontent.com/vincpa/git-psradar/master/images/show-stash-count.png
[OriginMasterDiveredTmp]: https://raw.githubusercontent.com/vincpa/git-psradar/master/images/origin-master-diverged-tmp.png
[TmpAheadOriginMaster]: https://raw.githubusercontent.com/vincpa/git-psradar/master/images/tmp-ahead-origin-master.png
[OriginTmpAheadOriginMaster]: https://raw.githubusercontent.com/vincpa/git-psradar/master/images/origin-tmp-diverged-origin-master.png
