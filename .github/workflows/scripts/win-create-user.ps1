# Create RDP user with strong password
Add-Type -AssemblyName System.Security
$securePass = ConvertTo-SecureString Pass@Word1 -AsPlainText -Force
New-LocalUser -Name "administrator" -Password $securePass -AccountNeverExpires
Add-LocalGroupMember -Group "Administrators" -Member "administrator"
Add-LocalGroupMember -Group "Remote Desktop Users" -Member "administrator"
echo "RDP_CREDS=User: vum | Password: Pass@Word1" >> $env:GITHUB_ENV
if (-not (Get-LocalUser -Name "vum")) { throw "User creation failed" }
