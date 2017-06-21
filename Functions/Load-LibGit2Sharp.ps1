function Load-LibGit2Sharp
{
    param(
        [Parameter(Mandatory=$true)]
        [string]
       # The Git-PsRadar module path
        $GitPsRadarRoot
    )

    if ($global:lib2gitsharp -eq $null) {
        
        $global:lib2gitsharp = Add-Type -Path "$GitPsRadarRoot\LibGit2Sharp.0.23.1\lib\net40\LibGit2Sharp.dll"

        $loadLibSignature = '
            [DllImport("kernel32.dll")]
            public static extern IntPtr LoadLibrary(string dllToLoad);'

        $win32Type = Add-Type -MemberDefinition $loadLibSignature -Name Win32Utils -Namespace GitPsRadar -PassThru

        if ([Environment]::Is64BitProcess) {
            $win32Type::LoadLibrary("$GitPsRadarRoot\LibGit2Sharp.NativeBinaries.1.0.164\runtimes\win7-x64\native\git2-a5cf255.dll") | Out-Null
        } else {
            $win32Type::LoadLibrary("$GitPsRadarRoot\LibGit2Sharp.NativeBinaries.1.0.164\runtimes\win7-x86\native\git2-a5cf255.dll") | Out-Null
        }
    }
}