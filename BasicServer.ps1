# Loads the Config File
function Load-Config {
    $json = ""
    foreach($line in [System.IO.File]::ReadLines('./config.txt'))
    {
        $json = $json + $line + "`n"
    }
    $dict = @{}
    (ConvertFrom-Json $json).psobject.properties | Foreach {$dict[$_.Name] = $_.Value}
    return $dict
}

$config = Load-Config

if ($config."publicServer") {
    $hostPort = 27016
}
else {
    $hostPort = 27015
}

$endpoint = New-Object System.Net.IPEndPoint ([IPAddress]::Any, $hostPort)
$listener = New-Object System.Net.Sockets.TcpListener $endpoint
$encoding = new-object System.Text.AsciiEncoding 


# Fill message list
$messages = New-Object Collections.Generic.List[String]
foreach($line in [System.IO.File]::ReadLines('./messages.txt')) {
    $messages.Add($line)
}

# Start listener server
$listener.Start()
$ip = (Get-NetIPAddress -AddressFamily IPv4 -InterfaceAlias Wi-Fi).IPAddress

# This code handles the actual seperate threads created by the listener
function Handle-Client{
    $client = $listener.AcceptTcpClient()
    $stream = $client.GetStream()

    $streamReader = New-Object System.IO.StreamReader $stream

    $data = $streamReader.ReadLine()

    $streamReader.Close()

    # JSON Data checking, passes on errors
    try {
        $json = ConvertFrom-Json $data
        $method = $json."method"
        $username = $json."username"

        # "Send Message" - Adds a message to the message list & file
        if ($method -eq "send_message")
        {
            if ($config."users".$username -ne $null)
            {
                $message = $config."users".$username + " > " + $json."content"
            }
            else
            {
                $message = $username + " > " + $json."content"
            }
            $messages.Add($message)
            Add-Content '.\messages.txt' $message
        }
        # "Get Message" - Returns the last x messages
        elseif ($method -eq "get_messages")
        {
            $stream.Close()
            $client.Close()

            # Await the new & cleared connection
            $client = $listener.AcceptTcpClient()
            $stream = $client.GetStream()

            $streamWriter = New-Object System.IO.StreamWriter $stream

            $toSend = ""
            
            # Set up data to return to the client
            if ($config."shouldAuthenticate")
            {
                if ($config."users".$username -ne $null)
                {
                    foreach ($msg in ($messages | Select-Object -Last $config."returnMessages"))
                    {
                        $toSend = $toSend + $msg + "`n" 
                    }
                }
                else
                {
                    $toSend = "You are not a validated user on this server.`nIf you believe this to be a mistake, please contact the server owner."
                }
            }
            else
            {
                foreach ($msg in ($messages | Select-Object -Last $config."returnMessages"))
                {
                    $toSend = $toSend + $msg + "`n" 
                }
            }

            $streamWriter.Write($toSend)

            $streamWriter.Close()
        }

    }
    catch {}

    # Close streams
    $stream.Close()
    $client.Close

}

# Handles listenting
Write-Host "Listener Server started on" $ip"...."
while ($true) {
    # Await connection
    if ($listener.Pending()) { Invoke-Command -ScriptBlock { Handle-Client } }
}
$listener.Stop()