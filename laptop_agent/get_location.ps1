Add-Type -AssemblyName System.Device
$w = New-Object System.Device.Location.GeoCoordinateWatcher([System.Device.Location.GeoPositionAccuracy]::High)
$w.MovementThreshold = 0
$w.Start()

$best = $null
for ($i = 0; $i -lt 30; $i++) {
    $p = $w.Position.Location
    if (-not $p.IsUnknown -and $p.Latitude -ne 0 -and $p.Longitude -ne 0) {
        $best = $p
        if ($p.HorizontalAccuracy -gt 0 -and $p.HorizontalAccuracy -lt 1000) {
            break
        }
    }
    Start-Sleep -Milliseconds 300
}

if ($best -ne $null) {
    [PSCustomObject]@{
        Status = $w.Status.ToString()
        Permission = $w.Permission.ToString()
        Lat = $best.Latitude
        Lon = $best.Longitude
        Acc = $best.HorizontalAccuracy
    } | ConvertTo-Json -Compress
} else {
    Write-Output "{}"
}
