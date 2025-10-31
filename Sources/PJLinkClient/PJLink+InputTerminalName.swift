//
//  PJLink+InputTerminalName.swift
//  pjlink-client-swift
//
//  Created by Eric Hyche on 10/31/25.
//

extension PJLink {

    public struct InputTerminalName: Equatable, Sendable {
        public var value: String
    }
}

extension PJLink.InputTerminalName {

    public static let mock = Self(value: "Mock Input Terminal Name")
}
