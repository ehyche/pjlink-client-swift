//
//  PJLink+MuteState.swift
//  pjlink-client-swift
//
//  Created by Eric Hyche on 10/20/25.
//

extension PJLink {

    public struct MuteState: Equatable, Sendable {
        var mute: Mute
        var state: OnOff
    }
}

extension PJLink.MuteState: LosslessStringConvertibleThrowing {

    public init(_ description: String) throws {
        var mutableDesc = description
        let muteRawValue = String(mutableDesc.prefix(1))
        guard let mute = PJLink.Mute(rawValue: muteRawValue) else {
            throw PJLink.Error.invalidMute(muteRawValue)
        }
        self.mute = mute
        mutableDesc.removeFirst(1)

        let onOffRawValue = String(mutableDesc.prefix(1))
        guard let onOff = PJLink.OnOff(rawValue: onOffRawValue) else {
            throw PJLink.Error.invalidOnOff(onOffRawValue)
        }
        self.state = onOff
        mutableDesc.removeFirst(1)
    }

    public var description: String {
        mute.rawValue + state.rawValue
    }
}

extension PJLink.MuteState: CaseIterable {
    public static var allCases: [PJLink.MuteState] {
        PJLink.Mute.allCases.flatMap { mute in
            PJLink.OnOff.allCases.map { onOff in
                PJLink.MuteState(mute: mute, state: onOff)
            }
        }
    }
}
