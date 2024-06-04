Clear-Host
$Error.Clear()

# Parameters for create VPN connection
$Parameters = @{
	Name = "My L2TP VPN"
	ServerAddress = "EnterYourPublicIP"
	TunnelType = "L2tp"
	AuthenticationMethod = "MsChapv2"
	EncryptionLevel = "Required"
	SplitTunneling = [switch]::Present
#	DnsSuffix = "8.8.8.8"
	L2tpPsk = "EnterYourKey"
	Force = [switch]::Present
	PassThru = [switch]::Present
	WarningAction = "SilentlyContinue"
}
Add-VpnConnection @Parameters

if ($Error)
{
	Write-Verbose -Message "Network: VPN was not created. Please fix the reason and run script again" -Verbose
	Write-Verbose -Message "Contact system team if you couldn't fix it by yourself" -Verbose

	exit
}
else
{
	Write-Verbose -Message "Network: VPN created successfully" -Verbose
}

# Modify VPN file configuration

$pbkpath = "$env:APPDATA\Microsoft\Network\Connections\Pbk\rasphone.pbk"
$rasphone = Get-Content -Path $pbkpath
if ($rasphone | Select-String -Pattern "UseRasCredentials=1")
{
	($rasphone) -replace "UseRasCredentials=1", "UseRasCredentials=0" | Set-Content -Path $pbkpath -Encoding Default -Force

	Write-Verbose -Message "File with VPN settings was modified successfully" -Verbose
}

# Add route to your VPN subnets
Add-VpnConnectionRoute -ConnectionName "My L2TP VPN" -DestinationPrefix "192.168.0.0/24"
Add-VpnConnectionRoute -ConnectionName "My L2TP VPN" -DestinationPrefix "192.168.1.0/24"
Add-VpnConnectionRoute -ConnectionName "My L2TP VPN" -DestinationPrefix "192.168.2.0/24"


Write-Verbose -Message "`Routes to VPN servers were added" -Verbose


REG ADD HKLM\SYSTEM\CurrentControlSet\Services\PolicyAgent /v AssumeUDPEncapsulationContextOnSendRule /t REG_DWORD /d 0x2 /f
REG ADD HKLM\SYSTEM\CurrentControlSet\Services\RasMan\Parameters /v ProhibitIpSec /t REG_DWORD /d 0x0 /f

Write-Verbose -Message "Necessary changes have been made to the registry" -Verbose

Write-Verbose -Message "All is Ok, you may connect to Home network using VPN" -Verbose
