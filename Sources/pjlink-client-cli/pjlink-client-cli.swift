// The Swift Programming Language
// https://docs.swift.org/swift-book
// 
// Swift Argument Parser
// https://swiftpackageindex.com/apple/swift-argument-parser/documentation

import ArgumentParser
import Foundation
import Network

enum PowerStatus: Int {
    case standBy = 0
    case lampOn = 1
    case cooling = 2
    case warmUp = 3
}

enum GetPowerResponse {
    case ok(PowerStatus)
    case unavailableTime
    case projectorFailure
}

enum SetPowerRequest {
    case lampOn
    case standBy
}

enum SetPowerResponse {
    case ok
    case outOfParameter
    case unavailableTime
    case projectorFailure
}

enum PJLinkCommand: String {
    case power = "POWR"
    case inputSwitch = "INPT"
    case avMute = "AVMT"
    case errorStatus = "ERST"
    case lampHours = "LAMP"
    case inputList = "INST"
    case projectorName = "NAME"
    case manufacturerName = "INF1"
    case productName = "INF2"
    case otherInformation = "INFO"
    case projectorClass = "CLSS"
    case serialNumber = "SNUM"
    case softwareVersion = "SVER"
    case inputTerminalName = "INNM"
    case inputResolution = "IRES"
    case recommendedResolution = "RRES"
    case filterUsageTime = "FILT"
    case lampReplacementModelNumber = "RLMP"
    case filterReplacementModelNumber = "RFIL"
    case speakerVolume = "SVOL"
    case microphoneVolumer = "MVOL"
    case freeze = "FREZ"
}

enum PJLinkMessageType {
    case request
    case response

    static let separatorSpace: UInt8 = 32
    static let separatorEquals: UInt8 = 61
}

enum PJLinkMessage {
    case getPowerRequest
    case getPowerResponse(GetPowerResponse)
    case setPowerRequest(SetPowerRequest)
    case setPowerResponse(SetPowerResponse)

    static let idByte: UInt8 = 37 // '%'
    static let class1: UInt8 = 1
    static let class2: UInt8 = 2
    static let terminator: UInt8 = 13
}

enum PJLinkMessageError: Swift.Error {
    case invalidID(UInt8)
    case invalidClass(UInt8)
    case invalidCommand(String)
    case invalidSeparator(UInt8)
    case invalidPowerStatusValue(UInt8)
}

extension PowerStatus: Decodable {

    init(from decoder: any Decoder) throws {
        let container = try decoder.singleValueContainer()
        let byteValue = try container.decode(UInt8.self)
        guard let powerStatus = PowerStatus(rawValue: Int(byteValue)) else {
            throw PJLinkMessageError.invalidPowerStatusValue(byteValue)
        }
        self = powerStatus
    }
}

extension PowerStatus: Encodable {

    func encode(to encoder: any Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(UInt8(rawValue))
    }
}

extension PJLinkCommand: Decodable {

    init(from decoder: any Decoder) throws {
        var container = try decoder.unkeyedContainer()
        let byte0 = try container.decode(UInt8.self)
        let byte1 = try container.decode(UInt8.self)
        let byte2 = try container.decode(UInt8.self)
        let byte3 = try container.decode(UInt8.self)
        let str = "\(Character(UnicodeScalar(byte0)))\(Character(UnicodeScalar(byte1)))\(Character(UnicodeScalar(byte2)))\(Character(UnicodeScalar(byte3)))"
        guard let command = PJLinkCommand(rawValue: str.uppercased()) else {
            throw PJLinkMessageError.invalidCommand(str)
        }
        self = command
    }
}

extension PJLinkMessageType: Decodable {

    init(from decoder: any Decoder) throws {
        let container = try decoder.singleValueContainer()
        let byteValue = try container.decode(UInt8.self)
        switch byteValue {
        case PJLinkMessageType.separatorSpace:
            self = .request
        case PJLinkMessageType.separatorEquals:
            self = .response
        default:
            throw PJLinkMessageError.invalidSeparator(byteValue)
        }
    }
}

extension PJLinkMessage: Decodable {

    init(from decoder: any Decoder) throws {
        var container = try decoder.unkeyedContainer()
        let pjlinkID = try container.decode(UInt8.self)
        guard pjlinkID == PJLinkMessage.idByte else {
            throw PJLinkMessageError.invalidID(pjlinkID)
        }
        let pjlinkClass = try container.decode(UInt8.self)
        guard pjlinkClass == PJLinkMessage.class1 || pjlinkClass == PJLinkMessage.class2 else {
            throw PJLinkMessageError.invalidClass(pjlinkClass)
        }
        let command = try container.decode(PJLinkCommand.self)
        let messageType = try container.decode(PJLinkMessageType.self)
        var byteValue = try container.decode(UInt8.self)
        var parameter = ""
        while byteValue != PJLinkMessage.terminator {
            parameter += String(UnicodeScalar(byteValue))
            byteValue = try container.decode(UInt8.self)
        }
        self = .getPowerRequest
    }
}

@main
struct pjlink_client: ParsableCommand {
    mutating func run() async throws {
        let connection = NetworkConnection(to: .hostPort(host: "192.168.64.2", port: 4352)) {
            TCP {
                IP()
            }
        }

        let expectedResponse = Data("PJLINK 0\n".utf8)
        let connectionResponse = try await connection.receive(exactly: 9).content

        guard expectedResponse == connectionResponse else {
            print("Did not receive expected connection response.")
            return
        }
        print("Received non-authenticated connection response.")

        let powerQuery = Data("%1POWR ?\n".utf8)
        try await connection.send(powerQuery)

        let powerQueryResponse = try await connection.receive(atLeast: 9, atMost: 10).content

        guard let powerQueryResponseString = String(data: powerQueryResponse, encoding: .utf8) else {
            print("Received power query response could not be converted to UTF8 string.")
            return
        }
        print("Received \"\(powerQueryResponseString)\"")
    }
}
