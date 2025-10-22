//
//  PJLink+InputSwitch.swift
//  pjlink-client-swift
//
//  Created by Eric Hyche on 10/20/25.
//

extension PJLink {
    public struct InputSwitch: Equatable {
        var input: Input
        var channel: InputChannel
    }

    public struct InputSwitches: Equatable {
        var switches: [InputSwitch]
    }
}

extension PJLink.InputSwitch: LosslessStringConvertibleThrowing {

    public init(_ description: String) throws {
        var mutableDesc = description
        let inputRawValue = String(mutableDesc.prefix(1))
        guard let input = PJLink.Input(rawValue: inputRawValue) else {
            throw PJLink.Error.invalidInput(inputRawValue)
        }
        self.input = input
        mutableDesc.removeFirst(1)

        let channelRawValue = String(mutableDesc.prefix(1))
        guard let channel = PJLink.InputChannel(rawValue: channelRawValue) else {
            throw PJLink.Error.invalidInputChannel(channelRawValue)
        }
        self.channel = channel
        mutableDesc.removeFirst(1)
    }

    public var description: String { input.rawValue + channel.rawValue }
}

extension PJLink.InputSwitches: LosslessStringConvertibleThrowing {

    public init(_ description: String) throws {
        switches = try description
            .split(separator: " ")
            .map(String.init)
            .map { try PJLink.InputSwitch($0) }
    }

    public var description: String {
        switches
            .map(\.description)
            .joined(separator: " ")
    }
}
