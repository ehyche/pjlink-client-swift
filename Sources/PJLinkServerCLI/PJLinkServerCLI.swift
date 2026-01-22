// The Swift Programming Language
// https://docs.swift.org/swift-book
//
// Swift Argument Parser
// https://swiftpackageindex.com/apple/swift-argument-parser/documentation

import ArgumentParser
import Foundation
import Network
import PJLinkCommon
import PJLinkServer

@main
struct PJLinkServerCLI: AsyncParsableCommand {
    @Option(help: "The IP address of the projector host.")
    var host: String

    mutating func run() async throws {
        let server = PJLink.Server(config: .mock)
        try await server.run()
    }
}
