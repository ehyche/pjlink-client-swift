//
//  String+Extensions.swift
//  pjlink-client-swift
//
//  Created by Eric Hyche on 12/31/25.
//

import Foundation

extension String {

    var crTerminated: String {
        if hasSuffix("\r") {
            return self
        } else {
            return self + "\r"
        }
    }

    var crTerminatedData: Data {
        Data(crTerminated.utf8)
    }
}
