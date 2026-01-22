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
    @Option(help: "The relative path to the server configuration JSON file.")
    var configFile: String

    mutating func run() async throws {
        let configFileURL = URL(filePath: configFile, relativeTo: URL.currentDirectory())
        let configFileData = try Data(contentsOf: configFileURL)
        let config = try JSONDecoder().decode(PJLink.ServerConfig.self, from: configFileData)
        let server = PJLink.Server(config: config)
        try await server.run()
    }
}
