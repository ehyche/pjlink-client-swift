//
//  PJLink+Input.swift
//  pjlink-client-swift
//
//  Created by Eric Hyche on 10/20/25.
//

extension PJLink {

    public enum InputClass1: String, CaseIterable {
        case rgb = "1"
        case video = "2"
        case digital = "3"
        case storage = "4"
        case network = "5"
    }

    public enum InputClass2: String, CaseIterable {
        case rgb = "1"
        case video = "2"
        case digital = "3"
        case storage = "4"
        case network = "5"
        case `internal` = "6"
    }
}
