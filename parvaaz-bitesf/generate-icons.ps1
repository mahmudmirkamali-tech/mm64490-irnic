Add-Type -AssemblyName System.Drawing
$iconDir = Join-Path $PSScriptRoot "icons"
if (-not (Test-Path $iconDir)) { New-Item -ItemType Directory -Path $iconDir | Out-Null }

foreach ($size in @(192, 512)) {
    $bmp = New-Object System.Drawing.Bitmap($size, $size)
    $g = [System.Drawing.Graphics]::FromImage($bmp)
    $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
    $g.Clear([System.Drawing.Color]::FromArgb(8, 10, 15))
    $gold = [System.Drawing.Color]::FromArgb(201, 168, 76)
    $penWidth = [Math]::Max(2, [int]($size / 64))
    $pen = New-Object System.Drawing.Pen($gold, $penWidth)
    $cx = $size / 2
    $g.DrawLine($pen, $cx, $size * 0.22, $cx, $size * 0.58)
    $g.DrawLine($pen, $size * 0.28, $size * 0.24, $size * 0.72, $size * 0.24)
    $g.DrawEllipse($pen, $size * 0.32, $size * 0.42, $size * 0.14, $size * 0.06)
    $g.DrawEllipse($pen, $size * 0.54, $size * 0.42, $size * 0.14, $size * 0.06)
    $brush = New-Object System.Drawing.SolidBrush($gold)
    $fontSize = [Math]::Max(8, $size / 14)
    $font = New-Object System.Drawing.Font("Arial", $fontSize, [System.Drawing.FontStyle]::Bold)
    $sf = New-Object System.Drawing.StringFormat
    $sf.Alignment = [System.Drawing.StringAlignment]::Center
    $sf.LineAlignment = [System.Drawing.StringAlignment]::Center
    $rect = New-Object System.Drawing.RectangleF([float]0, [float]($size * 0.62), [float]$size, [float]($size * 0.28))
    $g.DrawString("P", $font, $brush, $rect, $sf)
    $path = Join-Path $iconDir "icon-$size.png"
    $bmp.Save($path, [System.Drawing.Imaging.ImageFormat]::Png)
    $g.Dispose()
    $bmp.Dispose()
    Write-Host "Created $path"
}
