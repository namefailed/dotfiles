# Starts the Ollama server silently in the background
# Deployed from scripts.org
Start-Process -FilePath "$env:LOCALAPPDATA\Programs\Ollama\ollama.exe" -ArgumentList "serve" -WindowStyle Hidden
