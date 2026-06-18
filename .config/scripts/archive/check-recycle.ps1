$shell = New-Object -ComObject Shell.Application
$bin = $shell.Namespace(0xA)
$items = $bin.Items()
foreach ($item in $items) {
    if ($item.Name -eq "antigravity") {
        Write-Host "Found: $($item.Name)"
        Write-Host "Original path: $($item.ExtendedProperty('System.Recycle.DeletedFrom'))"
        Write-Host "Date deleted: $($item.ExtendedProperty('System.Recycle.DateDeleted'))"
        if ($item.IsFolder) {
            Write-Host "Contents:"
            $item.GetFolder.Items() | ForEach-Object {
                Write-Host "  $($_.Name)  $($_.Size)"
            }
        }
    }
}
