$logFile = "C:\Users\amans\AppData\Local\Temp\opencode\server_run.log"
Set-Location -LiteralPath "C:\ketta\backend"
node dist/index.js *>> $logFile
