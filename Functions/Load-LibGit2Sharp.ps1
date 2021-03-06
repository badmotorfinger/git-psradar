﻿function Load-LibGit2Sharp
{
    param(
        [Parameter(Mandatory=$true)]
        [string]
       # The Git-PsRadar module path
        $GitPsRadarRoot
    )
    
    Add-Type -Path "$GitPsRadarRoot\LibGit2Sharp.0.24.0\lib\net40\LibGit2Sharp.dll"

    $loadLibSignature = '
        [DllImport("kernel32.dll")]
        public static extern IntPtr LoadLibrary(string dllToLoad);'

    $win32Type = Add-Type -MemberDefinition $loadLibSignature -Name Win32Utils -Namespace GitPsRadar -PassThru

    if ([Environment]::Is64BitProcess) {
        $win32Type::LoadLibrary("$GitPsRadarRoot\LibGit2Sharp.NativeBinaries.1.0.185\runtimes\win7-x64\native\git2-15e1193.dll") | Out-Null
    } else {
        $win32Type::LoadLibrary("$GitPsRadarRoot\LibGit2Sharp.NativeBinaries.1.0.185\runtimes\win7-x86\native\git2-15e1193.dll") | Out-Null
    }
}