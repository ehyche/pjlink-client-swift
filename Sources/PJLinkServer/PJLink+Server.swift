//
//  PJLink+Server.swift
//  pjlink-client-swift
//
//  Created by Eric Hyche on 1/9/26.
//

import ConcurrencyExtras
import Foundation
import Network
import PJLinkCommon

extension PJLink {

    public final class Server {
//        private var config: ServerConfig
//        private var stateActor: StateActor
        let serverConnections = LockIsolated<[ServerConnection]>([])

        public init() { }

        public func run() async throws {
            let listener = try NetworkListener(
                using: .parameters {
                    TCP()
                }
                .localPort(4352)
            )
            listener.onServiceRegistrationUpdate { listener, change in
                print("NetworkListener.onServiceRegistrationUpdate(\(listener), \(change))")
            }
            listener.onStateUpdate { listener, state in
                print("NetworkListener.onStateUpdate(\(listener), \(state))")
            }
            try await listener.run { [serverConnections = self.serverConnections] connection in
                print("NetworkListener.run() connection=\(connection)")
                let serverConnection = ServerConnection(connection: connection) { serverConn in
                    print("ServerConnection.onTerminated(\(serverConn))")
                    serverConnections.withValue {
                        if let index = $0.firstIndex(where: { $0 === serverConn }) {
                            $0.remove(at: index)
                            print("Server removed ServerConnection: \(serverConn)")
                            print("Current ServerConnection count: \($0.count)")
                        } else {

                        }
                    }
                }
                serverConnections.withValue {
                    $0.append(serverConnection)
                    print("Server added ServerConnection: \(serverConnection)")
                    print("Current ServerConnection count: \($0.count)")
                }
                try await serverConnection.run()
            }
        }
    }

    public struct ServerConfig: Codable {
        public var initialState: PJLink.State
    }

//    public static func authenticate(
//        on connection: NetworkConnection<TCP>,
//        pjLinkClass: PJLink.Class,
//        password: String?
//    ) async throws -> PJLink.AuthState {
//        // We initially respond with either:
//        // - "PJLINK 0" (if auth is disabled); OR
//        // - "PJLINK 1 498e4a67" (if auth is enabled)
//        let randomBuffer4 = try Buffer4(Data.random(count: 4))
//        let firstResponse: PJLink.AuthResponse = password != nil ? .securityLevel1(randomBuffer4) : .authDisabled
//        try await connection.send(firstResponse.description.crTerminatedData)
//
//        guard let password else {
//            // Auth is disabled, so we return AuthState.disabled
//            return .disabled
//        }
//
//        guard pjLinkClass == .two else {
//            // We are emulating a Class 1 projector
//            return .level1(projectorRandom: randomBuffer4, password: password)
//        }
//
//        // We expect a request which is a security level check ("PJLINK 2")
//        let authRequestData = try await connection.receive(atMost: 9).content
//        let authRequestUTF8 = try authRequestData.toUTF8String()
//        let authRequest = try PJLink.AuthRequest(authRequestUTF8)
//
//        // Our second response is "PJLINK 2 <hex-encoded-16-byte-random-number>\r"
//        let randomBuffer16 = try Buffer16(Data.random(count: 16))
//        let secondResponse: PJLink.AuthResponse = .securityLevel2(randomBuffer16)
//        try await connection.send(firstResponse.description.crTerminatedData)
//
//    }
//
//    public static func receiveRequest(
//        on connection: NetworkConnection<TCP>,
//        auth: PJLink.AuthState
//    ) async throws -> PJLink.Message.Request {
//        let maxRequestSize = auth.expectedAuthSize + PJLink.maxRequestSize
//        let requestData = try await connection.receive(atMost: maxRequestSize).content
//        let requestUTF8 = try requestData.toUTF8String()
//
//        // Validate authentication
//        let requestString = try validateAuth(requestUTF8, auth: auth)
//        // Parse the request string
//        return try .init(requestString)
//    }
//
//    private static func validateAuth(_ request: String, auth: PJLink.AuthState) throws -> String {
//        // We look for the "%" which marks the beginning of the request.
//        guard let percentIndex = request.firstIndex(of: PJLink.identifierCharacter) else {
//            throw PJLink.Error.requestContainsNoIdentifier(request)
//        }
//        // Split the string into authentication and request
//        let authString = String(request[request.startIndex..<percentIndex])
//        let requestString = String(request[percentIndex..<request.endIndex])
//
//        // Verify we have the expected size
//        guard authString.count == auth.expectedAuthSize else {
//            throw PJLink.Error.unexpectedRequestAuthSize(expected: auth.expectedAuthSize, actual: authString.count)
//        }
//
//        let validateResult = validateAuthenticationString(authString, auth: auth)
//        guard validateResult else {
//            throw PJLink.Error.requestFailsValidation(request)
//        }
//
//        return requestString
//    }
//
//    private static func validateAuthenticationString(_ authString: String, auth: PJLink.AuthState) -> Bool {
//        authString == auth.hash
//    }
}
