Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing


$hostIp = "10.31.43.205"
$hostPort = 27015

# Get and parse User's server data
function Get-UserServers {
    $json = ""
    foreach($line in [System.IO.File]::ReadLines('./servers.txt'))
    {
        $json = $json + $line + "`n"
    }
    $dict = @{}
    (ConvertFrom-Json $json).psobject.properties | Foreach {$dict[$_.Name] = $_.Value}
    return $dict
}

function Main {
    while ($true)
    {
        # Get Server list
        Write-Host "--------------"
        $servers = Get-UserServers
        for ($i = 0; $i -lt $servers.count; $i += 1)
        {
            $serverName = $servers.keys | Select-Object -Index $i
            Write-Host $i": "$serverName "("$servers[$serverName][0]")"
        }
        Write-Host "--------------"

        # Write Promps
        Write-Host 'Please select a server number or choose one of the following:'
        Write-Host 'Enter "new" to connect to a new server.'
        Write-Host 'Enter "delete" to remove a server connection.'
        Write-Host 'To start a server, type "start".'

        $goTo = Read-Host
        # New Server
        if ($goTo -eq "new") {
            cls
            $name = Read-Host "Server Name"
            $ip = Read-Host "Server IP"
            while ($true){
                $pub = Read-Host "Is the server public? (Y/N)"
                    if ($pub -eq "y")
                    {
                        $port = 27015
                        break
                    }
                    elseif ($pub -eq "n")
                    {
                        $port = 27016
                        break
                    }
                cls
            }
            $servers[$name] = $ip, $port

            ConvertTo-Json $servers | Out-File .\servers.txt -Encoding utf8

            Write-Host "Created new server " $name
        }
        elseif ($goTo -eq "delete") {
            cls
            for ($i = 0; $i -lt $servers.count; $i += 1)
            {
                $serverName = $servers.keys | Select-Object -Index $i
                Write-Host $i": "$serverName "("$servers[$serverName][0]")"
            }

            $remove = Read-Host What server would you like to remove?
            try
            {
                $servers.Remove(($servers.keys | Select-Object -Index $remove))
                ConvertTo-Json $servers | Out-File .\servers.txt -Encoding utf8
                Write-Host Deleted server.
            }
            catch {}
            cls
        }
        # Start a server
        elseif ($goTo -eq "start") {
            Start-Process powershell.exe -ArgumentList '-file .\BasicServer.ps1'
            cls
            Write-Host "Disclaimer: The developer is not responsible for what happens on your server."
            Write-Host "Use at your own risk."
            Write-Host "Started Server."
        }
        # Connect to a server
        else {
            if ($goTo -ge 0 -and $goTo -le $servers.count - 1)
            {
                $serverName = $servers.keys | Select-Object -Index $goTo
                $hostIP = $servers[$serverName][0]
                $hostPort = $servers[$serverName][1]
                ConnectTo-Server
            }
            else
            {
                cls
                Write-Host "Invalid Server."
            }
        }
    }
}

# Creates a server connection, if no connection, returns null
function Create-ServerConnection {
    try
    {
        $client = New-Object System.Net.Sockets.TcpClient([IPAddress]$HostIP, $HOSTPORT)
        return $client
    } 
    catch 
    { 
        return $null 
    }
}

# Sends a message to the server
function Send-Message {   
    param($data)

    $client = Create-ServerConnection
    $stream = $client.GetStream()
    $streamWriter = New-Object System.IO.StreamWriter $stream

    $streamWriter.Write($data)

    $streamWriter.Close()
    $stream.Close()
    $client.Close()
}

# Handles connections to servers.
function ConnectTo-Server {
    # Get Username 
    $username = $env:USERNAME

    Write-Host Connecting to chat servers...

    # Checks the server connection before letting a user join
    while ($true)
                                                {
    $client = Create-ServerConnection
    try
    {
        $client.Close()
        break
    }
    catch
    {
        cls
        Read-Host Connection to the server could not be established. Press [Enter] to try again
    }
    }

    # Start Chat Window
    Start-Process 'powershell.exe' -ArgumentList '-file .\BasicRecvClient.ps1', $hostIP, $hostPort

    # Allows for the sending of messages
    while ($true)
                                                                                    {
    cls
    Write-Host 'Connection to the server established. Type "EXIT" to close the chat.'
    $content = Read-Host "To Send"
    # Check for empty content
    if ($content.Replace(" ", "") -eq "")
    {
        Write-Host "Server > Cannot send an empty message."
    }
    # Exit the chat
    elseif ($content -eq "EXIT")
    {
        break
    }
    # Send Message
    else
    {
        $message = '{"method":"send_message","username":"'+ $username +'","content":"' + $content + '"}'
        Send-Message $message
    }
    
    }
    cls
    Write-Host "The chat has been closed."
}

cls
Main