//
//  PJLink+Auth.swift
//  pjlink-client-swift
//
//  Created by Eric Hyche on 12/18/25.
//

import Foundation

extension PJLink {

    public enum AuthRequest: Equatable {
        case securityLevel
    }

    public enum AuthResponse: Equatable {
        case authDisabled
        case securityLevel1(Buffer4)
        case securityLevel2(Buffer16)
        case authError
    }

    public struct Buffer4: Equatable {
        public var data: Data

        public init(data: Data) {
            self.data = data
        }
    }

    public struct Buffer16: Equatable {
        public var data: Data

        public init(data: Data) {
            self.data = data
        }
    }

    public struct Buffer32: Equatable {
        public var data: Data

        public init(data: Data) {
            self.data = data
        }
    }

    public enum ClientAuthState: Equatable {
        // We haven't sent or received anything yet.
        case indeterminate
        // We have received "PJLINK 0" indicating authentication is disabled
        case disabled
        // We have received something like "PJLINK 1 498e4a67" and then
        // we need to send a "PJLINK 2" to determine the security level.
        // We hold the 4-byte random number as an associated value.
        case securityLevelRequestPending(random4: Buffer4, password: String)
    }

    public enum AuthState: Equatable {
        // Projector has disabled authentication
        case disabled
        // Projector is using Class1 authentication
        case level1(projectorRandom: Buffer4, password: String)
        // Projector is using Class2 authentication
        case level2(clientRandom: Buffer16, projectorRandom: Buffer16, password: String)
        // At least 1 response has been authenticated, so there
        // is no further need to supply the authenticated
        // data before the request.
        case authenticated
    }

    public enum SecurityLevel: String {
        case disabled = "0"
        case level1 = "1"
        case level2 = "2"
    }
}

extension PJLink.Buffer4 {

    public init(_ data: Data) throws {
        guard data.count == 4 else {
            throw PJLink.Error.invalidDataBufferCount(expected: 4, actual: data.count)
        }
        self.data = data
    }
}

extension PJLink.Buffer16 {

    public init(_ data: Data) throws {
        guard data.count == 16 else {
            throw PJLink.Error.invalidDataBufferCount(expected: 16, actual: data.count)
        }
        self.data = data
    }

    public func combine(with other: Self, transform: (UInt8, UInt8) -> UInt8) -> Self {
        Self(data: Data(zip(self.data, other.data).map(transform)))
    }

    public func xor(with other: Self) -> Self {
        combine(with: other, transform: ^)
    }
}

extension PJLink.Buffer32 {

    public init(_ data: Data) throws {
        guard data.count == 32 else {
            throw PJLink.Error.invalidDataBufferCount(expected: 32, actual: data.count)
        }
        self.data = data
    }
}

extension PJLink.AuthRequest: LosslessStringConvertibleThrowing {

    public init(_ description: String) throws {
        let components = description.split(separator: " ")
        guard components.count == 2 else {
            throw PJLink.Error.invalidAuthRequestFieldCount(description)
        }
        guard components[0] == PJLink.pjlink else {
            throw PJLink.Error.invalidAuthRequestHeader(String(components[0]))
        }
        guard components[1] == PJLink.SecurityLevel.level2.rawValue else {
            throw PJLink.Error.invalidSecurityLevel(String(components[1]))
        }
        self = .securityLevel
    }

    public var description: String {
        PJLink.pjlink + " " + PJLink.SecurityLevel.level2.rawValue
    }
}

extension PJLink.AuthResponse: LosslessStringConvertibleThrowing {

    public init(_ description: String) throws {
        let components = description.split(separator: " ")
        guard components.count >= 2 else {
            throw PJLink.Error.invalidAuthResponseFieldCount(description)
        }
        guard components[0] == PJLink.pjlink else {
            throw PJLink.Error.invalidAuthResponseHeader(String(components[0]))
        }
        guard components[1] != "ERRA" else {
            self = .authError
            return
        }
        guard let authLevel = PJLink.SecurityLevel(rawValue: String(components[1])) else {
            throw PJLink.Error.invalidSecurityLevel(String(components[1]))
        }
        switch authLevel {
        case .disabled:
            guard components.count == 2 else {
                throw PJLink.Error.invalidAuthResponseFieldCount(description)
            }
            self = .authDisabled
        case .level1:
            guard components.count == 3 else {
                throw PJLink.Error.invalidAuthResponseFieldCount(description)
            }
            self = .securityLevel1(try .init(try Data(hex: String(components[2]))))
        case .level2:
            guard components.count == 3 else {
                throw PJLink.Error.invalidAuthResponseFieldCount(description)
            }
            self = .securityLevel2(try .init(try Data(hex: String(components[2]))))
        }
    }

    public var description: String {
        switch self {
        case .authDisabled:
            PJLink.pjlink + " " + PJLink.SecurityLevel.disabled.rawValue
        case .securityLevel1(let buffer4):
            PJLink.pjlink + " " + PJLink.SecurityLevel.level1.rawValue + " " + buffer4.data.hexEncodedString
        case .securityLevel2(let buffer16):
            PJLink.pjlink + " " + PJLink.SecurityLevel.level2.rawValue + " " + buffer16.data.hexEncodedString
        case .authError:
            PJLink.pjlink + " ERRA"
        }
    }
}

extension PJLink.AuthState {

    public static let level2ClientRandomCount = 32
    public static let level2ClientHashCount = 64

    public var expectedAuthSize: Int {
        switch self {
        case .disabled: 0
        case .level1: 32
        case .level2: 96
        case .authenticated: 0
        }
    }

    public var hash: String {
        switch self {
        case .disabled:
            return ""
        case .level1(let projectorRandom, let password):
            let toBeHashed = projectorRandom.data.hexEncodedString + password
            return Data(toBeHashed.utf8).md5.hexEncodedString
        case .level2(let clientRandom, let projectorRandom, let password):
            // XOR the projector and client random numbers
            let xorRandom16 = clientRandom.xor(with: projectorRandom)
            // Construct the string to be hashed. This string consists of:
            // - The hex-encoded XOR of the projector and client random numbers
            // - The password
            let toBeHashed = xorRandom16.data.hexEncodedString + password
            // Perform a SHA256 on this data and then hex-encode it.
            return Data(toBeHashed.utf8).sha256.hexEncodedString
        case .authenticated:
            return ""
        }
    }
}
