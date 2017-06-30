nuget install LibGit2Sharp -Version 0.24.0

mkdir _publish

Copy-Item .\Git-PsRadar.psd1 .\_publish -Force
Copy-Item .\Git-PsRadar.psm1 .\_publish -Force
Copy-Item .\Functions .\_publish\Functions -Force
Copy-Item .\LibGit2Sharp.0.24.0 .\_publish -Recurse -Force
Copy-Item .\LibGit2Sharp.NativeBinaries.1.0.185 .\_publish -Recurse -Force