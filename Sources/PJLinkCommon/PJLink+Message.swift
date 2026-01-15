//
//  PJLink+Message.swift
//  pjlink-client-swift
//
//  Created by Eric Hyche on 10/17/25.
//

import Foundation

extension PJLink {
    public enum Message: Equatable {
        case request(Request)
        case response(Response)

        public enum Request: Equatable {
            case get(GetRequest)
            case set(SetRequest)
        }

        public enum Response: Equatable {
            case get(GetResponse)
            case set(SetResponse)
        }
    }
}

extension PJLink.Message {
    
    /// Initializer
    /// - Parameters:
    ///   - description: The string to parse
    ///   - isSetResponseHint: This optional boolean is a hint which indicates this is a response to a Set command.
    ///   Why is this needed? If the response is either "ERR1",  "ERR3" or "ERR4", then there is no
    ///   way to distinguish just from the parsed text if this is a response to a set command or a get command.
    ///   But in practice, we will know what we are expecting. So if we know we should be parsing the
    ///   response to a Set command, then we can provide this hint.
    public init(_ description: String, isSetResponseHint: Bool? = nil) throws {
        var mutableDesc = description
        let pjlinkId = String(mutableDesc.prefix(1))
        guard pjlinkId == PJLink.identifier else {
            throw PJLink.Error.invalidID(pjlinkId)
        }
        mutableDesc.removeFirst(1)

        let classRawValue = String(mutableDesc.prefix(1))
        guard let pjlinkClass = PJLink.Class(rawValue: classRawValue) else {
            throw PJLink.Error.invalidClass(classRawValue)
        }
        mutableDesc.removeFirst(1)

        let commandRawValue = mutableDesc.prefix(4).uppercased()
        guard let pjlinkCommand = PJLink.Command(rawValue: commandRawValue) else {
            throw PJLink.Error.invalidCommand(commandRawValue)
        }
        mutableDesc.removeFirst(4)

        let separator = String(mutableDesc.prefix(1))
        guard separator == PJLink.separatorRequest || separator == PJLink.separatorResponse else {
            throw PJLink.Error.invalidSeparator(separator)
        }
        mutableDesc.removeFirst(1)

        if separator == PJLink.separatorRequest {
            // Request
            if mutableDesc.prefix(1) == PJLink.prefixGet {
                // Get Request
                mutableDesc.removeFirst(1)
                self = .request(.get(try .init(pjlinkClass: pjlinkClass, command: pjlinkCommand, parameters: mutableDesc)))
            } else {
                // Set Request
                self = .request(.set(try .init(pjlinkClass: pjlinkClass, command: pjlinkCommand, parameters: mutableDesc)))
            }
        } else {
            // This is a response. Is a hint provided?
            if let isSetResponseHint {
                if isSetResponseHint {
                    self = .response(.set(.init(class: pjlinkClass, command: pjlinkCommand, code: try .init(mutableDesc))))
                } else {
                    self = .response(.get(try .init(pjlinkClass: pjlinkClass, command: pjlinkCommand, parameters: mutableDesc)))
                }
            } else {
                // We don't have a hint, so we have to try and infer
                // GetResponse vs SetResponse from the parameters.
                // In this case, we assume that a standard response code
                // (OK, ERR1, ERR2, ERR3, or ERR4) is a Set Response.
                self = .response(try .init(pjlinkClass: pjlinkClass, command: pjlinkCommand, parameters: mutableDesc))
            }
        }
    }

    public var description: String {
        PJLink.identifier + self.class.rawValue + command.rawValue + separator + parameterDescription
    }

    public var `class`: PJLink.Class {
        switch self {
        case .request(let request): request.class
        case .response(let response): response.class
        }
    }

    public var command: PJLink.Command {
        switch self {
        case .request(let request): request.command
        case .response(let response): response.command
        }
    }

    public var isRequest: Bool {
        switch self {
        case .request: true
        case .response: false
        }
    }

    public var isSetRequest: Bool {
        switch self {
        case .request(let request): request.isSet
        case .response: false
        }
    }

    public var isSetResponse: Bool {
        switch self {
        case .request: false
        case .response(let response): response.isSet
        }
    }

    public var isSuccessfulResponse: Bool {
        switch self {
        case .request: false
        case .response(let response): response.isSuccess
        }
    }

    public var separator: String {
        switch self {
        case .request: PJLink.separatorRequest
        case .response: PJLink.separatorResponse
        }
    }

    public var parameterDescription: String {
        switch self {
        case .request(let request):
            switch request {
            case .get(let getRequest): getRequest.description
            case .set(let setRequest): setRequest.description
            }
        case .response(let response):
            switch response {
            case .get(let getResponse): getResponse.description
            case .set(let setResponse): setResponse.code.description
            }
        }
    }
}

extension PJLink.Message.Request {

    public var isSet: Bool {
        switch self {
        case .get: false
        case .set: true
        }
    }

    public var `class`: PJLink.Class {
        switch self {
        case .get(let getRequest): getRequest.class
        case .set(let setRequest): setRequest.class
        }
    }

    public var command: PJLink.Command {
        switch self {
        case .get(let getRequest): getRequest.command
        case .set(let setRequest): setRequest.command
        }
    }

    public var parameterDescription: String {
        switch self {
        case .get(let getRequest): getRequest.description
        case .set(let setRequest): setRequest.description
        }
    }
}

extension PJLink.Message.Request: LosslessStringConvertibleThrowing {

    public init(_ description: String) throws {
        var mutableDesc = description
        let pjlinkId = String(mutableDesc.prefix(1))
        guard pjlinkId == PJLink.identifier else {
            throw PJLink.Error.invalidID(pjlinkId)
        }
        mutableDesc.removeFirst(1)

        let classRawValue = String(mutableDesc.prefix(1))
        guard let pjlinkClass = PJLink.Class(rawValue: classRawValue) else {
            throw PJLink.Error.invalidClass(classRawValue)
        }
        mutableDesc.removeFirst(1)

        let commandRawValue = mutableDesc.prefix(4).uppercased()
        guard let pjlinkCommand = PJLink.Command(rawValue: commandRawValue) else {
            throw PJLink.Error.invalidCommand(commandRawValue)
        }
        mutableDesc.removeFirst(4)

        let separator = String(mutableDesc.prefix(1))
        guard separator == PJLink.separatorRequest else {
            throw PJLink.Error.unexpectedSeparator(separator)
        }
        mutableDesc.removeFirst(1)

        if mutableDesc.prefix(1) == PJLink.prefixGet {
            // Get Request
            mutableDesc.removeFirst(1)
            self = .get(try .init(pjlinkClass: pjlinkClass, command: pjlinkCommand, parameters: mutableDesc))
        } else {
            // Set Request
            self = .set(try .init(pjlinkClass: pjlinkClass, command: pjlinkCommand, parameters: mutableDesc))
        }
    }

    public var description: String {
        PJLink.identifier + self.class.rawValue + self.command.rawValue + PJLink.separatorRequest + parameterDescription
    }
}

extension PJLink.Message.Response {

    public init(pjlinkClass: PJLink.Class, command: PJLink.Command, parameters: String) throws {
        if let setResponseCode = PJLink.SetResponseCode(rawValue: parameters) {
            self = .set(.init(class: pjlinkClass, command: command, code: setResponseCode))
        } else {
            self = .get(try .init(pjlinkClass: pjlinkClass, command: command, parameters: parameters))
        }
    }

    public var `class`: PJLink.Class {
        switch self {
        case .get(let getResponse): getResponse.class
        case .set(let setResponse): setResponse.class
        }
    }

    public var command: PJLink.Command {
        switch self {
        case .get(let getResponse): getResponse.command
        case .set(let setResponse): setResponse.command
        }
    }

    public var isSet: Bool {
        switch self {
        case .get: false
        case .set: true
        }
    }

    public var isSuccess: Bool {
        switch self {
        case .get(let getResponse): getResponse.isSuccess
        case .set(let setResponse): setResponse.isOK
        }
    }
}

