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
        var data: Data
    }

    public struct Buffer16: Equatable {
        var data: Data
    }

    public struct Buffer32: Equatable {
        var data: Data
    }

    public enum AuthState: Equatable {
        case disabled
        case level1(hash: Buffer16)
        case level2(random: Buffer16, hash: Buffer32)
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

    func combine(with other: Self, transform: (UInt8, UInt8) -> UInt8) -> Self {
        Self(data: Data(zip(self.data, other.data).map(transform)))
    }

    func xor(with other: Self) -> Self {
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

extension PJLink.AuthRequest: CustomStringConvertible {

    public var description: String {
        PJLink.pjlink + " 2"
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

    public static func level1(projectorRandom4: PJLink.Buffer4, password: String) throws -> Self {
        // Construct the string to be hashed. This string consists of:
        // - The hex-encoded 4-byte projector random number
        // - The password
        let toBeHashed = projectorRandom4.data.hexEncodedString + password

        // Perform an MD5 hash on this string
        let md5 = try PJLink.Buffer16(Data(toBeHashed.utf8).md5)

        return .level1(hash: md5)
    }

    public static func level2(projectorRandom16: PJLink.Buffer16, password: String) throws -> Self {
        // Generate a 16-byte client random number
        let clientRandom16 = PJLink.Buffer16(data: try Data.random(count: 16))

        // XOR the projector and client random numbers
        let xorRandom16 = clientRandom16.xor(with: projectorRandom16)

        // Construct the string to be hashed. This string consists of:
        // - The hex-encoded XOR of the projector and client random numbers
        // - The password
        let toBeHashed = xorRandom16.data.hexEncodedString + password

        // Perform a SHA256 on this string
        let sha256 = try PJLink.Buffer32(Data(toBeHashed.utf8).sha256)

        return .level2(random: clientRandom16, hash: sha256)
    }
}

extension PJLink.AuthState: CustomStringConvertible {

    public var description: String {
        switch self {
        case .disabled: ""
        case .level1(let hash): hash.data.hexEncodedString
        case .level2(let random, let hash): random.data.hexEncodedString + hash.data.hexEncodedString
        }
    }
}
