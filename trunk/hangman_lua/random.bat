@setlocal
@set hangman_dict=..\words.txt
@lua52 RandomWords.lua 1000 | lua52 Main.lua
@endlocal
