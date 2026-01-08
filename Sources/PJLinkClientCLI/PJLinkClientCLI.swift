// The Swift Programming Language
// https://docs.swift.org/swift-book
// 
// Swift Argument Parser
// https://swiftpackageindex.com/apple/swift-argument-parser/documentation

import ArgumentParser
import Foundation
import Network
import PJLinkClient

@main
struct PJLinkClientCLI: ParsableCommand {
    @Option(help: "The IP address of the projector host.")
    var host: String

    @Option(help: "The password for the projector.")
    var password: String = ""

    mutating func run() async throws {
        // Connect to the projector
        let connectionState = try await PJLink.Client.authenticate(
            at: .hostPort(host: .init(host), port: 4352),
            password: password
        )

        // Fetch the state
        let state = try await PJLink.Client.fetchState(from: connectionState)

        // Print out the state
        print("Projector State:\n\n\(state)")
    }
}
