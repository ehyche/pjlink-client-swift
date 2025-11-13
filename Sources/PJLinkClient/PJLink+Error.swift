//
//  PJLink+Error.swift
//  pjlink-client-swift
//
//  Created by Eric Hyche on 10/17/25.
//

import Foundation

extension PJLink {
    public enum Error: Swift.Error, Equatable {
        case couldNotCreateUTF8StringFromData(Data)
        case couldNotCreateDataFromUTF8String(String)
        case invalidID(String)
        case invalidClass(String)
        case invalidCommand(String)
        case invalidSeparator(String)
        case invalidClass1Input(String)
        case invalidClass2Input(String)
        case invalidClass1InputChannel(String)
        case invalidClass2InputChannel(String)
        case invalidOnOff(String)
        case invalidMute(String)
        case invalidVolume(String)
        case invalidFreeze(String)
        case invalidResolution(String)
        case invalidPowerStatus(String)
        case invalidErrorStatus(String)
        case invalidLampStatusCount(Int)
        case invalidLampUsageTime(String)
        case lampUsageTimeOutOfRange(Int)
        case invalidLampOnOff(String)
        case invalidFilterUsageTime(String)
        case filterUsageTimeOutOfRange(Int)
        case invalidSetResponseCode(String)
        case projectorNameExceedsMaximumLength(Int)
        case projectorNameContainsInvalidASCIIValue(UInt8)
        case manufacturerNameExceedsMaximumLength(Int)
        case unexpectedGetRequest(PJLink.Class, PJLink.Command, String)
        case unexpectedSetRequest(PJLink.Class, PJLink.Command)
        case unexpectedGetResponse(PJLink.Class, PJLink.Command)
    }
}
