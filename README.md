# Powershell Chatroom
A basic chat room system using TCP Clients and Powershell

## How it works
By using a threaded TCP Listener server, the chat room is able to maintain multiple connections, resources permitting.
Each client has access to any server they wish, if they are authenticated onit. By using the local username, you can also create a set of nicknames that show in the server chat.
Anyone on the local internet network can connect, as long as the propper configurations are specified.

A user may connect to a server by creating a new entry (typing "`new`" on the client start menu - these are stored in the local file `servers.txt`.). With the new server entry, they can connect by simply typing the index number displayed in the server list.

## Starting a Server
A server can be started through the client, by typing "`start`" on the selection menu. The server's settings are determined by the data found in the local file `config.txt`. After starting the server, the IP Address that can be connected to will be shown at the top of the console.

## Server Config
The default configuration is as follows:
```json
{
    "publicServer": false,
    "shouldAuthenticate":  true,
    "returnMessages":  20,
    "users":  {
                  "ExampleUser":  "Mr. Foo"
              }
}
```
| Property | Usage | Possible Values |
|-----|-----|-----|
| `publicServer` | Marks the server as public, setting the port to `27016`, or private, setting it to `27015`. | `true` or `false` |
| `shouldAuthenticate` | Decides whether or not the server should authenticate incoming users | `true` or `false` |
| `returnMessages`| Sets the number of messages that the server returns to a client | Any integer greater than 0 (larger numbers will take more time to transfer.) |
| `users` | Any username recorded in the `users` property will be authenticated, and will have their name replaced in the chat room with the given name. | `"string"`: `"string"` |

## Disclaimer
Obviously, this system isn't very secure. You can authenticate yourself as a user very easily by changing the `$username` variable that is passed in the client. Messages are sent through unencrypted JSON over the local network, and are easily intercepted. It is highly advised to *not* use this as a means of transfering sensitive information.

Along with the above mentioned security issues, the server by default has no form of content filtering. Users are able to freely send anything they wish, at any time the server is running.
