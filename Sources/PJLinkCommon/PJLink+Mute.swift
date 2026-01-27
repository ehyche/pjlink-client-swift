//
//  PJLink+Mute.swift
//  pjlink-client-swift
//
//  Created by Eric Hyche on 10/20/25.
//

extension PJLink {
    public enum Mute: String, CaseIterable, Equatable, Sendable, Codable {
        case video = "1"
        case audio = "2"
        case audioVideo = "3"
    }
}

extension PJLink.Mute {

    public var displayName: String {
        switch self {
        case .video: "Video"
        case .audio: "Audio"
        case .audioVideo: "Audio and Video"
        }
    }
}
