<#


#>

[cmdletbinding()]
param(
    [parameter(Mandatory=$true)]
    [string] $ImagePath,
    [parameter(Mandatory=$true)]
    [string] $Path,
    [parameter(Mandatory=$true)]
    [string[]] $Patches,
    [parameter(Mandatory=$true)]
    [string] $PackagePath,
    [string] $LogPath,
    [string] $ForceADKDISM,
    [int] $Index = 1
)

Write-Verbose "Update Windows 7 image"
$local:ErrorActionPreference = 'stop'

$PSBoundParameters | Out-String |Write-Verbose

#region prep path
###########################################################
Write-Verbose "Prep parameters"

if ( -not ( test-path $imagepath ) ) { throw "missing image.wim at [$ImagePath]" }
if ( -not ( test-path $path ) )
{
    new-item -ItemType directory -path $path -force | out-string |write-verbose
}

if ( -not ( test-path $PackagePath ) )
{
    new-item -ItemType directory -path $PackagePath -force | out-string |write-verbose
}

#endregion

#region Get-Patches
###########################################################
Write-Verbose "Download Patches"

foreach ( $uri in $patches -split ',' ) 
{
    $LocalFile = join-path $PackagePath ( split-path -leaf $uri )
    if ( -not ( Test-Path $LocalFile ) )
    {
        Write-verbose "download FIle $uri to $LocalFile"
        (New-Object net.webclient).DownloadFile($uri,$LocalFile)
        # Invoke-WebRequest -Uri $uri -OutFile $LocalFile   #Too SLOW!
    }
}

#endregion

#region Mount Image
###########################################################
Write-Verbose "Mount Image"

Mount-WindowsImage -path $path -ImagePath $imagePath -Index $index  -LogPath $LogPath

if ( -not ( test-path $path\windows\system32\ntoskrnl.exe ) ) { throw "did not mount $ImagePath" }

#endregion

#region Service Image
###########################################################
Write-Verbose "Update Windows 7`n Mount Image"

for ( $I = 0; $i -lt 3; $i++ )
{

    try 
    {
        write-verbose "Add-WindowsPackage Pass $i"
        if ( $ForceADKDISM )
        {
             & $ForceADKDISM "/image:$Path" /Add-Package "/PackagePath:$PackagePath"
            if ( -not $? ) 
            {
                Write-Warning "DISM return $lastExitCode"
                throw new-object System.InvalidOperationException
            }
        }
        else 
        {
            Add-WindowsPackage -LogPath $LogPath -NoRestart -PackagePath $PackagePath -Path $Path
        }
        $Success = $true
        break
    }
    catch [System.Runtime.InteropServices.COMException],[System.InvalidOperationException]
    {
        write-verbose "ARGH, for whatever reason, DISM is FAILING the first time, run again"
        write-warning ("retry {0}: '{1}'" -f ($_.Exception.GetType().FullName), ($_.Exception.Message))
    }
    catch
    {
        write-error ("error: {0}: '{1}'" -f ($_.Exception.GetType().FullName), ($_.Exception.Message)) -ErrorAction SilentlyContinue
        break;
        $Success = $False
    }

}

#endregion

#region Mount Image
###########################################################
Write-Verbose "dismount Windows Image"

if ( $Success -eq $true )
{
    Dismount-WindowsImage -LogPath $LogPath -Save -Path $path
}
else 
{
    Dismount-WindowsImage -LogPath $LogPath -discard -Path $path
}

#endregion

