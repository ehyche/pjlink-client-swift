//
//  Data+Extensions.swift
//  pjlink-client-swift
//
//  Created by Eric Hyche on 12/19/25.
//

import CryptoKit
import Foundation
import Security

extension Data {

    var hexEncodedString: String {
        self.map { String(format: "%02x", $0) }.joined()
    }

    var utf8StringWithCRStripped: String? {
        guard let utf8String = String(data: self, encoding: .utf8) else {
            return nil
        }
        if let crIndex = utf8String.firstIndex(of: "\r") {
            return String(utf8String.prefix(upTo: crIndex))
        } else {
            return utf8String
        }
    }

    func toUTF8String() throws -> String {
        guard let utf8String = String(data: self, encoding: .utf8) else {
            throw PJLink.Error.couldNotConvertToUTF8(self)
        }
        guard let crIndex = utf8String.firstIndex(of: "\r") else {
            throw PJLink.Error.missingCarriageReturnSuffix(utf8String)
        }
        return String(utf8String.prefix(upTo: crIndex))
    }

    static func random(count: Int) throws -> Data {
        guard count > 0 else {
            throw PJLink.Error.invalidRandomByteCountArgument(count)
        }

        var bytes = [UInt8](repeating: 0, count: count)
        let status = SecRandomCopyBytes(kSecRandomDefault, count, &bytes)

        guard status == errSecSuccess else {
            throw PJLink.Error.failedToGenerateRandomBytes(count)
        }

        return Data(bytes)
    }

    var sha256: Data {
        var hash = SHA256()
        hash.update(data: self)
        let digest = hash.finalize()
        var output = [UInt8]()
        digest.withUnsafeBytes { buffer in
            output.append(contentsOf: buffer)
        }
        return Data(output)
    }

    var md5: Data {
        var hash = Insecure.MD5()
        hash.update(data: self)
        let digest = hash.finalize()
        var output = [UInt8]()
        digest.withUnsafeBytes { buffer in
            output.append(contentsOf: buffer)
        }
        return Data(output)
    }

    init(hex: String) throws {
        let hexChars = try hex.map { try PJLink.HexCharacter($0) }
        guard hexChars.count.isMultiple(of: 2) else {
            throw PJLink.Error.oddNumberOfHexCharacters(hex)
        }
        var bytes = [UInt8]()
        stride(from: 0, to: hexChars.count, by: 2).forEach { index in
            bytes.append(PJLink.HexByte(upper: hexChars[index], lower: hexChars[index + 1]).uint8Value)
        }
        self = Data(bytes)
    }
}
