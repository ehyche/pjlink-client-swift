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
    func getRequestsHappyPath() throws {
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

    @Test
    func setRequestsHappyPath() throws {
        let testCases: [(String, PJLink.Message)] = [
            ("%1POWR 1", .init(class: .one, command: .power, body: .request(.set(.power(.on))))),
            ("%1POWR 0", .init(class: .one, command: .power, body: .request(.set(.power(.off))))),
            ("%1INPT 11", .init(class: .one, command: .inputSwitch, body: .request(.set(.inputSwitchClass1(.init(input: .rgb, channel: .one)))))),
            ("%1INPT 12", .init(class: .one, command: .inputSwitch, body: .request(.set(.inputSwitchClass1(.init(input: .rgb, channel: .two)))))),
            ("%1INPT 13", .init(class: .one, command: .inputSwitch, body: .request(.set(.inputSwitchClass1(.init(input: .rgb, channel: .three)))))),
            ("%1INPT 14", .init(class: .one, command: .inputSwitch, body: .request(.set(.inputSwitchClass1(.init(input: .rgb, channel: .four)))))),
            ("%1INPT 15", .init(class: .one, command: .inputSwitch, body: .request(.set(.inputSwitchClass1(.init(input: .rgb, channel: .five)))))),
            ("%1INPT 16", .init(class: .one, command: .inputSwitch, body: .request(.set(.inputSwitchClass1(.init(input: .rgb, channel: .six)))))),
            ("%1INPT 17", .init(class: .one, command: .inputSwitch, body: .request(.set(.inputSwitchClass1(.init(input: .rgb, channel: .seven)))))),
            ("%1INPT 18", .init(class: .one, command: .inputSwitch, body: .request(.set(.inputSwitchClass1(.init(input: .rgb, channel: .eight)))))),
            ("%1INPT 19", .init(class: .one, command: .inputSwitch, body: .request(.set(.inputSwitchClass1(.init(input: .rgb, channel: .nine)))))),
            ("%1INPT 21", .init(class: .one, command: .inputSwitch, body: .request(.set(.inputSwitchClass1(.init(input: .video, channel: .one)))))),
            ("%1INPT 22", .init(class: .one, command: .inputSwitch, body: .request(.set(.inputSwitchClass1(.init(input: .video, channel: .two)))))),
            ("%1INPT 23", .init(class: .one, command: .inputSwitch, body: .request(.set(.inputSwitchClass1(.init(input: .video, channel: .three)))))),
            ("%1INPT 24", .init(class: .one, command: .inputSwitch, body: .request(.set(.inputSwitchClass1(.init(input: .video, channel: .four)))))),
            ("%1INPT 25", .init(class: .one, command: .inputSwitch, body: .request(.set(.inputSwitchClass1(.init(input: .video, channel: .five)))))),
            ("%1INPT 26", .init(class: .one, command: .inputSwitch, body: .request(.set(.inputSwitchClass1(.init(input: .video, channel: .six)))))),
            ("%1INPT 27", .init(class: .one, command: .inputSwitch, body: .request(.set(.inputSwitchClass1(.init(input: .video, channel: .seven)))))),
            ("%1INPT 28", .init(class: .one, command: .inputSwitch, body: .request(.set(.inputSwitchClass1(.init(input: .video, channel: .eight)))))),
            ("%1INPT 29", .init(class: .one, command: .inputSwitch, body: .request(.set(.inputSwitchClass1(.init(input: .video, channel: .nine)))))),
            ("%1INPT 31", .init(class: .one, command: .inputSwitch, body: .request(.set(.inputSwitchClass1(.init(input: .digital, channel: .one)))))),
            ("%1INPT 32", .init(class: .one, command: .inputSwitch, body: .request(.set(.inputSwitchClass1(.init(input: .digital, channel: .two)))))),
            ("%1INPT 33", .init(class: .one, command: .inputSwitch, body: .request(.set(.inputSwitchClass1(.init(input: .digital, channel: .three)))))),
            ("%1INPT 34", .init(class: .one, command: .inputSwitch, body: .request(.set(.inputSwitchClass1(.init(input: .digital, channel: .four)))))),
            ("%1INPT 35", .init(class: .one, command: .inputSwitch, body: .request(.set(.inputSwitchClass1(.init(input: .digital, channel: .five)))))),
            ("%1INPT 36", .init(class: .one, command: .inputSwitch, body: .request(.set(.inputSwitchClass1(.init(input: .digital, channel: .six)))))),
            ("%1INPT 37", .init(class: .one, command: .inputSwitch, body: .request(.set(.inputSwitchClass1(.init(input: .digital, channel: .seven)))))),
            ("%1INPT 38", .init(class: .one, command: .inputSwitch, body: .request(.set(.inputSwitchClass1(.init(input: .digital, channel: .eight)))))),
            ("%1INPT 39", .init(class: .one, command: .inputSwitch, body: .request(.set(.inputSwitchClass1(.init(input: .digital, channel: .nine)))))),
            ("%1INPT 41", .init(class: .one, command: .inputSwitch, body: .request(.set(.inputSwitchClass1(.init(input: .storage, channel: .one)))))),
            ("%1INPT 42", .init(class: .one, command: .inputSwitch, body: .request(.set(.inputSwitchClass1(.init(input: .storage, channel: .two)))))),
            ("%1INPT 43", .init(class: .one, command: .inputSwitch, body: .request(.set(.inputSwitchClass1(.init(input: .storage, channel: .three)))))),
            ("%1INPT 44", .init(class: .one, command: .inputSwitch, body: .request(.set(.inputSwitchClass1(.init(input: .storage, channel: .four)))))),
            ("%1INPT 45", .init(class: .one, command: .inputSwitch, body: .request(.set(.inputSwitchClass1(.init(input: .storage, channel: .five)))))),
            ("%1INPT 46", .init(class: .one, command: .inputSwitch, body: .request(.set(.inputSwitchClass1(.init(input: .storage, channel: .six)))))),
            ("%1INPT 47", .init(class: .one, command: .inputSwitch, body: .request(.set(.inputSwitchClass1(.init(input: .storage, channel: .seven)))))),
            ("%1INPT 48", .init(class: .one, command: .inputSwitch, body: .request(.set(.inputSwitchClass1(.init(input: .storage, channel: .eight)))))),
            ("%1INPT 49", .init(class: .one, command: .inputSwitch, body: .request(.set(.inputSwitchClass1(.init(input: .storage, channel: .nine)))))),
            ("%1INPT 51", .init(class: .one, command: .inputSwitch, body: .request(.set(.inputSwitchClass1(.init(input: .network, channel: .one)))))),
            ("%1INPT 52", .init(class: .one, command: .inputSwitch, body: .request(.set(.inputSwitchClass1(.init(input: .network, channel: .two)))))),
            ("%1INPT 53", .init(class: .one, command: .inputSwitch, body: .request(.set(.inputSwitchClass1(.init(input: .network, channel: .three)))))),
            ("%1INPT 54", .init(class: .one, command: .inputSwitch, body: .request(.set(.inputSwitchClass1(.init(input: .network, channel: .four)))))),
            ("%1INPT 55", .init(class: .one, command: .inputSwitch, body: .request(.set(.inputSwitchClass1(.init(input: .network, channel: .five)))))),
            ("%1INPT 56", .init(class: .one, command: .inputSwitch, body: .request(.set(.inputSwitchClass1(.init(input: .network, channel: .six)))))),
            ("%1INPT 57", .init(class: .one, command: .inputSwitch, body: .request(.set(.inputSwitchClass1(.init(input: .network, channel: .seven)))))),
            ("%1INPT 58", .init(class: .one, command: .inputSwitch, body: .request(.set(.inputSwitchClass1(.init(input: .network, channel: .eight)))))),
            ("%1INPT 59", .init(class: .one, command: .inputSwitch, body: .request(.set(.inputSwitchClass1(.init(input: .network, channel: .nine)))))),
            ("%1AVMT 11", .init(class: .one, command: .avMute, body: .request(.set(.avMute(.init(mute: .video, state: .on)))))),
            ("%1AVMT 10", .init(class: .one, command: .avMute, body: .request(.set(.avMute(.init(mute: .video, state: .off)))))),
            ("%1AVMT 21", .init(class: .one, command: .avMute, body: .request(.set(.avMute(.init(mute: .audio, state: .on)))))),
            ("%1AVMT 20", .init(class: .one, command: .avMute, body: .request(.set(.avMute(.init(mute: .audio, state: .off)))))),
            ("%1AVMT 31", .init(class: .one, command: .avMute, body: .request(.set(.avMute(.init(mute: .audioVideo, state: .on)))))),
            ("%1AVMT 30", .init(class: .one, command: .avMute, body: .request(.set(.avMute(.init(mute: .audioVideo, state: .off)))))),
            ("%2SVOL 0", .init(class: .two, command: .speakerVolume, body: .request(.set(.speakerVolume(.decrease))))),
            ("%2SVOL 1", .init(class: .two, command: .speakerVolume, body: .request(.set(.speakerVolume(.increase))))),
            ("%2MVOL 0", .init(class: .two, command: .microphoneVolume, body: .request(.set(.microphoneVolume(.decrease))))),
            ("%2MVOL 1", .init(class: .two, command: .microphoneVolume, body: .request(.set(.microphoneVolume(.increase))))),
            ("%2FREZ 0", .init(class: .two, command: .freeze, body: .request(.set(.freeze(.stop))))),
            ("%2FREZ 1", .init(class: .two, command: .freeze, body: .request(.set(.freeze(.start))))),
        ]
        for testCase in testCases {
            let message = try PJLink.Message(testCase.0)
            #expect(message == testCase.1)
        }
    }
}
