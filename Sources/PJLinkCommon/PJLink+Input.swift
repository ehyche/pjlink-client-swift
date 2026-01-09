//
//  PJLink+Input.swift
//  pjlink-client-swift
//
//  Created by Eric Hyche on 10/20/25.
//

extension PJLink {

    public enum InputClass1: String, CaseIterable, Sendable {
        case rgb = "1"
        case video = "2"
        case digital = "3"
        case storage = "4"
        case network = "5"
    }

    public enum InputClass2: String, CaseIterable, Sendable {
        case rgb = "1"
        case video = "2"
        case digital = "3"
        case storage = "4"
        case network = "5"
        case `internal` = "6"
    }
}

extension PJLink.InputClass1 {

    public var asClass2: PJLink.InputClass2 {
        switch self {
        case .rgb: .rgb
        case .video: .video
        case .digital: .digital
        case .storage: .storage
        case .network: .network
        }
    }
}
