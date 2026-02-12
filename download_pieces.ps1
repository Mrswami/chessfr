# Download Lichess chess piece SVGs
$pieces = @(
    "wK", "wQ", "wR", "wB", "wN", "wP",
    "bK", "bQ", "bR", "bB", "bN", "bP"
)

$baseUrl = "https://lichess1.org/assets/piece/cburnett"
$outputDir = "assets\chess_pieces"

Write-Host "Downloading chess pieces from Lichess..." -ForegroundColor Cyan

foreach ($piece in $pieces) {
    $url = "$baseUrl/$piece.svg"
    $output = "$outputDir\$piece.svg"
    
    try {
        Invoke-WebRequest -Uri $url -OutFile $output -ErrorAction Stop
        Write-Host "✓ Downloaded $piece.svg" -ForegroundColor Green
    }
    catch {
        Write-Host "✗ Failed to download $piece.svg" -ForegroundColor Red
    }
}

Write-Host "`nDone! All pieces downloaded to $outputDir" -ForegroundColor Cyan
