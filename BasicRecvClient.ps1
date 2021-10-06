Write-Host "This is the chat screen. Please wait while it starts up..."

$HOSTIP = $args[0]
$HOSTPORT = $args[1]

# Empties the new Message variables
$newMsgs = "x"
$oldMsgs = "x"

# Creates a Server Connection, or returns null
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

# Runs updates the chat window
function Update-Messages {
    while ($true)
    {
        # If there is an error, mark as connection issue
        try
        {
            Sleep 1

            $client = Create-ServerConnection
            $stream = $client.GetStream()

            # Send data request
            $streamWriter = New-Object System.IO.StreamWriter $stream
            $streamWriter.WriteLine('{"method":"get_messages","username":' + $env:USERNAME + '}')

            # Close out streams
            $streamWriter.Close()
            $stream.Close()
            $client.Close()

            # Create a new client connectiont to clear streams

            $client = Create-ServerConnection
            $stream = $client.GetStream()

            # Read new messages
            $streamReader = New-Object System.IO.StreamReader $stream
            $newMsgs = $streamReader.ReadToEnd()

            # Close out streams
            $streamReader.Close()
            $stream.Close()
            $client.Close()

            # Check & Update message dislpay
            if ($oldMsgs -ne $newMsgs -or ($oldMsgs -eq "x" -and $newMsgs -ne "x"))
            {
                cls
                Write-Host $newMsgs
                $oldMsgs = $newMsgs
            }
        }
        catch
        {
            cls
            Write-Host "Lost Connection to the server..."
        }
    }
}

Update-Messages
