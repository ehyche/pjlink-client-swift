//
//  PJLink+Resolution.swift
//  pjlink-client-swift
//
//  Created by Eric Hyche on 10/20/25.
//

extension PJLink {

    public enum InputResolution {
        case ok(Resolution)
        case noSignal
        case unknownSignal
    }

    public struct Resolution {
        var horizontal: Int
        var vertical: Int
    }
}

extension PJLink.InputResolution: LosslessStringConvertibleThrowing {

    public init(_ description: String) throws {
        if description == Self.noSignalRawValue {
            self = .noSignal
        } else if description == Self.unknownSignalRawValue {
            self = .unknownSignal
        } else {
            self = .ok(try .init(description))
        }
    }

    public var description: String {
        switch self {
        case .ok(let resolution): resolution.description
        case .noSignal: Self.noSignalRawValue
        case .unknownSignal: Self.unknownSignalRawValue
        }
    }

    private static let noSignalRawValue = "-"
    private static let unknownSignalRawValue = "*"
}

extension PJLink.Resolution: LosslessStringConvertibleThrowing {

    public init(_ description: String) throws {
        let components = description
            .split(separator: "x")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .compactMap(Int.init)
        guard components.count == 2 else {
            throw PJLink.Error.invalidResolution(description)
        }
        horizontal = components[0]
        vertical = components[1]
    }

    public var description: String {
        "\(horizontal)x\(vertical)"
    }
}
