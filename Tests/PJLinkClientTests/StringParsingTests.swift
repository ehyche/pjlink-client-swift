//
//  StringParsingTests.swift
//  pjlink-client-swift
//
//  Created by Eric Hyche on 10/22/25.
//

@testable import PJLinkClient
import Testing

@Suite
struct StringParsingTests {

    @Test
    func getRequests() throws {
        let testCases: [(String, PJLink.Message)] = [
            ("%1POWR ?", .init(class: .one, command: .power, body: .request(.get(.power)))),
            ("%1INPT ?", .init(class: .one, command: .inputSwitch, body: .request(.get(.inputSwitch)))),
            ("%2INPT ?", .init(class: .two, command: .inputSwitch, body: .request(.get(.inputSwitch)))),
            ("%1AVMT ?", .init(class: .one, command: .avMute, body: .request(.get(.avMute)))),
            ("%1ERST ?", .init(class: .one, command: .errorStatus, body: .request(.get(.errorStatus)))),
            ("%1LAMP ?", .init(class: .one, command: .lamp, body: .request(.get(.lamp)))),
            ("%1INST ?", .init(class: .one, command: .inputList, body: .request(.get(.inputList)))),
            ("%2INST ?", .init(class: .two, command: .inputList, body: .request(.get(.inputList)))),
            ("%1NAME ?", .init(class: .one, command: .projectorName, body: .request(.get(.projectorName)))),
            ("%1INF1 ?", .init(class: .one, command: .manufacturerName, body: .request(.get(.manufacturerName)))),
            ("%1INF2 ?", .init(class: .one, command: .productName, body: .request(.get(.productName)))),
            ("%1INFO ?", .init(class: .one, command: .otherInformation, body: .request(.get(.otherInformation)))),
            ("%1CLSS ?", .init(class: .one, command: .projectorClass, body: .request(.get(.projectorClass)))),
            ("%2SNUM ?", .init(class: .two, command: .serialNumber, body: .request(.get(.serialNumber)))),
            ("%2SVER ?", .init(class: .two, command: .softwareVersion, body: .request(.get(.softwareVersion)))),
            ("%2INNM ?11", .init(class: .two, command: .inputTerminalName, body: .request(.get(.inputTerminalName(.init(input: .rgb, channel: .one)))))),
            ("%2IRES ?", .init(class: .two, command: .inputResolution, body: .request(.get(.inputResolution)))),
            ("%2RRES ?", .init(class: .two, command: .recommendedResolution, body: .request(.get(.recommendedResolution)))),
            ("%2FILT ?", .init(class: .two, command: .filterUsageTime, body: .request(.get(.filterUsageTime)))),
            ("%2RLMP ?", .init(class: .two, command: .lampReplacementModelNumber, body: .request(.get(.lampReplacementModelNumber)))),
            ("%2RFIL ?", .init(class: .two, command: .filterReplacementModelNumber, body: .request(.get(.filterReplacementModelNumber)))),
            ("%2FREZ ?", .init(class: .two, command: .freeze, body: .request(.get(.freeze)))),
        ]
        for testCase in testCases {
            let message = try PJLink.Message(testCase.0)
            #expect(message == testCase.1)
        }
    }
}
