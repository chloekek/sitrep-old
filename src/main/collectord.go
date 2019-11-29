package main

import (
    "bufio"
    "log"
    "net"
    "sitrep/wire"
)

func main() {
    listen, err := net.Listen("tcp", "127.0.0.1:1324")
    if err != nil { log.Fatalf("net.Listen: %s", err) }
    defer listen.Close()
    for {
        client, err := listen.Accept()
        if err != nil { panic(err) }
        go handleClient(client)
    }
}

func handleClient(client net.Conn) {
    defer client.Close()
    r := bufio.NewReader(client)

    for {
        event, err := wire.ReadEvent(r)
        log.Printf("%#v %s", event, err)
        if err != nil { break }
    }
}
