# Verify RDP port 3389
$testResult = Test-NetConnection -ComputerName 156.231.141.29 -Port 33890
if (-not $testResult.TcpTestSucceeded) { throw "TCP connection to 33890 failed" }
Write-Host "TCP connectivity successful!"
