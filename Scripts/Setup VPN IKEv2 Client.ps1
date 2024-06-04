Clear-Host
$Error.Clear()

# Parameters for create VPN connection

$Parameters1 = @{
	Name = "My IKEv2 VPN"
	ServerAddress = "Enter your Public IP"
	TunnelType = "IKEv2"
	AuthenticationMethod = "MachineCertificate"
	EncryptionLevel = "Required"
	SplitTunneling = [switch]::Present
	Force = [switch]::Present
	PassThru = [switch]::Present
	WarningAction = "SilentlyContinue"
}

# Parameters for IPsec configuration

$Parameters2 = @{
	ConnectionName = "My IKEv2 VPN"
	AuthenticationTransformConstants = "GCMAES128"
	CipherTransformConstants = "GCMAES128"
	EncryptionMethod = "AES256"
	IntegrityCheckMethod ="SHA256"
      PfsGroup = "None"
      DHGroup = "Group14"
      Force = [switch]::Present
	PassThru = [switch]::Present
}

Add-VpnConnection @Parameters1
Set-VpnConnectionIPsecConfiguration @Parameters2


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
Add-VpnConnectionRoute -ConnectionName "My IKEv2 VPN" -DestinationPrefix "192.168.0.0/24"
Add-VpnConnectionRoute -ConnectionName "My IKEv2 VPN" -DestinationPrefix "192.168.1.0/24"
Add-VpnConnectionRoute -ConnectionName "My IKEv2 VPN" -DestinationPrefix "192.168.2.0/24"

Write-Verbose -Message "`Routes to VPN servers were added" -Verbose


REG ADD HKLM\SYSTEM\CurrentControlSet\Services\RasMan\Parameters /v NegotiateDH2048_AES256 /t REG_DWORD /d 0x1 /f

Write-Verbose -Message "Necessary changes have been made to the registry" -Verbose