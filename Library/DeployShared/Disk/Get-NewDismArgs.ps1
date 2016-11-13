function Get-NewDismArgs
{
    $LogPath = [System.IO.Path]::GetTempFileName()
    write-verbose "New DISM LogLevel [3]  LogPath: $LogPath"
    @{ LogLevel = [Microsoft.Dism.Commands.LogLevel]::WarningsInfo ;  LogPath = $LogPath } | Write-Output
}