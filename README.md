# YazdanSwiftSocket
[![CocoaPods Compatible](https://img.shields.io/cocoapods/v/YazdanSwiftSocket.svg)](https://cocoapods.org/pods/YazdanSwiftSocket)
[![CocoaPods Platforms](https://img.shields.io/cocoapods/p/YazdanSwiftSocket.svg)](https://img.shields.io/cocoapods/p/YazdanSwiftSocket.svg)
[![Carthage Compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat)](https://github.com/Carthage/Carthage)

YazdanSwiftSocket library provides as easy to use interface for socket based connections on server or client side.
Supports both TCP and UDP sockets.


# Installation
## Cocoapods
Add this to your `Podfile`:
```ruby
pod 'YazdanSwiftSocket'
```
And run then `pod install`

## Carthage
```ruby
github "ymazdy/YazdanSwiftSocket"
```

# Code examples

## Create client socket
``` swift
// Create a socket connect to www.apple.com and port at 80
let client = TCPClient(address: "www.apple.com", port: 80)
```
## Connect with timeout
You can also set timeout to `-1` or leave parameters empty (`client.connect()`) to turn off connection timeout.
``` swift
 switch client.connect(timeout: 1.0) {
   case .success:
     // Connection successful 🎉
   case .failure(let error):
     // 💩
 }
```

## Send data
``` swift
let data: Data = // ... Bytes you want to send
let result = client.send(data: data)
```

## Read data
``` swift
var data = client.read(1024*10) //return optional [Int8]
```

## Read String Until certain delimiter
``` swift
if let string = client.readString(until: "delimiter") {
    print(string) //the data from socket up until "delimiter"
}
```

## Read All the Incoming String
``` swift
client.onMessage {msg in
    print(msg)              //Reads all the incoming data and when there is no more incoming data it will convert it into string, then calls this closure with the string
}
```

## Close socket
``` swift
client.close()
```

## Client socket example
``` swift
let client = TCPClient(address: "www.apple.com", port: 80)
switch client.connect(timeout: 1.5) {
  case .success:
    client.onMessage {msg in
        print(msg)
    }
    client.send(string: "GET / HTTP/1.0\n\n" )
  case .failure(let error):
    print(error)
}

```

## Server socket example (echo server)
``` swift
func echoService(client: TCPClient) {
    print("Newclient from:\(client.address)[\(client.port)]")
    var d = client.read(1024*10)
    client.send(data: d!)
    client.close()
}

func testServer() {
    let server = TCPServer(address: "127.0.0.1", port: 8080)
    switch server.listen() {
      case .success:
        while true {
            if var client = server.accept() {
                echoService(client: client)
            } else {
                print("accept error")
            }
        }
      case .failure(let error):
        print(error)
    }
}
```
