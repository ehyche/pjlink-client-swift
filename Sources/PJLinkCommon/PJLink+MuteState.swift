//
//  PJLink+MuteState.swift
//  pjlink-client-swift
//
//  Created by Eric Hyche on 10/20/25.
//

extension PJLink {

    public struct MuteState: Equatable, Sendable, Codable {
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

extension PJLink.MuteState {

    public var displayName: String {
        mute.displayName + " " + state.displayName
    }

    public var isAudioMuted: Bool {
        get {
            switch (mute, state) {
            case (_, .off): false
            case (.audio, .on): true
            case (.audioVideo, .on): true
            case (.video, .on): false
            }
        }
        set {
            switch (mute, state, newValue) {
            case (_, .off, false):
                break
            case (.audio, .on, true):
                break
            case (.audio, .on, false):
                state = .off
            case (.audio, .off, true):
                state = .on
            case (.video, .on, true):
                mute = .audioVideo
            case (.video, .on, false):
                break
            case (.video, .off, true):
                mute = .audio
                state = .on
            case (.audioVideo, .on, true):
                break
            case (.audioVideo, .on, false):
                mute = .video
            case (.audioVideo, .off, true):
                mute = .audio
                state = .on
            }
        }
    }

    public var isVideoMuted: Bool {
        get {
            switch (mute, state) {
            case (_, .off): false
            case (.audio, .on): false
            case (.audioVideo, .on): true
            case (.video, .on): true
            }
        }
        set {
            switch (mute, state, newValue) {
            case (_, .off, false):
                break
            case (.audio, .on, true):
                mute = .audioVideo
            case (.audio, .on, false):
                break
            case (.audio, .off, true):
                mute = .video
                state = .on
            case (.video, .on, true):
                break
            case (.video, .on, false):
                state = .off
            case (.video, .off, true):
                state = .on
            case (.audioVideo, .on, true):
                break
            case (.audioVideo, .on, false):
                mute = .audio
            case (.audioVideo, .off, true):
                mute = .video
                state = .on
            }
        }
    }

    public static let mock: Self = .init(mute: .audioVideo, state: .off)
}
