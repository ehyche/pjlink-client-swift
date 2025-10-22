//
//  File.swift
//  pjlink-client-swift
//
//  Created by Eric Hyche on 10/20/25.
//

extension PJLink {

    public enum GetRequest: Equatable {
        case power
        case inputSwitch
        case avMute
        case errorStatus
        case lamp
        case inputList
        case projectorName
        case manufacturerName
        case productName
        case otherInformation
        case projectorClass
        case serialNumber
        case softwareVersion
        case inputTerminalName(InputSwitch)
        case inputResolution
        case recommendedResolution
        case filterUsageTime
        case lampReplacementModelNumber
        case filterReplacementModelNumber
        case speakerVolume
        case microphoneVolume
        case freeze
    }
}

extension PJLink.GetRequest: CustomStringConvertible {

    public var description: String {
        switch self {
        case .inputTerminalName(let inputSwitch): PJLink.prefixGet + inputSwitch.description
        default: PJLink.prefixGet
        }
    }
}
