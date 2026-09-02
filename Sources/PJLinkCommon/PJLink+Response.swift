//
//  PJLink+Response.swift
//  pjlink-client-swift
//
//  Created by Eric Hyche on 9/2/26.
//

extension PJLink {

    public enum Response: Equatable, Sendable {
        case auth(AuthResponse)
        case get(GetResponse)
        case status(StatusResponse)
    }
}

extension PJLink.Response: LosslessStringConvertibleThrowing {

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

    public var description: String {
        switch self {
        case .auth(let authResponse): authResponse.description
        case .get(let getSuccess): getSuccess.description
        case .status(let statusResponse): statusResponse.description
        }
    }
}

extension PJLink.Response {

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
