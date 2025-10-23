//
//  File.swift
//  pjlink-client-swift
//
//  Created by Eric Hyche on 10/23/25.
//

extension PJLink {

    public enum ErrorResponse: String, CaseIterable {
        case ok = "OK"
        case undefinedCommand = "ERR1"
        case outOfParameter = "ERR2"
        case unavailableTime = "ERR3"
        case projectorFailure = "ERR4"
    }
}
