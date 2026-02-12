@echo off
echo Downloading chess pieces from Lichess...

curl -o assets/chess_pieces/wK.svg https://lichess1.org/assets/piece/cburnett/wK.svg
curl -o assets/chess_pieces/wQ.svg https://lichess1.org/assets/piece/cburnett/wQ.svg
curl -o assets/chess_pieces/wR.svg https://lichess1.org/assets/piece/cburnett/wR.svg
curl -o assets/chess_pieces/wB.svg https://lichess1.org/assets/piece/cburnett/wB.svg
curl -o assets/chess_pieces/wN.svg https://lichess1.org/assets/piece/cburnett/wN.svg
curl -o assets/chess_pieces/wP.svg https://lichess1.org/assets/piece/cburnett/wP.svg

curl -o assets/chess_pieces/bK.svg https://lichess1.org/assets/piece/cburnett/bK.svg
curl -o assets/chess_pieces/bQ.svg https://lichess1.org/assets/piece/cburnett/bQ.svg
curl -o assets/chess_pieces/bR.svg https://lichess1.org/assets/piece/cburnett/bR.svg
curl -o assets/chess_pieces/bB.svg https://lichess1.org/assets/piece/cburnett/bB.svg
curl -o assets/chess_pieces/bN.svg https://lichess1.org/assets/piece/cburnett/bN.svg
curl -o assets/chess_pieces/bP.svg https://lichess1.org/assets/piece/cburnett/bP.svg

echo.
echo Done! All pieces downloaded.
pause
