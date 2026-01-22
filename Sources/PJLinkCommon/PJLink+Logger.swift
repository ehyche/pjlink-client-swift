//
//  PJLink+Logger.swift
//  pjlink-client-swift
//
//  Created by Eric Hyche on 1/22/26.
//
import os

extension PJLink {

    public enum Subsystem: String {
        case server = "PJLinkServer"
        case client = "PJLinkClient"
    }

    public enum Category: String {
        case parsing = "Parsing"
        case network = "Network"
        case listener = "Listener"
        case connection = "Connection"
    }
}

extension Logger {

    public init(sub: PJLink.Subsystem = .server, cat: PJLink.Category) {
        self.init(subsystem: sub.rawValue, category: cat.rawValue)
    }
}
