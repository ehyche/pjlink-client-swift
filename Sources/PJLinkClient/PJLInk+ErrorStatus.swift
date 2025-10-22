//
//  PJLink+ErrorStatus.swift
//  pjlink-client-swift
//
//  Created by Eric Hyche on 10/20/25.
//

extension PJLink {

    public struct ErrorStatus: Equatable {
        var fan: ComponentError
        var lamp: ComponentError
        var temperature: ComponentError
        var coverOpen: ComponentError
        var filter: ComponentError
        var other: ComponentError
    }

    public enum ComponentError: String {
        case none = "0"
        case warning = "1"
        case error = "2"
    }
}

extension PJLink.ErrorStatus: LosslessStringConvertibleThrowing {

    public init(_ description: String) throws {
        var mutableDesc = description
        var errors = [PJLink.ComponentError]()
        for _ in 0..<6 {
            let errorRawValue = String(mutableDesc.prefix(1))
            guard let componentError = PJLink.ComponentError(rawValue: errorRawValue) else {
                throw PJLink.Error.invalidErrorStatus(description)
            }
            errors.append(componentError)
            mutableDesc.removeFirst(1)
        }
        self.fan = errors[0]
        self.lamp = errors[1]
        self.temperature = errors[2]
        self.coverOpen = errors[3]
        self.filter = errors[4]
        self.other = errors[5]
    }

    public var description: String {
        fan.rawValue + lamp.rawValue + temperature.rawValue + coverOpen.rawValue + filter.rawValue + other.rawValue
    }
}
