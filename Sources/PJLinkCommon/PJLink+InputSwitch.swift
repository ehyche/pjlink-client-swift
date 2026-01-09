//
//  PJLink+InputSwitch.swift
//  pjlink-client-swift
//
//  Created by Eric Hyche on 10/20/25.
//

extension PJLink {
    public struct InputSwitchClass1: Equatable, Sendable, Codable {
        public var input: InputClass1
        public var channel: InputChannelClass1
    }

    public struct InputSwitchesClass1: Equatable, Sendable, Codable {
        public var switches: [InputSwitchClass1]
    }

    public struct InputSwitchClass2: Hashable, Sendable, Codable {
        public var input: InputClass2
        public var channel: InputChannelClass2
    }

    public struct InputSwitchesClass2: Equatable, Sendable, Codable {
        public var switches: [InputSwitchClass2]
    }

    /// Class-independent input information
    public struct Input: Equatable, Sendable {
        /// `InputClass2` is a superset of `InputClass1`, so we can use `InputClass2` for both classes
        public var input: InputClass2
        /// `InputChannelClass2` is a superset of `InputChannelClass1`, so we can use `InputChannelClass2` for both classes
        public var channel: InputChannelClass2
        /// `InputTerminalName` will only be available for Class2 devices
        public var name: InputTerminalName?
    }
}

extension PJLink.InputSwitchClass1: LosslessStringConvertibleThrowing {

    public init(_ description: String) throws {
        var mutableDesc = description
        let inputRawValue = String(mutableDesc.prefix(1))
        guard let input = PJLink.InputClass1(rawValue: inputRawValue) else {
            throw PJLink.Error.invalidClass1Input(inputRawValue)
        }
        self.input = input
        mutableDesc.removeFirst(1)

        let channelRawValue = String(mutableDesc.prefix(1))
        guard let channel = PJLink.InputChannelClass1(rawValue: channelRawValue) else {
            throw PJLink.Error.invalidClass1InputChannel(channelRawValue)
        }
        self.channel = channel
        mutableDesc.removeFirst(1)
    }

    public var description: String { input.rawValue + channel.rawValue }
}

extension PJLink.InputSwitchesClass1: LosslessStringConvertibleThrowing {

    public init(_ description: String) throws {
        switches = try description
            .split(separator: " ")
            .map(String.init)
            .map { try PJLink.InputSwitchClass1($0) }
    }

    public var description: String {
        switches
            .map(\.description)
            .joined(separator: " ")
    }
}

extension PJLink.InputSwitchClass2: LosslessStringConvertibleThrowing {

    public init(_ description: String) throws {
        var mutableDesc = description
        let inputRawValue = String(mutableDesc.prefix(1))
        guard let input = PJLink.InputClass2(rawValue: inputRawValue) else {
            throw PJLink.Error.invalidClass2Input(inputRawValue)
        }
        self.input = input
        mutableDesc.removeFirst(1)

        let channelRawValue = String(mutableDesc.prefix(1))
        guard let channel = PJLink.InputChannelClass2(rawValue: channelRawValue) else {
            throw PJLink.Error.invalidClass2InputChannel(channelRawValue)
        }
        self.channel = channel
        mutableDesc.removeFirst(1)
    }

    public var description: String { input.rawValue + channel.rawValue }
}

extension PJLink.InputSwitchesClass2: LosslessStringConvertibleThrowing {

    public init(_ description: String) throws {
        switches = try description
            .split(separator: " ")
            .map(String.init)
            .map { try PJLink.InputSwitchClass2($0) }
    }

    public var description: String {
        switches
            .map(\.description)
            .joined(separator: " ")
    }
}

extension PJLink.InputSwitchClass1: CaseIterable {

    public static var allCases: [PJLink.InputSwitchClass1] {
        PJLink.InputClass1.allCases.flatMap { input in
            PJLink.InputChannelClass1.allCases.map { channel in
                PJLink.InputSwitchClass1(input: input, channel: channel)
            }
        }
    }
}

extension PJLink.InputSwitchClass2: CaseIterable {

    public static var allCases: [PJLink.InputSwitchClass2] {
        PJLink.InputClass2.allCases.flatMap { input in
            PJLink.InputChannelClass2.allCases.map { channel in
                PJLink.InputSwitchClass2(input: input, channel: channel)
            }
        }
    }
}

extension PJLink.InputSwitchClass1 {

    public var asInput: PJLink.Input {
        .init(input: input.asClass2, channel: channel.asClass2, name: nil)
    }
}

extension PJLink.InputSwitchesClass1 {

    public static let mock = Self(switches: PJLink.InputSwitchClass1.allCases)
}

extension PJLink.InputSwitchClass2 {

    public func toInput(withName name: PJLink.InputTerminalName?) -> PJLink.Input {
        .init(input: input, channel: channel, name: name)
    }
}

extension PJLink.InputSwitchesClass2 {

    public static let mock = Self(switches: PJLink.InputSwitchClass2.allCases)
}
