param(
    [string]$ReleaseVersion = ""
)

#Figure out the directory in which the script resides.
function Get-ScriptDirectory
{
$Invocation = (Get-Variable MyInvocation -Scope 1).Value
Split-Path $Invocation.MyCommand.Path
}

#IntPtr in 64bit is 8 bytes
function is64bit() {    if ([IntPtr].Size -eq 4) { return $false }    else { return $true }}

#$framework_dir_2 = "$env:systemroot\microsoft.net\framework\v2.0.50727"
$framework_dir_3_5 = "$env:systemroot\microsoft.net\framework\v3.5"
$base_dir = (get-item (Get-ScriptDirectory)).parent.FullName
$build_dir = "$base_dir\build"
$sln_file_2005 = "$base_dir\SQL2005_bidshelper.sln"

#utility locations
$msbuild = "$framework_dir_3_5\msbuild.exe"  
$tf = "$env:ProgramFiles\Microsoft Visual Studio 9.0\Common7\IDE\tf.exe"

if(is64bit -eq $true) 
{
$tf = "$env:ProgramFiles (x86)\Microsoft Visual Studio 9.0\Common7\IDE\tf.exe"
}


$zip = "$env:ProgramFiles\7-zip\7z.exe"

#version files
$versionFiles = @("$base_dir\Properties\AssemblyInfo.cs", "ascii"),
        @("$base_dir\setupScript\BIDSHelperSetup.nsi", "ascii"),
        @("$base_dir\setupScript\BIDSHelperSetup2008.nsi", "ascii"),
        @("$base_dir\setupScript\BIDSHelperSetup2012.nsi", "ascii"),
        @("$base_dir\setupScript\SQL2005CurrentReleaseVersion.xml", "UTF8"),
        @("$base_dir\setupScript\SQL2008CurrentReleaseVersion.xml", "UTF8"),
        @("$base_dir\setupScript\SQL2012CurrentReleaseVersion.xml", "UTF8"),
        @("$base_dir\BIDSHelper.Addin", "unicode"),
        @("$base_dir\BIDSHelper2008.Addin", "unicode")
        @("$base_dir\BIDSHelper2012.Addin", "unicode")
$lastReleaseFile = "$base_dir\setupScript\SQL2005CurrentReleaseVersion.xml"
$assemblyInfoFile = "$base_dir\Properties\AssemblyInfo.cs"

#Clean 

#checkVersion 
    if($ReleaseVersion.Length -eq 0)
    {
        # if we have not been given an explicit build, then use AssemblyInfo.cs
        [string]$(get-Content "$($assemblyInfoFile)") -cmatch '\d+\.\d+\.\d+\.\d+'
        $ver = $matches[0]
        
   		# HACK: having this regex match appears to make the replace statement work
		# removing it makes the following replace line fail for some reason.
        $null = $ver -cmatch "(?'main'\d+\.\d+\.\d+\.)(?'build'\d+)"
        
        $ReleaseVersion = $ver -replace "(?'main'\d+\.\d+\.\d+\.)(?'build'\d+)", "$($matches['main'])$([int]$matches['build'])"
    }

#Compile
    write-Host "Path: $msbuild"
    &($msbuild) $sln_file_2005 /t:Rebuild /p:Configuration=Release /v:q
    Write-Host "Executed Compile!"

#BuildXCopy 
    write-Host "Starting Zip"
    $ver = $ReleaseVersion -replace "\.", "_"
    &($zip) a -tzip "$base_dir\SetupScript\BIDSHelper2005_$ver.zip" "$base_dir\bin\BIDSHelper.dll"
	&($zip) a -tzip "$base_dir\SetupScript\BIDSHelper2005_$ver.zip" "$base_dir\bin\ExpressionEditor.dll"
    &($zip) a -tzip "$base_dir\SetupScript\BIDSHelper2005_$ver.zip" "$base_dir\BIDSHelper.Addin"
	&($zip) a -tzip "$base_dir\SetupScript\BIDSHelper2005_$ver.zip" "$base_dir\BIDS Helper xcopy deploy readme.txt"