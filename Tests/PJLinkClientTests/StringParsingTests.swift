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
    struct TestCase {
        var input: String
        var expected: PJLink.Message

        init(_ input: String, _ expected: PJLink.Message) {
            self.input = input
            self.expected = expected
        }
    }

    @Test
    func getRequestsHappyPath() throws {
        let testCases: [TestCase] = [
            .init("%1POWR ?", .init(class: .one, command: .power, body: .request(.get(.power)))),
            .init("%1INPT ?", .init(class: .one, command: .inputSwitch, body: .request(.get(.inputSwitch)))),
            .init("%2INPT ?", .init(class: .two, command: .inputSwitch, body: .request(.get(.inputSwitch)))),
            .init("%1AVMT ?", .init(class: .one, command: .avMute, body: .request(.get(.avMute)))),
            .init("%1ERST ?", .init(class: .one, command: .errorStatus, body: .request(.get(.errorStatus)))),
            .init("%1LAMP ?", .init(class: .one, command: .lamp, body: .request(.get(.lamp)))),
            .init("%1INST ?", .init(class: .one, command: .inputList, body: .request(.get(.inputList)))),
            .init("%2INST ?", .init(class: .two, command: .inputList, body: .request(.get(.inputList)))),
            .init("%1NAME ?", .init(class: .one, command: .projectorName, body: .request(.get(.projectorName)))),
            .init("%1INF1 ?", .init(class: .one, command: .manufacturerName, body: .request(.get(.manufacturerName)))),
            .init("%1INF2 ?", .init(class: .one, command: .productName, body: .request(.get(.productName)))),
            .init("%1INFO ?", .init(class: .one, command: .otherInformation, body: .request(.get(.otherInformation)))),
            .init("%1CLSS ?", .init(class: .one, command: .projectorClass, body: .request(.get(.projectorClass)))),
            .init("%2SNUM ?", .init(class: .two, command: .serialNumber, body: .request(.get(.serialNumber)))),
            .init("%2SVER ?", .init(class: .two, command: .softwareVersion, body: .request(.get(.softwareVersion)))),
            .init("%2INNM ?11", .init(class: .two, command: .inputTerminalName, body: .request(.get(.inputTerminalName(.init(input: .rgb, channel: .one)))))),
            .init("%2IRES ?", .init(class: .two, command: .inputResolution, body: .request(.get(.inputResolution)))),
            .init("%2RRES ?", .init(class: .two, command: .recommendedResolution, body: .request(.get(.recommendedResolution)))),
            .init("%2FILT ?", .init(class: .two, command: .filterUsageTime, body: .request(.get(.filterUsageTime)))),
            .init("%2RLMP ?", .init(class: .two, command: .lampReplacementModelNumber, body: .request(.get(.lampReplacementModelNumber)))),
            .init("%2RFIL ?", .init(class: .two, command: .filterReplacementModelNumber, body: .request(.get(.filterReplacementModelNumber)))),
            .init("%2FREZ ?", .init(class: .two, command: .freeze, body: .request(.get(.freeze)))),
        ]
        try run(testCases)
    }

    @Test
    func setRequestsHappyPath() throws {
        let testCases: [TestCase] = [
            .init("%1POWR 1", .init(class: .one, command: .power, body: .request(.set(.power(.on))))),
            .init("%1POWR 0", .init(class: .one, command: .power, body: .request(.set(.power(.off))))),
            .init("%1INPT 11", .init(class: .one, command: .inputSwitch, body: .request(.set(.inputSwitchClass1(.init(input: .rgb, channel: .one)))))),
            .init("%1INPT 12", .init(class: .one, command: .inputSwitch, body: .request(.set(.inputSwitchClass1(.init(input: .rgb, channel: .two)))))),
            .init("%1INPT 13", .init(class: .one, command: .inputSwitch, body: .request(.set(.inputSwitchClass1(.init(input: .rgb, channel: .three)))))),
            .init("%1INPT 14", .init(class: .one, command: .inputSwitch, body: .request(.set(.inputSwitchClass1(.init(input: .rgb, channel: .four)))))),
            .init("%1INPT 15", .init(class: .one, command: .inputSwitch, body: .request(.set(.inputSwitchClass1(.init(input: .rgb, channel: .five)))))),
            .init("%1INPT 16", .init(class: .one, command: .inputSwitch, body: .request(.set(.inputSwitchClass1(.init(input: .rgb, channel: .six)))))),
            .init("%1INPT 17", .init(class: .one, command: .inputSwitch, body: .request(.set(.inputSwitchClass1(.init(input: .rgb, channel: .seven)))))),
            .init("%1INPT 18", .init(class: .one, command: .inputSwitch, body: .request(.set(.inputSwitchClass1(.init(input: .rgb, channel: .eight)))))),
            .init("%1INPT 19", .init(class: .one, command: .inputSwitch, body: .request(.set(.inputSwitchClass1(.init(input: .rgb, channel: .nine)))))),
            .init("%1INPT 21", .init(class: .one, command: .inputSwitch, body: .request(.set(.inputSwitchClass1(.init(input: .video, channel: .one)))))),
            .init("%1INPT 22", .init(class: .one, command: .inputSwitch, body: .request(.set(.inputSwitchClass1(.init(input: .video, channel: .two)))))),
            .init("%1INPT 23", .init(class: .one, command: .inputSwitch, body: .request(.set(.inputSwitchClass1(.init(input: .video, channel: .three)))))),
            .init("%1INPT 24", .init(class: .one, command: .inputSwitch, body: .request(.set(.inputSwitchClass1(.init(input: .video, channel: .four)))))),
            .init("%1INPT 25", .init(class: .one, command: .inputSwitch, body: .request(.set(.inputSwitchClass1(.init(input: .video, channel: .five)))))),
            .init("%1INPT 26", .init(class: .one, command: .inputSwitch, body: .request(.set(.inputSwitchClass1(.init(input: .video, channel: .six)))))),
            .init("%1INPT 27", .init(class: .one, command: .inputSwitch, body: .request(.set(.inputSwitchClass1(.init(input: .video, channel: .seven)))))),
            .init("%1INPT 28", .init(class: .one, command: .inputSwitch, body: .request(.set(.inputSwitchClass1(.init(input: .video, channel: .eight)))))),
            .init("%1INPT 29", .init(class: .one, command: .inputSwitch, body: .request(.set(.inputSwitchClass1(.init(input: .video, channel: .nine)))))),
            .init("%1INPT 31", .init(class: .one, command: .inputSwitch, body: .request(.set(.inputSwitchClass1(.init(input: .digital, channel: .one)))))),
            .init("%1INPT 32", .init(class: .one, command: .inputSwitch, body: .request(.set(.inputSwitchClass1(.init(input: .digital, channel: .two)))))),
            .init("%1INPT 33", .init(class: .one, command: .inputSwitch, body: .request(.set(.inputSwitchClass1(.init(input: .digital, channel: .three)))))),
            .init("%1INPT 34", .init(class: .one, command: .inputSwitch, body: .request(.set(.inputSwitchClass1(.init(input: .digital, channel: .four)))))),
            .init("%1INPT 35", .init(class: .one, command: .inputSwitch, body: .request(.set(.inputSwitchClass1(.init(input: .digital, channel: .five)))))),
            .init("%1INPT 36", .init(class: .one, command: .inputSwitch, body: .request(.set(.inputSwitchClass1(.init(input: .digital, channel: .six)))))),
            .init("%1INPT 37", .init(class: .one, command: .inputSwitch, body: .request(.set(.inputSwitchClass1(.init(input: .digital, channel: .seven)))))),
            .init("%1INPT 38", .init(class: .one, command: .inputSwitch, body: .request(.set(.inputSwitchClass1(.init(input: .digital, channel: .eight)))))),
            .init("%1INPT 39", .init(class: .one, command: .inputSwitch, body: .request(.set(.inputSwitchClass1(.init(input: .digital, channel: .nine)))))),
            .init("%1INPT 41", .init(class: .one, command: .inputSwitch, body: .request(.set(.inputSwitchClass1(.init(input: .storage, channel: .one)))))),
            .init("%1INPT 42", .init(class: .one, command: .inputSwitch, body: .request(.set(.inputSwitchClass1(.init(input: .storage, channel: .two)))))),
            .init("%1INPT 43", .init(class: .one, command: .inputSwitch, body: .request(.set(.inputSwitchClass1(.init(input: .storage, channel: .three)))))),
            .init("%1INPT 44", .init(class: .one, command: .inputSwitch, body: .request(.set(.inputSwitchClass1(.init(input: .storage, channel: .four)))))),
            .init("%1INPT 45", .init(class: .one, command: .inputSwitch, body: .request(.set(.inputSwitchClass1(.init(input: .storage, channel: .five)))))),
            .init("%1INPT 46", .init(class: .one, command: .inputSwitch, body: .request(.set(.inputSwitchClass1(.init(input: .storage, channel: .six)))))),
            .init("%1INPT 47", .init(class: .one, command: .inputSwitch, body: .request(.set(.inputSwitchClass1(.init(input: .storage, channel: .seven)))))),
            .init("%1INPT 48", .init(class: .one, command: .inputSwitch, body: .request(.set(.inputSwitchClass1(.init(input: .storage, channel: .eight)))))),
            .init("%1INPT 49", .init(class: .one, command: .inputSwitch, body: .request(.set(.inputSwitchClass1(.init(input: .storage, channel: .nine)))))),
            .init("%1INPT 51", .init(class: .one, command: .inputSwitch, body: .request(.set(.inputSwitchClass1(.init(input: .network, channel: .one)))))),
            .init("%1INPT 52", .init(class: .one, command: .inputSwitch, body: .request(.set(.inputSwitchClass1(.init(input: .network, channel: .two)))))),
            .init("%1INPT 53", .init(class: .one, command: .inputSwitch, body: .request(.set(.inputSwitchClass1(.init(input: .network, channel: .three)))))),
            .init("%1INPT 54", .init(class: .one, command: .inputSwitch, body: .request(.set(.inputSwitchClass1(.init(input: .network, channel: .four)))))),
            .init("%1INPT 55", .init(class: .one, command: .inputSwitch, body: .request(.set(.inputSwitchClass1(.init(input: .network, channel: .five)))))),
            .init("%1INPT 56", .init(class: .one, command: .inputSwitch, body: .request(.set(.inputSwitchClass1(.init(input: .network, channel: .six)))))),
            .init("%1INPT 57", .init(class: .one, command: .inputSwitch, body: .request(.set(.inputSwitchClass1(.init(input: .network, channel: .seven)))))),
            .init("%1INPT 58", .init(class: .one, command: .inputSwitch, body: .request(.set(.inputSwitchClass1(.init(input: .network, channel: .eight)))))),
            .init("%1INPT 59", .init(class: .one, command: .inputSwitch, body: .request(.set(.inputSwitchClass1(.init(input: .network, channel: .nine)))))),
            .init("%1AVMT 11", .init(class: .one, command: .avMute, body: .request(.set(.avMute(.init(mute: .video, state: .on)))))),
            .init("%1AVMT 10", .init(class: .one, command: .avMute, body: .request(.set(.avMute(.init(mute: .video, state: .off)))))),
            .init("%1AVMT 21", .init(class: .one, command: .avMute, body: .request(.set(.avMute(.init(mute: .audio, state: .on)))))),
            .init("%1AVMT 20", .init(class: .one, command: .avMute, body: .request(.set(.avMute(.init(mute: .audio, state: .off)))))),
            .init("%1AVMT 31", .init(class: .one, command: .avMute, body: .request(.set(.avMute(.init(mute: .audioVideo, state: .on)))))),
            .init("%1AVMT 30", .init(class: .one, command: .avMute, body: .request(.set(.avMute(.init(mute: .audioVideo, state: .off)))))),
            .init("%2SVOL 0", .init(class: .two, command: .speakerVolume, body: .request(.set(.speakerVolume(.decrease))))),
            .init("%2SVOL 1", .init(class: .two, command: .speakerVolume, body: .request(.set(.speakerVolume(.increase))))),
            .init("%2MVOL 0", .init(class: .two, command: .microphoneVolume, body: .request(.set(.microphoneVolume(.decrease))))),
            .init("%2MVOL 1", .init(class: .two, command: .microphoneVolume, body: .request(.set(.microphoneVolume(.increase))))),
            .init("%2FREZ 0", .init(class: .two, command: .freeze, body: .request(.set(.freeze(.stop))))),
            .init("%2FREZ 1", .init(class: .two, command: .freeze, body: .request(.set(.freeze(.start))))),
        ]
        try run(testCases)
    }

    private func run(_ testCases: [TestCase]) throws {
        for testCase in testCases {
            let actual = try PJLink.Message(testCase.input)
            #expect(actual == testCase.expected)
        }
    }
}
