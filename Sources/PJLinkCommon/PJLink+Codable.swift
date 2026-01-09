//
//  PJLink+Codable.swift
//  pjlink-client-swift
//
//  Created by Eric Hyche on 10/20/25.
//

import Foundation

extension PJLink.Message: Decodable {

    public init(from decoder: any Decoder) throws {
        var container = try decoder.unkeyedContainer()
        var bytes = [UInt8]()
        var byteValue = try container.decode(UInt8.self)
        while byteValue != PJLink.terminatorByte {
            bytes.append(byteValue)
            byteValue = try container.decode(UInt8.self)
        }
        let data = Data(bytes)
        guard let utf8 = String(data: data, encoding: .utf8) else {
            throw PJLink.Error.couldNotCreateUTF8StringFromData(data)
        }
        try self.init(utf8)
    }
}

extension PJLink.Message: Encodable {

    public func encode(to encoder: any Encoder) throws {
        let terminatedDesc = self.description + PJLink.terminator
        guard let data = terminatedDesc.data(using: .utf8) else {
            throw PJLink.Error.couldNotCreateDataFromUTF8String(terminatedDesc)
        }
        var container = encoder.singleValueContainer()
        try container.encode(data)
    }
}
