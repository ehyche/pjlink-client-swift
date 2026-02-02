//
//  PJLink+Notification.swift
//  pjlink-client-swift
//
//  Created by Eric Hyche on 2/2/26.
//

extension PJLink {

    public enum Notification: Equatable, Sendable {
        case linkup(MacAddress)
        case errorStatus(ErrorStatus)
        case power(OnOff)
        case input(InputSwitchClass2)
    }
}
