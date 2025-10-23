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
        var testCases: [TestCase] = [
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
            .init("%2IRES ?", .init(class: .two, command: .inputResolution, body: .request(.get(.inputResolution)))),
            .init("%2RRES ?", .init(class: .two, command: .recommendedResolution, body: .request(.get(.recommendedResolution)))),
            .init("%2FILT ?", .init(class: .two, command: .filterUsageTime, body: .request(.get(.filterUsageTime)))),
            .init("%2RLMP ?", .init(class: .two, command: .lampReplacementModelNumber, body: .request(.get(.lampReplacementModelNumber)))),
            .init("%2RFIL ?", .init(class: .two, command: .filterReplacementModelNumber, body: .request(.get(.filterReplacementModelNumber)))),
            .init("%2FREZ ?", .init(class: .two, command: .freeze, body: .request(.get(.freeze)))),
        ]
        PJLink.InputSwitchClass2.allCases.forEach { input in
            let testCase = TestCase(
                "%2INNM ?\(input.input.rawValue)\(input.channel.rawValue)",
                .init(class: .two, command: .inputTerminalName, body: .request(.get(.inputTerminalName(input))))
            )
            testCases.append(testCase)
        }
        try run(testCases)
    }

    @Test
    func setRequestsHappyPath() throws {
        var testCases: [TestCase] = [
            .init("%1POWR 1", .init(class: .one, command: .power, body: .request(.set(.power(.on))))),
            .init("%1POWR 0", .init(class: .one, command: .power, body: .request(.set(.power(.off))))),
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
        PJLink.InputSwitchClass1.allCases.forEach { input in
            let testCase = TestCase(
                "%1INPT \(input.input.rawValue)\(input.channel.rawValue)",
                .init(class: .one, command: .inputSwitch, body: .request(.set(.inputSwitchClass1(input))))
            )
            testCases.append(testCase)
        }
        PJLink.InputSwitchClass2.allCases.forEach { input in
            let testCase = TestCase(
                "%2INPT \(input.input.rawValue)\(input.channel.rawValue)",
                .init(class: .two, command: .inputSwitch, body: .request(.set(.inputSwitchClass2(input))))
            )
            testCases.append(testCase)
        }
        try run(testCases)
    }

    @Test
    func setResponsesHappyPath() throws {
        var testCases = [TestCase]()
        // Add cases for OK, ERR1, ERR2, ERR3, and ERR4 for every set request
        PJLink.Command.allSetCommands.forEach { command in
            command.classes.forEach { commandClass in
                PJLink.ErrorResponse.allCases.forEach { errorResponse in
                    testCases.append(
                        .init(
                            "%\(commandClass.rawValue)\(command.rawValue)=\(errorResponse.rawValue)",
                            .init(
                                class: commandClass,
                                command: command,
                                body: .response(.code(errorResponse))
                            )
                        )
                    )
                }
            }
        }
        try run(testCases)
    }

    private func run(_ testCases: [TestCase]) throws {
        for testCase in testCases {
            let actual = try PJLink.Message(testCase.input)
            #expect(actual == testCase.expected)
        }
    }
}
