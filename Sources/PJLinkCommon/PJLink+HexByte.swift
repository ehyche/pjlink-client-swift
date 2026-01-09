//
//  PJLink+HexByte.swift
//  pjlink-client-swift
//
//  Created by Eric Hyche on 12/19/25.
//

extension PJLink {

    public struct HexByte: Equatable {
        var upper: HexCharacter
        var lower: HexCharacter
    }
}

extension PJLink.HexByte {

    var uint8Value: UInt8 {
        upper.uint8Value * 16 + lower.uint8Value
    }
}
