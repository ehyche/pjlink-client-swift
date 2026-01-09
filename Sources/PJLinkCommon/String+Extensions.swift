//
//  String+Extensions.swift
//  pjlink-client-swift
//
//  Created by Eric Hyche on 12/31/25.
//

import Foundation

extension String {

    public var crTerminated: String {
        if hasSuffix("\r") {
            return self
        } else {
            return self + "\r"
        }
    }

    public var crTerminatedData: Data {
        Data(crTerminated.utf8)
    }
}
