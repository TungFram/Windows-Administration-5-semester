$scriptName = $PSCommandPath
write-host `nHello, this is $scriptName 

$ifIndexesOfInterfaces = (Get-NetAdapter).IfIndex
$namesOfInterfaces = (Get-NetAdapter).Name

while ($true)
{
    Write-Host "`nWhat do you want?"
    Write-Host "1) Configure interfaces"
    Write-Host "2) See info"
    $option = Read-Host 

    switch ($option)
    {
        1 {
            while ($true) 
            {
	            Write-Host "`nWhat interface would you like to configure?"
	            for ($i = 0; $i -lt $ifIndexesOfInterfaces.Count; $i++)
	            {
	                Write-Host ($i+1)"<==>" $ifIndexesOfInterfaces[$i] $namesOfInterfaces[$i]
	            }
	
	            $num = Read-Host 
                if ($num -match '[^-0-9]+') {
                    Write-Warning "Interface can be chosen only by number!"
                    Continue
                }

                #Write-Host $num.GetType()
                $num = [int]$num
                #Write-Host $num.GetType()

	            if ($num -gt ($ifIndexesOfInterfaces.Count))
	            {
	                Write-Warning -"`nYour number is more that each number of interface."
	                Write-Host Maximum possible number is $ifIndexesOfInterfaces.Count`n
                    Continue
	            }

                if ($num -le 0)
	            {
	                Write-Warning "`nYour number is less that each number of interface."
	                Write-Host "Minimum possible number is 1.`n"
                    Continue
	            }

                $interfaceIndex = $ifIndexesOfInterfaces[$num - 1]
                Write-Host "`nOk, what mode do you prefer?"
                Write-Host "1) Auto"
                Write-Host "2) Manual"
                Write-Host "Everything else)  exit"
                $mode = Read-Host

                switch ($mode) {
                    1 {
                        # Перед активацией DHCP на сетевом интерфейсе нужно удалить настройки IP адреса (если они имеются).

                        # Удаляем дефолтный шлюз:
                        Remove-NetRoute -InterfaceIndex $interfaceIndex

                        # Включаем DHCP на сетевом интерфейсе:
                        Set-NetIPInterface -InterfaceIndex $interfaceIndex -Dhcp Enabled

                        # Удаляем записи о DNS серверах, чтобы настройки DNS также получались автоматически:
                        Set-DnsClientServerAddress -InterfaceIndex $interfaceIndex -ResetServerAddresses

                        # И, наконец, убеждаемся в том, что всё поменялось:
                        Get-NetIPConfiguration -InterfaceIndex $interfaceIndex
                        Pause
                        Continue
                    }

                    2 {
                        $ipParams = @{
                            InterfaceIndex = $interfaceIndex
                            IPAddress = "192.168.1.10"
                            PrefixLength = 24
                            DefaultGateway = "192.168.1.1"
                            AddressFamily = "IPv4"
                        }

                        $dnsParams = @{
                            InterfaceIndex = $interfaceIndex
                            ServerAddresses = ("8.8.8.8")
                        }

                        if ((Get-NetIPConfiguration -InterfaceIndex 12 -Detailed).NetIPv4Interface.DHCP -ne "Enabled")
                        {                      
                            # Т.к. мы не можем напрямую заменить все параметры, потому что шлюз не изменится, удалим все, 
                            # а потом заново поставим:

                            # Удаляем статичный IP адрес:
                            Remove-NetIPAddress -InterfaceIndex $interfaceIndex

                            # Удаляем дефолтный шлюз:
                            Remove-NetRoute -InterfaceIndex $interfaceIndex
                        }

                        # Добавляем новый IP адрес и шлюз:
                        New-NetIPAddress @ipParams

                        # Задаёс DNS через заранее подготовленные параметры:
                        Set-DnsClientServerAddress @dnsParams                   
                        
                        # И, наконец, убеждаемся в том, что всё поменялось:
                        Get-NetIPConfiguration -InterfaceIndex $interfaceIndex
                        Pause
                        Continue
                    }

                    Default { 
                        Write-Host "Do you want to exit from configuring? [Y/N]"
                        $confirmExit = Read-Host
                        if ($confirmExit -match '[YyНн]') {
                            Break;
                        }
                    }
                }

                Write-Host "Do you want configure something else? [Y/N]"
                $confirmExit = Read-Host
                if ($confirmExit -match '[^YyНн]') {
                    Break;
                }
            }
        }

        2 {
            foreach ($interfaceIndex in $ifIndexesOfInterfaces) {
                Get-NetIPConfiguration -InterfaceIndex $interfaceIndex
            }
        }

        Default { 
            Write-Host "Do you want to exit from options? [Y/N]"
            $confirmExit = Read-Host
            if ($confirmExit -match '[YyНн]') {
                Break;
            }
        }
    }

    Write-Host "Do you want to exit from programm? [Y/N]"
    $confirmExit = Read-Host
    if ($confirmExit -match '[YyНн]') {
        Break;
    }
}

