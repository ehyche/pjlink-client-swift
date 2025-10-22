//
//  PJLink+PowerStatus.swift
//  pjlink-client-swift
//
//  Created by Eric Hyche on 10/20/25.
//

extension PJLink {

    public enum PowerStatus: String {
        case standby = "0"
        case lampOn = "1"
        case cooling = "2"
        case warmUp = "3"
    }
}
