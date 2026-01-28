//
//  PJLink+SetRequest.swift
//  pjlink-client-swift
//
//  Created by Eric Hyche on 10/20/25.
//

extension PJLink {

    public enum SetRequest: Equatable {
        case power(PJLink.OnOff)
        case inputSwitchClass1(PJLink.InputSwitchClass1)
        case inputSwitchClass2(PJLink.InputSwitchClass2)
        case avMute(PJLink.MuteState)
        case speakerVolume(PJLink.VolumeAdjustment)
        case microphoneVolume(PJLink.VolumeAdjustment)
        case freeze(PJLink.Freeze)
    }
}

extension PJLink.SetRequest {

    public init(pjlinkClass: PJLink.Class, command: PJLink.Command, parameters: String) throws {
        switch (pjlinkClass, command) {
        case (.one, .power):
            self = .power(try .init(parameters))
        case (.one, .inputSwitch):
            self = .inputSwitchClass1(try .init(parameters))
        case (.two, .inputSwitch):
            self = .inputSwitchClass2(try .init(parameters))
        case (.one, .avMute):
            self = .avMute(try .init(parameters))
        case (.two, .speakerVolume):
            self = .speakerVolume(try .init(parameters))
        case (.two, .microphoneVolume):
            self = .microphoneVolume(try .init(parameters))
        case (.two, .freeze):
            self = .freeze(try .init(parameters))
        default:
            throw PJLink.Error.unexpectedSetRequest(pjlinkClass, command)
        }
    }

    public var `class`: PJLink.Class {
        switch self {
        case .power: .one
        case .inputSwitchClass1: .one
        case .inputSwitchClass2: .two
        case .avMute: .one
        case .speakerVolume: .two
        case .microphoneVolume: .two
        case .freeze: .two
        }
    }

    public var command: PJLink.Command {
        switch self {
        case .power: .power
        case .inputSwitchClass1, .inputSwitchClass2: .inputSwitch
        case .avMute: .avMute
        case .speakerVolume: .speakerVolume
        case .microphoneVolume: .microphoneVolume
        case .freeze: .freeze
        }
    }

    public var parameterDescription: String {
        switch self {
        case .power(let onOff): onOff.rawValue
        case .inputSwitchClass1(let inputSwitch): inputSwitch.description
        case .inputSwitchClass2(let inputSwitch): inputSwitch.description
        case .avMute(let muteState): muteState.description
        case .speakerVolume(let volumeAdjustment): volumeAdjustment.rawValue
        case .microphoneVolume(let volumeAdjustment): volumeAdjustment.rawValue
        case .freeze(let freeze): freeze.rawValue
        }
    }
}

extension PJLink.SetRequest: CustomStringConvertible {

    public var description: String {
        PJLink.identifier + self.class.description + self.command.rawValue + PJLink.separatorRequest + parameterDescription
    }
}
