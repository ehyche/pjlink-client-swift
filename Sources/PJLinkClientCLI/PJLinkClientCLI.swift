// The Swift Programming Language
// https://docs.swift.org/swift-book
// 
// Swift Argument Parser
// https://swiftpackageindex.com/apple/swift-argument-parser/documentation

import ArgumentParser
import Foundation
import Network
import PJLinkCommon
import PJLinkClient

@main
struct PJLinkClientCLI: AsyncParsableCommand {
    @Option(help: "The IP address of the projector host.")
    var host: String

    mutating func run() async throws {
        let connection = NetworkConnection(to: .hostPort(host: "127.0.0.1", port: 4352)) {
            TCP()
        }

        connection.onBetterPathUpdate { connection, newValue in
            print("Client onBetterPathUpdate(\(connection), \(newValue))")
        }
        connection.onPathUpdate { connection, newPath in
            print("Client onPathUpdate(\(connection), \(newPath))")
        }
        connection.onViabilityUpdate { connection, newViable in
            print("Client onViabilityUpdate(\(connection), \(newViable))")
        }
        connection.onStateUpdate { connection, state in
            print("Client onStateUpdate(\(connection), \(state))")
        }

        while true {
            print("Enter a line to send to the projector (or Enter to exit): ", terminator: "")
            guard let line = readLine(), !line.isEmpty else { break }

            print("Sending to server: \"\(line)\"")
            try await connection.send(Data(line.utf8))

            let responseData = try await connection.receive(atMost: 1024).content
            guard let responseString = String(data: responseData, encoding: .utf8) else {
                print("Could not convert server response data to UTF8. Exiting.")
                break
            }
            print("Response from server: \"\(responseString)\"")
        }

        print("Client exiting.")
    }
}
