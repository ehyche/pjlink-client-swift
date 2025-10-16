// The Swift Programming Language
// https://docs.swift.org/swift-book
// 
// Swift Argument Parser
// https://swiftpackageindex.com/apple/swift-argument-parser/documentation

import ArgumentParser
import Foundation
import Network

@main
struct pjlink_client: ParsableCommand {
    mutating func run() async throws {
        let connection = NetworkConnection(to: .hostPort(host: "192.168.64.2", port: 4352)) {
            TCP {
                IP()
            }
        }

        let expectedResponse = Data("PJLINK 0\n".utf8)
        let connectionResponse = try await connection.receive(exactly: 9).content

        guard expectedResponse == connectionResponse else {
            print("Did not receive expected connection response.")
            return
        }
        print("Received non-authenticated connection response.")

        let powerQuery = Data("%1POWR ?\n".utf8)
        try await connection.send(powerQuery)

        let powerQueryResponse = try await connection.receive(atLeast: 9, atMost: 10).content

        guard let powerQueryResponseString = String(data: powerQueryResponse, encoding: .utf8) else {
            print("Received power query response could not be converted to UTF8 string.")
            return
        }
        print("Received \"\(powerQueryResponseString)\"")
    }
}
