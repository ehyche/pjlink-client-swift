//
//  PJLink+Message.swift
//  pjlink-client-swift
//
//  Created by Eric Hyche on 10/17/25.
//

import Foundation

extension PJLink {

    public enum Message: Equatable, Sendable {
        case request(Request)
        case response(Response)
    }

    public enum Request: Equatable, Sendable {
        case auth(AuthRequest)
        case get(GetRequest)
        case set(SetRequest)
    }

    public enum Response: Equatable, Sendable {
        case auth(AuthResponse)
        case get(GetResponse)
        case status(StatusResponse)
    }
}

extension PJLink.Message {
    
    /// Initializer
    /// - Parameters:
    ///   - description: The string to parse
    public init(_ description: String) throws {
        // Check for AuthRequest ("PJLINK 2")
        guard description != PJLink.AuthRequest.securityLevel.description else {
            self = .request(.auth(.securityLevel))
            return
        }
        // Check for AuthResponse
        guard !description.hasPrefix(PJLink.pjlink) else {
            self = .response(.auth(try .init(description)))
            return
        }
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
            // This is a response.
            self = .response(try .init(pjlinkClass: pjlinkClass, command: pjlinkCommand, parameters: mutableDesc))
        }
    }

    public var description: String {
        switch self {
        case .request(let request): request.description
        case .response(let response): response.description
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
        case .response(let response): response.isStatus
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
}

extension PJLink.Request {

    public var isSet: Bool {
        switch self {
        case .set: true
        default: false
        }
    }

    public var `class`: PJLink.Class? {
        switch self {
        case .auth: nil
        case .get(let getRequest): getRequest.class
        case .set(let setRequest): setRequest.class
        }
    }

    public var command: PJLink.Command? {
        switch self {
        case .auth: nil
        case .get(let getRequest): getRequest.command
        case .set(let setRequest): setRequest.command
        }
    }
}

extension PJLink.Request: LosslessStringConvertibleThrowing {

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
        switch self {
        case .auth(let authRequest): authRequest.description
        case .get(let getRequest): getRequest.description
        case .set(let setRequest): setRequest.description
        }
    }
}

extension PJLink.Response {

    /// Initializer
    /// - Parameters:
    ///   - description: The string to parse
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
        guard separator == PJLink.separatorResponse else {
            throw PJLink.Error.invalidSeparator(separator)
        }
        mutableDesc.removeFirst(1)

        try self.init(pjlinkClass: pjlinkClass, command: pjlinkCommand, parameters: mutableDesc)
    }

    public init(pjlinkClass: PJLink.Class, command: PJLink.Command, parameters: String) throws {
        // Are the parameters a status code?
        if let statusCode = PJLink.ResponseCode(rawValue: parameters) {
            self = .status(.init(pjlinkClass: pjlinkClass, command: command, code: statusCode))
        } else {
            self = .get(try .init(pjlinkClass: pjlinkClass, command: command, parameters: parameters))
        }
    }

    public var `class`: PJLink.Class? {
        switch self {
        case .auth: nil
        case .get(let getSuccess): getSuccess.class
        case .status(let statusResponse): statusResponse.class
        }
    }

    public var command: PJLink.Command? {
        switch self {
        case .auth: nil
        case .get(let getSuccess): getSuccess.command
        case .status(let statusResponse): statusResponse.command
        }
    }

    public var isStatus: Bool {
        switch self {
        case .status: true
        default: false
        }
    }

    public var isSuccess: Bool {
        switch self {
        case .auth: false
        case .get: true
        case .status(let statusResponse): statusResponse.isOK
        }
    }
}

extension PJLink.Response: CustomStringConvertible {

    public var description: String {
        switch self {
        case .auth(let authResponse): authResponse.description
        case .get(let getSuccess): getSuccess.description
        case .status(let statusResponse): statusResponse.description
        }
    }
}
