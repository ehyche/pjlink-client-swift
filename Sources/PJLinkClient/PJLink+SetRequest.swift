//
//  PJLink+SetRequest.swift
//  pjlink-client-swift
//
//  Created by Eric Hyche on 10/20/25.
//

extension PJLink {

    public enum SetRequest: Equatable {
        case power(PJLink.OnOff)
        case inputSwitch(PJLink.InputSwitch)
        case avMute(PJLink.MuteState)
        case speakerVolume(PJLink.VolumeAdjustment)
        case microphoneVolume(PJLink.VolumeAdjustment)
        case freeze(PJLink.Freeze)
    }
}

extension PJLink.SetRequest {

    public init(command: PJLink.Command, parameters: String) throws {
        switch command {
        case .power:
            guard let onOff = PJLink.OnOff(rawValue: parameters) else {
                throw PJLink.Error.invalidOnOff(parameters)
            }
            self = .power(onOff)
        case .inputSwitch:
            self = .inputSwitch(try .init(parameters))
        case .avMute:
            self = .avMute(try .init(parameters))
        case .speakerVolume:
            guard let volumeAdjustment = PJLink.VolumeAdjustment(rawValue: parameters) else {
                throw PJLink.Error.invalidVolume(parameters)
            }
            self = .speakerVolume(volumeAdjustment)
        case .microphoneVolume:
            guard let volumeAdjustment = PJLink.VolumeAdjustment(rawValue: parameters) else {
                throw PJLink.Error.invalidVolume(parameters)
            }
            self = .microphoneVolume(volumeAdjustment)
        case .freeze:
            guard let freeze = PJLink.Freeze(rawValue: parameters) else {
                throw PJLink.Error.invalidFreeze(parameters)
            }
            self = .freeze(freeze)
        default:
            throw PJLink.Error.invalidSetCommand(command)
        }
    }
}

extension PJLink.SetRequest: CustomStringConvertible {

    public var description: String {
        switch self {
        case .power(let onOff): onOff.rawValue
        case .inputSwitch(let inputSwitch): inputSwitch.description
        case .avMute(let muteState): muteState.description
        case .speakerVolume(let volumeAdjustment): volumeAdjustment.rawValue
        case .microphoneVolume(let volumeAdjustment): volumeAdjustment.rawValue
        case .freeze(let freeze): freeze.rawValue
        }
    }
}
