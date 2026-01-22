//
//  StringParsingTests.swift
//  pjlink-client-swift
//
//  Created by Eric Hyche on 10/22/25.
//

@testable import PJLinkCommon
@testable import PJLinkClient
import Testing

@Suite
struct StringParsingTests {
    struct TestCase {
        var input: String
        var expected: Swift.Result<PJLink.Message, PJLink.Error>
        var isSetReponseHint: Bool?

        init(_ input: String, _ expected: Swift.Result<PJLink.Message, PJLink.Error>, _ isSetReponseHint: Bool? = nil) {
            self.input = input
            self.expected = expected
            self.isSetReponseHint = isSetReponseHint
        }
    }

    @Test
    func powerRequest() throws {
        let testCases: [TestCase] = [
            .init("%1POWR ?", .success(.request(.get(.power)))),
            .init("%2POWR ?", .failure(.unexpectedGetRequest(.two, .power, ""))),
            .init("%1POWR ?X", .failure(.unexpectedGetRequest(.one, .power, "X"))),
            .init("%1POWR 1", .success(.request(.set(.power(.on))))),
            .init("%1POWR 0", .success(.request(.set(.power(.off))))),
            .init("%2POWR 0", .failure(.unexpectedSetRequest(.two, .power))),
            .init("%1POWR x", .failure(.invalidOnOff("x"))),
        ]
        try run(testCases)
    }

    @Test
    func powerResponse() throws {
        let testCases: [TestCase] = [
            .init("%1POWR=0", .success(.response(.get(.success(.power(.standby)))))),
            .init("%1POWR=0", .failure(.invalidSetResponseCode("0")), true),
            .init("%1POWR=0", .success(.response(.get(.success(.power(.standby))))), false),
            .init("%1POWR=1", .success(.response(.get(.success(.power(.lampOn)))))),
            .init("%1POWR=1", .failure(.invalidSetResponseCode("1")), true),
            .init("%1POWR=1", .success(.response(.get(.success(.power(.lampOn))))), false),
            .init("%1POWR=2", .success(.response(.get(.success(.power(.cooling)))))),
            .init("%1POWR=2", .failure(.invalidSetResponseCode("2")), true),
            .init("%1POWR=2", .success(.response(.get(.success(.power(.cooling))))), false),
            .init("%1POWR=3", .success(.response(.get(.success(.power(.warmUp)))))),
            .init("%1POWR=3", .failure(.invalidSetResponseCode("3")), true),
            .init("%1POWR=3", .success(.response(.get(.success(.power(.warmUp))))), false),
            .init("%2POWR=0", .failure(.unexpectedGetResponse(.two, .power))),
            .init("%1POWR=FOO", .failure(.invalidPowerStatus("FOO"))),
            .init("%1POWR=FOO", .failure(.invalidSetResponseCode("FOO")), true),
            .init("%1POWR=FOO", .failure(.invalidPowerStatus("FOO")), false),
            .init("%1POWR=OK", .success(.response(.set(.init(pjlinkClass: .one, command: .power, code: .ok))))),
            .init("%1POWR=OK", .success(.response(.set(.init(pjlinkClass: .one, command: .power, code: .ok)))), true),
            .init("%1POWR=OK", .failure(.invalidPowerStatus("OK")), false),
            .init("%1POWR=ERR1", .success(.response(.set(.init(pjlinkClass: .one, command: .power, code: .undefinedCommand))))),
            .init("%1POWR=ERR1", .success(.response(.set(.init(pjlinkClass: .one, command: .power, code: .undefinedCommand)))), true),
            .init("%1POWR=ERR1", .success(.response(.get(.failure(.init(pjLinkClass: .one, command: .power, code: .undefinedCommand))))), false),
            .init("%1POWR=ERR2", .success(.response(.set(.init(pjlinkClass: .one, command: .power, code: .outOfParameter))))),
            .init("%1POWR=ERR2", .success(.response(.set(.init(pjlinkClass: .one, command: .power, code: .outOfParameter)))), true),
            .init("%1POWR=ERR2", .success(.response(.get(.failure(.init(pjLinkClass: .one, command: .power, code: .outOfParameter))))), false),
            .init("%1POWR=ERR3", .success(.response(.set(.init(pjlinkClass: .one, command: .power, code: .unavailableTime))))),
            .init("%1POWR=ERR3", .success(.response(.set(.init(pjlinkClass: .one, command: .power, code: .unavailableTime)))), true),
            .init("%1POWR=ERR3", .success(.response(.get(.failure(.init(pjLinkClass: .one, command: .power, code: .unavailableTime))))), false),
            .init("%1POWR=ERR4", .success(.response(.set(.init(pjlinkClass: .one, command: .power, code: .projectorFailure))))),
            .init("%1POWR=ERR4", .success(.response(.set(.init(pjlinkClass: .one, command: .power, code: .projectorFailure)))), true),
            .init("%1POWR=ERR4", .success(.response(.get(.failure(.init(pjLinkClass: .one, command: .power, code: .projectorFailure))))), false),
        ]
        try run(testCases)
    }

    @Test
    func inputSwitchRequest() throws {
        var testCases: [TestCase] = [
            .init("%1INPT ?", .success(.request(.get(.inputSwitchClass1)))),
            .init("%2INPT ?", .success(.request(.get(.inputSwitchClass2)))),
            .init("%3INPT ?", .failure(.invalidClass("3"))),
            .init("%1INPT ?EXTRA", .failure(.unexpectedGetRequest(.one, .inputSwitch, "EXTRA"))),
            .init("%1INPT 61", .failure(.invalidClass1Input("6"))),
            .init("%1INPT 50", .failure(.invalidClass1InputChannel("0"))),
            .init("%2INPT 71", .failure(.invalidClass2Input("7"))),
            .init("%2INPT 60", .failure(.invalidClass2InputChannel("0"))),
        ]
        PJLink.InputSwitchClass1.allCases.forEach { inputSwitch in
            testCases.append(
                .init(
                    "%1INPT \(inputSwitch.input.rawValue)\(inputSwitch.channel.rawValue)",
                    .success(.request(.set(.inputSwitchClass1(inputSwitch)))),
                    false
                )
            )
        }
        PJLink.InputSwitchClass2.allCases.forEach { inputSwitch in
            testCases.append(
                .init(
                    "%2INPT \(inputSwitch.input.rawValue)\(inputSwitch.channel.rawValue)",
                    .success(.request(.set(.inputSwitchClass2(inputSwitch)))),
                    false
                )
            )
        }
        try run(testCases)
    }

    @Test
    func inputSwitchResponse() throws {
        var testCases: [TestCase] = [
            .init(
                "%1INPT=OK",
                .success(.response(.set(.init(pjlinkClass: .one, command: .inputSwitch, code: .ok))))
            ),
            .init(
                "%1INPT=OK",
                .success(.response(.set(.init(pjlinkClass: .one, command: .inputSwitch, code: .ok)))),
                true
            ),
            .init(
                "%1INPT=OK",
                .failure(.invalidClass1Input("O")),
                false
            ),
            .init(
                "%1INPT=ERR1",
                .success(.response(.set(.init(pjlinkClass: .one, command: .inputSwitch, code: .undefinedCommand))))
            ),
            .init(
                "%1INPT=ERR1",
                .success(.response(.set(.init(pjlinkClass: .one, command: .inputSwitch, code: .undefinedCommand)))),
                true
            ),
            .init(
                "%1INPT=ERR1",
                .success(.response(.get(.failure(.init(pjLinkClass: .one, command: .inputSwitch, code: .undefinedCommand))))),
                false
            ),
            .init(
                "%1INPT=ERR2",
                .success(.response(.set(.init(pjlinkClass: .one, command: .inputSwitch, code: .outOfParameter))))
            ),
            .init(
                "%1INPT=ERR2",
                .success(.response(.set(.init(pjlinkClass: .one, command: .inputSwitch, code: .outOfParameter)))),
                true
            ),
            .init(
                "%1INPT=ERR2",
                .success(.response(.get(.failure(.init(pjLinkClass: .one, command: .inputSwitch, code: .outOfParameter))))),
                false
            ),
            .init(
                "%1INPT=ERR3",
                .success(.response(.set(.init(pjlinkClass: .one, command: .inputSwitch, code: .unavailableTime))))
            ),
            .init(
                "%1INPT=ERR3",
                .success(.response(.set(.init(pjlinkClass: .one, command: .inputSwitch, code: .unavailableTime)))),
                true
            ),
            .init(
                "%1INPT=ERR3",
                .success(.response(.get(.failure(.init(pjLinkClass: .one, command: .inputSwitch, code: .unavailableTime))))),
                false
            ),
            .init(
                "%1INPT=ERR4",
                .success(.response(.set(.init(pjlinkClass: .one, command: .inputSwitch, code: .projectorFailure))))
            ),
            .init(
                "%1INPT=ERR4",
                .success(.response(.set(.init(pjlinkClass: .one, command: .inputSwitch, code: .projectorFailure)))),
                true
            ),
            .init(
                "%1INPT=ERR4",
                .success(.response(.get(.failure(.init(pjLinkClass: .one, command: .inputSwitch, code: .projectorFailure))))),
                false
            ),
            .init(
                "%2INPT=OK",
                .success(.response(.set(.init(pjlinkClass: .two, command: .inputSwitch, code: .ok))))
            ),
            .init(
                "%2INPT=OK",
                .success(.response(.set(.init(pjlinkClass: .two, command: .inputSwitch, code: .ok)))),
                true
            ),
            .init(
                "%2INPT=OK",
                .failure(.invalidClass2Input("O")),
                false
            ),
            .init(
                "%2INPT=ERR1",
                .success(.response(.set(.init(pjlinkClass: .two, command: .inputSwitch, code: .undefinedCommand))))
            ),
            .init(
                "%2INPT=ERR1",
                .success(.response(.set(.init(pjlinkClass: .two, command: .inputSwitch, code: .undefinedCommand)))),
                true
            ),
            .init(
                "%2INPT=ERR1",
                .success(.response(.get(.failure(.init(pjLinkClass: .two, command: .inputSwitch, code: .undefinedCommand))))),
                false
            ),
            .init(
                "%2INPT=ERR2",
                .success(.response(.set(.init(pjlinkClass: .two, command: .inputSwitch, code: .outOfParameter))))
            ),
            .init(
                "%2INPT=ERR2",
                .success(.response(.set(.init(pjlinkClass: .two, command: .inputSwitch, code: .outOfParameter)))),
                true
            ),
            .init(
                "%2INPT=ERR2",
                .success(.response(.get(.failure(.init(pjLinkClass: .two, command: .inputSwitch, code: .outOfParameter))))),
                false
            ),
            .init(
                "%2INPT=ERR3",
                .success(.response(.set(.init(pjlinkClass: .two, command: .inputSwitch, code: .unavailableTime))))
            ),
            .init(
                "%2INPT=ERR3",
                .success(.response(.set(.init(pjlinkClass: .two, command: .inputSwitch, code: .unavailableTime)))),
                true
            ),
            .init(
                "%2INPT=ERR3",
                .success(.response(.get(.failure(.init(pjLinkClass: .two, command: .inputSwitch, code: .unavailableTime))))),
                false
            ),
            .init(
                "%2INPT=ERR4",
                .success(.response(.set(.init(pjlinkClass: .two, command: .inputSwitch, code: .projectorFailure))))
            ),
            .init(
                "%2INPT=ERR4",
                .success(.response(.set(.init(pjlinkClass: .two, command: .inputSwitch, code: .projectorFailure)))),
                true
            ),
            .init(
                "%2INPT=ERR4",
                .success(.response(.get(.failure(.init(pjLinkClass: .two, command: .inputSwitch, code: .projectorFailure))))),
                false
            ),
            .init(
                "%2INPT=71",
                .failure(.invalidClass2Input("7"))
            ),
            .init(
                "%2INPT=60",
                .failure(.invalidClass2InputChannel("0"))
            ),
        ]
        PJLink.InputSwitchClass1.allCases.forEach { inputSwitch in
            let inputStr = "\(inputSwitch.input.rawValue)\(inputSwitch.channel.rawValue)"
            testCases.append(
                .init(
                    "%1INPT=\(inputStr)",
                    .success(.response(.get(.success(.inputSwitchClass1(inputSwitch)))))
                )
            )
            testCases.append(
                .init(
                    "%1INPT=\(inputStr)",
                    .failure(.invalidSetResponseCode(inputStr)),
                    true
                )
            )
            testCases.append(
                .init(
                    "%1INPT=\(inputStr)",
                    .success(.response(.get(.success(.inputSwitchClass1(inputSwitch))))),
                    false
                )
            )
        }
        PJLink.InputSwitchClass2.allCases.forEach { inputSwitch in
            let inputStr = "\(inputSwitch.input.rawValue)\(inputSwitch.channel.rawValue)"
            testCases.append(
                .init(
                    "%2INPT=\(inputStr)",
                    .success(.response(.get(.success(.inputSwitchClass2(inputSwitch)))))
                )
            )
            testCases.append(
                .init(
                    "%2INPT=\(inputStr)",
                    .failure(.invalidSetResponseCode(inputStr)),
                    true
                )
            )
            testCases.append(
                .init(
                    "%2INPT=\(inputStr)",
                    .success(.response(.get(.success(.inputSwitchClass2(inputSwitch))))),
                    false
                )
            )
        }
        try run(testCases)
    }

    @Test
    func muteRequest() throws {
        var testCases: [TestCase] = [
            .init("%1AVMT ?", .success(.request(.get(.avMute)))),
            .init("%2AVMT ?", .failure(.unexpectedGetRequest(.two, .avMute, ""))),
            .init("%3AVMT ?", .failure(.invalidClass("3"))),
            .init("%1AVMT ?XTRA",  .failure(.unexpectedGetRequest(.one, .avMute, "XTRA"))),
            .init("%1AVMT 41", .failure(.invalidMute("4"))),
            .init("%1AVMT 32", .failure(.invalidOnOff("2"))),
        ]
        PJLink.MuteState.allCases.forEach { muteState in
            testCases.append(
                .init(
                    "%1AVMT \(muteState.description)",
                    .success(.request(.set(.avMute(muteState))))
                )
            )
        }
        try run(testCases)
    }

    @Test
    func muteResponse() throws {
        var testCases: [TestCase] = [
            .init(
                "%1AVMT=OK",
                .success(.response(.set(.init(pjlinkClass: .one, command: .avMute, code: .ok))))
            ),
            .init(
                "%1AVMT=OK",
                .success(.response(.set(.init(pjlinkClass: .one, command: .avMute, code: .ok)))),
                true
            ),
            .init(
                "%1AVMT=OK",
                .failure(.invalidMute("O")),
                false
            ),
            .init(
                "%1AVMT=ERR1",
                .success(.response(.set(.init(pjlinkClass: .one, command: .avMute, code: .undefinedCommand))))
            ),
            .init(
                "%1AVMT=ERR1",
                .success(.response(.set(.init(pjlinkClass: .one, command: .avMute, code: .undefinedCommand)))),
                true
            ),
            .init(
                "%1AVMT=ERR1",
                .success(.response(.get(.failure(.init(pjLinkClass: .one, command: .avMute, code: .undefinedCommand))))),
                false
            ),
            .init(
                "%1AVMT=ERR2",
                .success(.response(.set(.init(pjlinkClass: .one, command: .avMute, code: .outOfParameter))))
            ),
            .init(
                "%1AVMT=ERR2",
                .success(.response(.set(.init(pjlinkClass: .one, command: .avMute, code: .outOfParameter)))),
                true
            ),
            .init(
                "%1AVMT=ERR2",
                .success(.response(.get(.failure(.init(pjLinkClass: .one, command: .avMute, code: .outOfParameter))))),
                false
            ),
            .init(
                "%1AVMT=ERR3",
                .success(.response(.set(.init(pjlinkClass: .one, command: .avMute, code: .unavailableTime))))
            ),
            .init(
                "%1AVMT=ERR3",
                .success(.response(.set(.init(pjlinkClass: .one, command: .avMute, code: .unavailableTime)))),
                true
            ),
            .init(
                "%1AVMT=ERR3",
                .success(.response(.get(.failure(.init(pjLinkClass: .one, command: .avMute, code: .unavailableTime))))),
                false
            ),
            .init(
                "%1AVMT=ERR4",
                .success(.response(.set(.init(pjlinkClass: .one, command: .avMute, code: .projectorFailure))))
            ),
            .init(
                "%1AVMT=ERR4",
                .success(.response(.set(.init(pjlinkClass: .one, command: .avMute, code: .projectorFailure)))),
                true
            ),
            .init(
                "%1AVMT=ERR4",
                .success(.response(.get(.failure(.init(pjLinkClass: .one, command: .avMute, code: .projectorFailure))))),
                false
            ),
            .init(
                "%1AVMT=41",
                .failure(.invalidMute("4"))
            ),
            .init(
                "%1AVMT=32",
                .failure(.invalidOnOff("2"))
            ),
        ]
        PJLink.MuteState.allCases.forEach { muteState in
            testCases.append(
                .init(
                    "%1AVMT=\(muteState.description)",
                    .success(.response(.get(.success(.avMute(muteState)))))
                )
            )
        }
        try run(testCases)
    }

    @Test
    func errorStatusRequest() throws {
        let testCases: [TestCase] = [
            .init("%1ERST ?", .success(.request(.get(.errorStatus)))),
            .init("%2ERST ?", .failure(.unexpectedGetRequest(.two, .errorStatus, ""))),
            .init("%3ERST ?", .failure(.invalidClass("3"))),
            .init("%1ERST ?XTRA",  .failure(.unexpectedGetRequest(.one, .errorStatus, "XTRA"))),
        ]
        try run(testCases)
    }

    @Test
    func errorStatusResponse() throws {
        var testCases: [TestCase] = [
            .init(
                "%2ERST=000000",
                .failure(.unexpectedGetResponse(.two, .errorStatus))
            ),
            .init(
                "%1ERST=000003",
                .failure(.invalidErrorStatus("000003"))
            ),
            .init(
                "%1ERST=000030",
                .failure(.invalidErrorStatus("000030"))
            ),
            .init(
                "%1ERST=000300",
                .failure(.invalidErrorStatus("000300"))
            ),
            .init(
                "%1ERST=003000",
                .failure(.invalidErrorStatus("003000"))
            ),
            .init(
                "%1ERST=030000",
                .failure(.invalidErrorStatus("030000"))
            ),
            .init(
                "%1ERST=300000",
                .failure(.invalidErrorStatus("300000"))
            ),
        ]
        PJLink.ErrorStatus.allCases.forEach { errorStatus in
            testCases.append(
                .init(
                    "%1ERST=\(errorStatus.description)",
                    .success(.response(.get(.success(.errorStatus(errorStatus)))))
                )
            )
        }
        try run(testCases)
    }

    @Test
    func lampRequest() throws {
        let testCases: [TestCase] = [
            .init("%1LAMP ?", .success(.request(.get(.lamp)))),
            .init("%2LAMP ?", .failure(.unexpectedGetRequest(.two, .lamp, ""))),
            .init("%3LAMP ?", .failure(.invalidClass("3"))),
            .init("%1LAMP ?XTRA",  .failure(.unexpectedGetRequest(.one, .lamp, "XTRA"))),
        ]
        try run(testCases)
    }

    @Test
    func lampResponse() throws {
        let testCases: [TestCase] = [
            .init("%1LAMP=0 0 0", .failure(.invalidLampStatusCount(3))),
            .init("%1LAMP=A 0", .failure(.invalidLampUsageTime("A"))),
            .init("%1LAMP=-1 0", .failure(.lampUsageTimeOutOfRange(-1))),
            .init("%1LAMP=100000 0", .failure(.lampUsageTimeOutOfRange(100000))),
            .init("%1LAMP=0 2", .failure(.invalidLampOnOff("2"))),
            .init("%1LAMP=1 0", .success(.response(.get(.success(.lamp(.init(lampStatus: [.init(usageTime: 1, state: .off)]))))))),
            .init("%1LAMP=1 1", .success(.response(.get(.success(.lamp(.init(lampStatus: [.init(usageTime: 1, state: .on)]))))))),
            .init("%2LAMP=1 0", .failure(.unexpectedGetResponse(.two, .lamp))),
            .init(
                "%1LAMP=ERR1",
                .success(.response(.set(.init(pjlinkClass: .one, command: .lamp, code: .undefinedCommand))))
            ),
            .init(
                "%1LAMP=ERR1",
                .success(.response(.set(.init(pjlinkClass: .one, command: .lamp, code: .undefinedCommand)))),
                true
            ),
            .init(
                "%1LAMP=ERR1",
                .success(.response(.get(.failure(.init(pjLinkClass: .one, command: .lamp, code: .undefinedCommand))))),
                false
            ),
            .init(
                "%1LAMP=ERR2",
                .success(.response(.set(.init(pjlinkClass: .one, command: .lamp, code: .outOfParameter))))
            ),
            .init(
                "%1LAMP=ERR2",
                .success(.response(.set(.init(pjlinkClass: .one, command: .lamp, code: .outOfParameter)))),
                true
            ),
            .init(
                "%1LAMP=ERR2",
                .success(.response(.get(.failure(.init(pjLinkClass: .one, command: .lamp, code: .outOfParameter))))),
                false
            ),
            .init(
                "%1LAMP=ERR3",
                .success(.response(.set(.init(pjlinkClass: .one, command: .lamp, code: .unavailableTime))))
            ),
            .init(
                "%1LAMP=ERR3",
                .success(.response(.set(.init(pjlinkClass: .one, command: .lamp, code: .unavailableTime)))),
                true
            ),
            .init(
                "%1LAMP=ERR3",
                .success(.response(.get(.failure(.init(pjLinkClass: .one, command: .lamp, code: .unavailableTime))))),
                false
            ),
            .init(
                "%1LAMP=ERR4",
                .success(.response(.set(.init(pjlinkClass: .one, command: .lamp, code: .projectorFailure))))
            ),
            .init(
                "%1LAMP=ERR4",
                .success(.response(.set(.init(pjlinkClass: .one, command: .lamp, code: .projectorFailure)))),
                true
            ),
            .init(
                "%1LAMP=ERR4",
                .success(.response(.get(.failure(.init(pjLinkClass: .one, command: .lamp, code: .projectorFailure))))),
                false
            ),
        ]
        try run(testCases)
    }

    @Test
    func inputListRequest() throws {
        let testCases: [TestCase] = [
            .init("%1INST ?", .success(.request(.get(.inputListClass1)))),
            .init("%2INST ?", .success(.request(.get(.inputListClass2)))),
            .init("%3INST ?", .failure(.invalidClass("3"))),
            .init("%1INST ?XTRA",  .failure(.unexpectedGetRequest(.one, .inputList, "XTRA"))),
            .init("%2INST ?XTRA",  .failure(.unexpectedGetRequest(.two, .inputList, "XTRA"))),
        ]
        try run(testCases)
    }

    @Test
    func inputListResponse() throws {
        var testCases: [TestCase] = [
            .init(
                "%3INST=11",
                .failure(.invalidClass("3"))
            ),
            .init(
                "%1INST=ERR1",
                .success(.response(.set(.init(pjlinkClass: .one, command: .inputList, code: .undefinedCommand))))
            ),
            .init(
                "%1INST=ERR1",
                .success(.response(.set(.init(pjlinkClass: .one, command: .inputList, code: .undefinedCommand)))),
                true
            ),
            .init(
                "%1INST=ERR1",
                .success(.response(.get(.failure(.init(pjLinkClass: .one, command: .inputList, code: .undefinedCommand))))),
                false
            ),
            .init(
                "%1INST=ERR2",
                .success(.response(.set(.init(pjlinkClass: .one, command: .inputList, code: .outOfParameter))))
            ),
            .init(
                "%1INST=ERR2",
                .success(.response(.set(.init(pjlinkClass: .one, command: .inputList, code: .outOfParameter)))),
                true
            ),
            .init(
                "%1INST=ERR2",
                .success(.response(.get(.failure(.init(pjLinkClass: .one, command: .inputList, code: .outOfParameter))))),
                false
            ),
            .init(
                "%1INST=ERR3",
                .success(.response(.set(.init(pjlinkClass: .one, command: .inputList, code: .unavailableTime))))
            ),
            .init(
                "%1INST=ERR3",
                .success(.response(.set(.init(pjlinkClass: .one, command: .inputList, code: .unavailableTime)))),
                true
            ),
            .init(
                "%1INST=ERR3",
                .success(.response(.get(.failure(.init(pjLinkClass: .one, command: .inputList, code: .unavailableTime))))),
                false
            ),
            .init(
                "%1INST=ERR4",
                .success(.response(.set(.init(pjlinkClass: .one, command: .inputList, code: .projectorFailure))))
            ),
            .init(
                "%1INST=ERR4",
                .success(.response(.set(.init(pjlinkClass: .one, command: .inputList, code: .projectorFailure)))),
                true
            ),
            .init(
                "%1INST=ERR4",
                .success(.response(.get(.failure(.init(pjLinkClass: .one, command: .inputList, code: .projectorFailure))))),
                false
            ),
        ]
        PJLink.InputSwitchClass1.allCases.forEach { inputSwitch in
            testCases.append(
                .init(
                    "%1INST=\(inputSwitch.description)",
                    .success(.response(.get(.success(.inputListClass1(.init(switches: [inputSwitch]))))))
                )
            )
        }
        PJLink.InputSwitchClass2.allCases.forEach { inputSwitch in
            testCases.append(
                .init(
                    "%2INST=\(inputSwitch.description)",
                    .success(.response(.get(.success(.inputListClass2(.init(switches: [inputSwitch]))))))
                )
            )
        }
        testCases.append(
            .init(
                "%1INST=\(PJLink.InputSwitchesClass1(switches: PJLink.InputSwitchClass1.allCases).description)",
                .success(.response(.get(.success(.inputListClass1(.init(switches: PJLink.InputSwitchClass1.allCases))))))
            )
        )
        testCases.append(
            .init(
                "%2INST=\(PJLink.InputSwitchesClass2(switches: PJLink.InputSwitchClass2.allCases).description)",
                .success(.response(.get(.success(.inputListClass2(.init(switches: PJLink.InputSwitchClass2.allCases))))))
            )
        )
        try run(testCases)
    }

    @Test
    func projectorNameRequest() throws {
        let testCases: [TestCase] = [
            .init("%1NAME ?", .success(.request(.get(.projectorName)))),
            .init("%2NAME ?", .failure(.unexpectedGetRequest(.two, .projectorName, ""))),
            .init("%3NAME ?", .failure(.invalidClass("3"))),
            .init("%1NAME ?XTRA",  .failure(.unexpectedGetRequest(.one, .projectorName, "XTRA"))),
            .init("%2NAME ?XTRA",  .failure(.unexpectedGetRequest(.two, .projectorName, "XTRA"))),
        ]
        try run(testCases)
    }

    @Test
    func projectorNameResponse() throws {
        let testCases: [TestCase] = [
            .init(
                "%1NAME=foo",
                .success(.response(.get(.success(.projectorName(.init(value: "foo"))))))
            ),
            .init(
                "%2NAME=foo",
                .failure(.unexpectedGetResponse(.two, .projectorName))
            ),
            .init(
                "%3NAME=foo",
                .failure(.invalidClass("3"))
            ),
            .init(
                "%1NAME=01234567890123456789012345678901234567890123456789012345678901234", // Length 65
                .failure(.stringExceedsMaximumLength(65, 64))
            ),
            .init(
                "%1NAME=Name\tWith\tTab", // Contains illegal character
                .failure(.characterOutOfValidBounds(9, 32...255))
            ),
            .init(
                "%1NAME=ERR1",
                .success(.response(.set(.init(pjlinkClass: .one, command: .projectorName, code: .undefinedCommand))))
            ),
            .init(
                "%1NAME=ERR1",
                .success(.response(.set(.init(pjlinkClass: .one, command: .projectorName, code: .undefinedCommand)))),
                true
            ),
            .init(
                "%1NAME=ERR1",
                .success(.response(.get(.failure(.init(pjLinkClass: .one, command: .projectorName, code: .undefinedCommand))))),
                false
            ),
            .init(
                "%1NAME=ERR2",
                .success(.response(.set(.init(pjlinkClass: .one, command: .projectorName, code: .outOfParameter))))
            ),
            .init(
                "%1NAME=ERR2",
                .success(.response(.set(.init(pjlinkClass: .one, command: .projectorName, code: .outOfParameter)))),
                true
            ),
            .init(
                "%1NAME=ERR2",
                .success(.response(.get(.failure(.init(pjLinkClass: .one, command: .projectorName, code: .outOfParameter))))),
                false
            ),
            .init(
                "%1NAME=ERR3",
                .success(.response(.set(.init(pjlinkClass: .one, command: .projectorName, code: .unavailableTime))))
            ),
            .init(
                "%1NAME=ERR3",
                .success(.response(.set(.init(pjlinkClass: .one, command: .projectorName, code: .unavailableTime)))),
                true
            ),
            .init(
                "%1NAME=ERR3",
                .success(.response(.get(.failure(.init(pjLinkClass: .one, command: .projectorName, code: .unavailableTime))))),
                false
            ),
            .init(
                "%1NAME=ERR4",
                .success(.response(.set(.init(pjlinkClass: .one, command: .projectorName, code: .projectorFailure))))
            ),
            .init(
                "%1NAME=ERR4",
                .success(.response(.set(.init(pjlinkClass: .one, command: .projectorName, code: .projectorFailure)))),
                true
            ),
            .init(
                "%1NAME=ERR4",
                .success(.response(.get(.failure(.init(pjLinkClass: .one, command: .projectorName, code: .projectorFailure))))),
                false
            ),
        ]
        try run(testCases)
    }

    @Test
    func manufacturerNameRequest() throws {
        let testCases: [TestCase] = [
            .init("%1INF1 ?", .success(.request(.get(.manufacturerName)))),
            .init("%2INF1 ?", .failure(.unexpectedGetRequest(.two, .manufacturerName, ""))),
            .init("%3INF1 ?", .failure(.invalidClass("3"))),
            .init("%1INF1 ?XTRA",  .failure(.unexpectedGetRequest(.one, .manufacturerName, "XTRA"))),
        ]
        try run(testCases)
    }

    @Test
    func manufacturerNameResponse() throws {
        let testCases: [TestCase] = [
            .init(
                "%1INF1=foo",
                .success(.response(.get(.success(.manufacturerName(.init(value: "foo"))))))
            ),
            .init(
                "%2INF1=foo",
                .failure(.unexpectedGetResponse(.two, .manufacturerName))
            ),
            .init(
                "%3INF1=foo",
                .failure(.invalidClass("3"))
            ),
            .init(
                "%1INF1=012345678901234567890123456789012", // Length 33
                .failure(.stringExceedsMaximumLength(33, 32))
            ),
            .init(
                "%1INF1=Name\tWith\tTab", // Contains character lower than legal bounds
                .failure(.characterOutOfValidBounds(9, 32...126))
            ),
            .init(
                "%1INF1=Name With Illegal Character: ≥", // Contains character higher than legal bounds
                .failure(.characterOutOfValidBounds(226, 32...126))
            ),
            .init(
                "%1INF1=ERR1",
                .success(.response(.set(.init(pjlinkClass: .one, command: .manufacturerName, code: .undefinedCommand))))
            ),
            .init(
                "%1INF1=ERR1",
                .success(.response(.set(.init(pjlinkClass: .one, command: .manufacturerName, code: .undefinedCommand)))),
                true
            ),
            .init(
                "%1INF1=ERR1",
                .success(.response(.get(.failure(.init(pjLinkClass: .one, command: .manufacturerName, code: .undefinedCommand))))),
                false
            ),
            .init(
                "%1INF1=ERR2",
                .success(.response(.set(.init(pjlinkClass: .one, command: .manufacturerName, code: .outOfParameter))))
            ),
            .init(
                "%1INF1=ERR2",
                .success(.response(.set(.init(pjlinkClass: .one, command: .manufacturerName, code: .outOfParameter)))),
                true
            ),
            .init(
                "%1INF1=ERR2",
                .success(.response(.get(.failure(.init(pjLinkClass: .one, command: .manufacturerName, code: .outOfParameter))))),
                false
            ),
            .init(
                "%1INF1=ERR3",
                .success(.response(.set(.init(pjlinkClass: .one, command: .manufacturerName, code: .unavailableTime))))
            ),
            .init(
                "%1INF1=ERR3",
                .success(.response(.set(.init(pjlinkClass: .one, command: .manufacturerName, code: .unavailableTime)))),
                true
            ),
            .init(
                "%1INF1=ERR3",
                .success(.response(.get(.failure(.init(pjLinkClass: .one, command: .manufacturerName, code: .unavailableTime))))),
                false
            ),
            .init(
                "%1INF1=ERR4",
                .success(.response(.set(.init(pjlinkClass: .one, command: .manufacturerName, code: .projectorFailure))))
            ),
            .init(
                "%1INF1=ERR4",
                .success(.response(.set(.init(pjlinkClass: .one, command: .manufacturerName, code: .projectorFailure)))),
                true
            ),
            .init(
                "%1INF1=ERR4",
                .success(.response(.get(.failure(.init(pjLinkClass: .one, command: .manufacturerName, code: .projectorFailure))))),
                false
            ),
        ]
        try run(testCases)
    }

    @Test
    func productNameRequest() throws {
        let testCases: [TestCase] = [
            .init("%1INF2 ?", .success(.request(.get(.productName)))),
            .init("%2INF2 ?", .failure(.unexpectedGetRequest(.two, .productName, ""))),
            .init("%3INF2 ?", .failure(.invalidClass("3"))),
            .init("%1INF2 ?XTRA",  .failure(.unexpectedGetRequest(.one, .productName, "XTRA"))),
        ]
        try run(testCases)
    }

    @Test
    func productNameResponse() throws {
        let testCases: [TestCase] = [
            .init(
                "%1INF2=foo",
                .success(.response(.get(.success(.productName(.init(value: "foo"))))))
            ),
            .init(
                "%2INF2=foo",
                .failure(.unexpectedGetResponse(.two, .productName))
            ),
            .init(
                "%3INF2=foo",
                .failure(.invalidClass("3"))
            ),
            .init(
                "%1INF2=012345678901234567890123456789012", // Length 33
                .failure(.stringExceedsMaximumLength(33, 32))
            ),
            .init(
                "%1INF2=Name\tWith\tTab", // Contains character lower than legal bounds
                .failure(.characterOutOfValidBounds(9, 32...126))
            ),
            .init(
                "%1INF2=Name With Illegal Character: ≥", // Contains character higher than legal bounds
                .failure(.characterOutOfValidBounds(226, 32...126))
            ),
            .init(
                "%1INF2=ERR1",
                .success(.response(.set(.init(pjlinkClass: .one, command: .productName, code: .undefinedCommand))))
            ),
            .init(
                "%1INF2=ERR1",
                .success(.response(.set(.init(pjlinkClass: .one, command: .productName, code: .undefinedCommand)))),
                true
            ),
            .init(
                "%1INF2=ERR1",
                .success(.response(.get(.failure(.init(pjLinkClass: .one, command: .productName, code: .undefinedCommand))))),
                false
            ),
            .init(
                "%1INF2=ERR2",
                .success(.response(.set(.init(pjlinkClass: .one, command: .productName, code: .outOfParameter))))
            ),
            .init(
                "%1INF2=ERR2",
                .success(.response(.set(.init(pjlinkClass: .one, command: .productName, code: .outOfParameter)))),
                true
            ),
            .init(
                "%1INF2=ERR2",
                .success(.response(.get(.failure(.init(pjLinkClass: .one, command: .productName, code: .outOfParameter))))),
                false
            ),
            .init(
                "%1INF2=ERR3",
                .success(.response(.set(.init(pjlinkClass: .one, command: .productName, code: .unavailableTime))))
            ),
            .init(
                "%1INF2=ERR3",
                .success(.response(.set(.init(pjlinkClass: .one, command: .productName, code: .unavailableTime)))),
                true
            ),
            .init(
                "%1INF2=ERR3",
                .success(.response(.get(.failure(.init(pjLinkClass: .one, command: .productName, code: .unavailableTime))))),
                false
            ),
            .init(
                "%1INF2=ERR4",
                .success(.response(.set(.init(pjlinkClass: .one, command: .productName, code: .projectorFailure))))
            ),
            .init(
                "%1INF2=ERR4",
                .success(.response(.set(.init(pjlinkClass: .one, command: .productName, code: .projectorFailure)))),
                true
            ),
            .init(
                "%1INF2=ERR4",
                .success(.response(.get(.failure(.init(pjLinkClass: .one, command: .productName, code: .projectorFailure))))),
                false
            ),
        ]
        try run(testCases)
    }

    @Test
    func otherInformationRequest() throws {
        let testCases: [TestCase] = [
            .init("%1INFO ?", .success(.request(.get(.otherInformation)))),
            .init("%2INFO ?", .failure(.unexpectedGetRequest(.two, .otherInformation, ""))),
            .init("%3INFO ?", .failure(.invalidClass("3"))),
            .init("%1INFO ?XTRA",  .failure(.unexpectedGetRequest(.one, .otherInformation, "XTRA"))),
        ]
        try run(testCases)
    }

    @Test
    func otherInformationResponse() throws {
        let testCases: [TestCase] = [
            .init(
                "%1INFO=foo",
                .success(.response(.get(.success(.otherInformation(.init(value: "foo"))))))
            ),
            .init(
                "%2INFO=foo",
                .failure(.unexpectedGetResponse(.two, .otherInformation))
            ),
            .init(
                "%3INFO=foo",
                .failure(.invalidClass("3"))
            ),
            .init(
                "%1INFO=012345678901234567890123456789012", // Length 33
                .failure(.stringExceedsMaximumLength(33, 32))
            ),
            .init(
                "%1INFO=Name\tWith\tTab", // Contains character lower than legal bounds
                .failure(.characterOutOfValidBounds(9, 32...126))
            ),
            .init(
                "%1INFO=Name With Illegal Character: ≥", // Contains character higher than legal bounds
                .failure(.characterOutOfValidBounds(226, 32...126))
            ),
            .init(
                "%1INFO=ERR1",
                .success(.response(.set(.init(pjlinkClass: .one, command: .otherInformation, code: .undefinedCommand))))
            ),
            .init(
                "%1INFO=ERR1",
                .success(.response(.set(.init(pjlinkClass: .one, command: .otherInformation, code: .undefinedCommand)))),
                true
            ),
            .init(
                "%1INFO=ERR1",
                .success(.response(.get(.failure(.init(pjLinkClass: .one, command: .otherInformation, code: .undefinedCommand))))),
                false
            ),
            .init(
                "%1INFO=ERR2",
                .success(.response(.set(.init(pjlinkClass: .one, command: .otherInformation, code: .outOfParameter))))
            ),
            .init(
                "%1INFO=ERR2",
                .success(.response(.set(.init(pjlinkClass: .one, command: .otherInformation, code: .outOfParameter)))),
                true
            ),
            .init(
                "%1INFO=ERR2",
                .success(.response(.get(.failure(.init(pjLinkClass: .one, command: .otherInformation, code: .outOfParameter))))),
                false
            ),
            .init(
                "%1INFO=ERR3",
                .success(.response(.set(.init(pjlinkClass: .one, command: .otherInformation, code: .unavailableTime))))
            ),
            .init(
                "%1INFO=ERR3",
                .success(.response(.set(.init(pjlinkClass: .one, command: .otherInformation, code: .unavailableTime)))),
                true
            ),
            .init(
                "%1INFO=ERR3",
                .success(.response(.get(.failure(.init(pjLinkClass: .one, command: .otherInformation, code: .unavailableTime))))),
                false
            ),
            .init(
                "%1INFO=ERR4",
                .success(.response(.set(.init(pjlinkClass: .one, command: .otherInformation, code: .projectorFailure))))
            ),
            .init(
                "%1INFO=ERR4",
                .success(.response(.set(.init(pjlinkClass: .one, command: .otherInformation, code: .projectorFailure)))),
                true
            ),
            .init(
                "%1INFO=ERR4",
                .success(.response(.get(.failure(.init(pjLinkClass: .one, command: .otherInformation, code: .projectorFailure))))),
                false
            ),
        ]
        try run(testCases)
    }

    @Test
    func classRequest() throws {
        let testCases: [TestCase] = [
            .init("%1CLSS ?", .success(.request(.get(.projectorClass)))),
            .init("%2CLSS ?", .failure(.unexpectedGetRequest(.two, .projectorClass, ""))),
            .init("%3CLSS ?", .failure(.invalidClass("3"))),
            .init("%1CLSS ?XTRA",  .failure(.unexpectedGetRequest(.one, .projectorClass, "XTRA"))),
        ]
        try run(testCases)
    }

    @Test
    func classResponse() throws {
        let testCases: [TestCase] = [
            .init(
                "%1CLSS=1",
                .success(.response(.get(.success(.projectorClass(.one)))))
            ),
            .init(
                "%1CLSS=2",
                .success(.response(.get(.success(.projectorClass(.two)))))
            ),
            .init(
                "%2CLSS=1",
                .failure(.unexpectedGetResponse(.two, .projectorClass))
            ),
            .init(
                "%3CLSS=3",
                .failure(.invalidClass("3"))
            ),
            .init(
                "%1CLSS=ERR1",
                .success(.response(.set(.init(pjlinkClass: .one, command: .projectorClass, code: .undefinedCommand))))
            ),
            .init(
                "%1CLSS=ERR1",
                .success(.response(.set(.init(pjlinkClass: .one, command: .projectorClass, code: .undefinedCommand)))),
                true
            ),
            .init(
                "%1CLSS=ERR1",
                .success(.response(.get(.failure(.init(pjLinkClass: .one, command: .projectorClass, code: .undefinedCommand))))),
                false
            ),
            .init(
                "%1CLSS=ERR2",
                .success(.response(.set(.init(pjlinkClass: .one, command: .projectorClass, code: .outOfParameter))))
            ),
            .init(
                "%1CLSS=ERR2",
                .success(.response(.set(.init(pjlinkClass: .one, command: .projectorClass, code: .outOfParameter)))),
                true
            ),
            .init(
                "%1CLSS=ERR2",
                .success(.response(.get(.failure(.init(pjLinkClass: .one, command: .projectorClass, code: .outOfParameter))))),
                false
            ),
            .init(
                "%1CLSS=ERR3",
                .success(.response(.set(.init(pjlinkClass: .one, command: .projectorClass, code: .unavailableTime))))
            ),
            .init(
                "%1CLSS=ERR3",
                .success(.response(.set(.init(pjlinkClass: .one, command: .projectorClass, code: .unavailableTime)))),
                true
            ),
            .init(
                "%1CLSS=ERR3",
                .success(.response(.get(.failure(.init(pjLinkClass: .one, command: .projectorClass, code: .unavailableTime))))),
                false
            ),
            .init(
                "%1CLSS=ERR4",
                .success(.response(.set(.init(pjlinkClass: .one, command: .projectorClass, code: .projectorFailure))))
            ),
            .init(
                "%1CLSS=ERR4",
                .success(.response(.set(.init(pjlinkClass: .one, command: .projectorClass, code: .projectorFailure)))),
                true
            ),
            .init(
                "%1CLSS=ERR4",
                .success(.response(.get(.failure(.init(pjLinkClass: .one, command: .projectorClass, code: .projectorFailure))))),
                false
            ),
        ]
        try run(testCases)
    }

    @Test
    func serialNumberRequest() throws {
        let testCases: [TestCase] = [
            .init("%1SNUM ?", .failure(.unexpectedGetRequest(.one, .serialNumber, ""))),
            .init("%2SNUM ?", .success(.request(.get(.serialNumber)))),
            .init("%3SNUM ?", .failure(.invalidClass("3"))),
            .init("%2SNUM ?XTRA",  .failure(.unexpectedGetRequest(.two, .serialNumber, "XTRA"))),
        ]
        try run(testCases)
    }

    @Test
    func serialNumberResponse() throws {
        let testCases: [TestCase] = [
            .init(
                "%2SNUM=foo",
                .success(.response(.get(.success(.serialNumber(.init(value: "foo"))))))
            ),
            .init(
                "%1SNUM=foo",
                .failure(.unexpectedGetResponse(.one, .serialNumber))
            ),
            .init(
                "%3SNUM=foo",
                .failure(.invalidClass("3"))
            ),
            .init(
                "%2SNUM=012345678901234567890123456789012", // Length 33
                .failure(.stringExceedsMaximumLength(33, 32))
            ),
            .init(
                "%2SNUM=Name\tWith\tTab", // Contains character lower than legal bounds
                .failure(.characterOutOfValidBounds(9, 32...126))
            ),
            .init(
                "%2SNUM=Name With Illegal Character: ≥", // Contains character higher than legal bounds
                .failure(.characterOutOfValidBounds(226, 32...126))
            ),
            .init(
                "%2SNUM=ERR1",
                .success(.response(.set(.init(pjlinkClass: .two, command: .serialNumber, code: .undefinedCommand))))
            ),
            .init(
                "%2SNUM=ERR1",
                .success(.response(.set(.init(pjlinkClass: .two, command: .serialNumber, code: .undefinedCommand)))),
                true
            ),
            .init(
                "%2SNUM=ERR1",
                .success(.response(.get(.failure(.init(pjLinkClass: .two, command: .serialNumber, code: .undefinedCommand))))),
                false
            ),
            .init(
                "%2SNUM=ERR2",
                .success(.response(.set(.init(pjlinkClass: .two, command: .serialNumber, code: .outOfParameter))))
            ),
            .init(
                "%2SNUM=ERR2",
                .success(.response(.set(.init(pjlinkClass: .two, command: .serialNumber, code: .outOfParameter)))),
                true
            ),
            .init(
                "%2SNUM=ERR2",
                .success(.response(.get(.failure(.init(pjLinkClass: .two, command: .serialNumber, code: .outOfParameter))))),
                false
            ),
            .init(
                "%2SNUM=ERR3",
                .success(.response(.set(.init(pjlinkClass: .two, command: .serialNumber, code: .unavailableTime))))
            ),
            .init(
                "%2SNUM=ERR3",
                .success(.response(.set(.init(pjlinkClass: .two, command: .serialNumber, code: .unavailableTime)))),
                true
            ),
            .init(
                "%2SNUM=ERR3",
                .success(.response(.get(.failure(.init(pjLinkClass: .two, command: .serialNumber, code: .unavailableTime))))),
                false
            ),
            .init(
                "%2SNUM=ERR4",
                .success(.response(.set(.init(pjlinkClass: .two, command: .serialNumber, code: .projectorFailure))))
            ),
            .init(
                "%2SNUM=ERR4",
                .success(.response(.set(.init(pjlinkClass: .two, command: .serialNumber, code: .projectorFailure)))),
                true
            ),
            .init(
                "%2SNUM=ERR4",
                .success(.response(.get(.failure(.init(pjLinkClass: .two, command: .serialNumber, code: .projectorFailure))))),
                false
            ),
        ]
        try run(testCases)
    }

    @Test
    func softwareVersionRequest() throws {
        let testCases: [TestCase] = [
            .init("%1SVER ?", .failure(.unexpectedGetRequest(.one, .softwareVersion, ""))),
            .init("%2SVER ?", .success(.request(.get(.softwareVersion)))),
            .init("%3SVER ?", .failure(.invalidClass("3"))),
            .init("%2SVER ?XTRA",  .failure(.unexpectedGetRequest(.two, .softwareVersion, "XTRA"))),
        ]
        try run(testCases)
    }

    @Test
    func softwareVersionResponse() throws {
        let testCases: [TestCase] = [
            .init(
                "%2SVER=foo",
                .success(.response(.get(.success(.softwareVersion(.init(value: "foo"))))))
            ),
            .init(
                "%1SVER=foo",
                .failure(.unexpectedGetResponse(.one, .softwareVersion))
            ),
            .init(
                "%3SVER=foo",
                .failure(.invalidClass("3"))
            ),
            .init(
                "%2SVER=012345678901234567890123456789012", // Length 33
                .failure(.stringExceedsMaximumLength(33, 32))
            ),
            .init(
                "%2SVER=Name\tWith\tTab", // Contains character lower than legal bounds
                .failure(.characterOutOfValidBounds(9, 32...126))
            ),
            .init(
                "%2SVER=Name With Illegal Character: ≥", // Contains character higher than legal bounds
                .failure(.characterOutOfValidBounds(226, 32...126))
            ),
            .init(
                "%2SVER=ERR1",
                .success(.response(.set(.init(pjlinkClass: .two, command: .softwareVersion, code: .undefinedCommand))))
            ),
            .init(
                "%2SVER=ERR1",
                .success(.response(.set(.init(pjlinkClass: .two, command: .softwareVersion, code: .undefinedCommand)))),
                true
            ),
            .init(
                "%2SVER=ERR1",
                .success(.response(.get(.failure(.init(pjLinkClass: .two, command: .softwareVersion, code: .undefinedCommand))))),
                false
            ),
            .init(
                "%2SVER=ERR2",
                .success(.response(.set(.init(pjlinkClass: .two, command: .softwareVersion, code: .outOfParameter))))
            ),
            .init(
                "%2SVER=ERR2",
                .success(.response(.set(.init(pjlinkClass: .two, command: .softwareVersion, code: .outOfParameter)))),
                true
            ),
            .init(
                "%2SVER=ERR2",
                .success(.response(.get(.failure(.init(pjLinkClass: .two, command: .softwareVersion, code: .outOfParameter))))),
                false
            ),
            .init(
                "%2SVER=ERR3",
                .success(.response(.set(.init(pjlinkClass: .two, command: .softwareVersion, code: .unavailableTime))))
            ),
            .init(
                "%2SVER=ERR3",
                .success(.response(.set(.init(pjlinkClass: .two, command: .softwareVersion, code: .unavailableTime)))),
                true
            ),
            .init(
                "%2SVER=ERR3",
                .success(.response(.get(.failure(.init(pjLinkClass: .two, command: .softwareVersion, code: .unavailableTime))))),
                false
            ),
            .init(
                "%2SVER=ERR4",
                .success(.response(.set(.init(pjlinkClass: .two, command: .softwareVersion, code: .projectorFailure))))
            ),
            .init(
                "%2SVER=ERR4",
                .success(.response(.set(.init(pjlinkClass: .two, command: .softwareVersion, code: .projectorFailure)))),
                true
            ),
            .init(
                "%2SVER=ERR4",
                .success(.response(.get(.failure(.init(pjLinkClass: .two, command: .softwareVersion, code: .projectorFailure))))),
                false
            ),
        ]
        try run(testCases)
    }

    @Test
    func inputTerminalNameRequest() throws {
        var testCases: [TestCase] = [
            .init("%1INNM ?11", .failure(.unexpectedGetRequest(.one, .inputTerminalName, "11"))),
            .init("%3INNM ?11", .failure(.invalidClass("3"))),
            .init("%2INNM ?71", .failure(.invalidClass2Input("7"))),
            .init("%2INNM ?60", .failure(.invalidClass2InputChannel("0"))),
        ]
        PJLink.InputSwitchClass2.allCases.forEach { inputSwitch in
            testCases.append(
                .init(
                    "%2INNM ?\(inputSwitch.description)",
                    .success(.request(.get(.inputTerminalName(inputSwitch))))
                )
            )
        }
        try run(testCases)
    }

    @Test
    func inputTerminalNameResponse() throws {
        let testCases: [TestCase] = [
            .init(
                "%2INNM=foo",
                .success(.response(.get(.success(.inputTerminalName(.init(value: "foo"))))))
            ),
            .init(
                "%1INNM=foo",
                .failure(.unexpectedGetResponse(.one, .inputTerminalName))
            ),
            .init(
                "%3INNM=foo",
                .failure(.invalidClass("3"))
            ),
            .init(
                "%2INNM=012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678",
                .failure(.stringExceedsMaximumLength(129, 128))
            ),
            .init(
                "%2INNM=Name\tWith\tTab", // Contains character lower than legal bounds
                .failure(.characterOutOfValidBounds(9, 32...255))
            ),
            .init(
                "%2INNM=ERR1",
                .success(.response(.set(.init(pjlinkClass: .two, command: .inputTerminalName, code: .undefinedCommand))))
            ),
            .init(
                "%2INNM=ERR1",
                .success(.response(.set(.init(pjlinkClass: .two, command: .inputTerminalName, code: .undefinedCommand)))),
                true
            ),
            .init(
                "%2INNM=ERR1",
                .success(.response(.get(.failure(.init(pjLinkClass: .two, command: .inputTerminalName, code: .undefinedCommand))))),
                false
            ),
            .init(
                "%2INNM=ERR2",
                .success(.response(.set(.init(pjlinkClass: .two, command: .inputTerminalName, code: .outOfParameter))))
            ),
            .init(
                "%2INNM=ERR2",
                .success(.response(.set(.init(pjlinkClass: .two, command: .inputTerminalName, code: .outOfParameter)))),
                true
            ),
            .init(
                "%2INNM=ERR2",
                .success(.response(.get(.failure(.init(pjLinkClass: .two, command: .inputTerminalName, code: .outOfParameter))))),
                false
            ),
            .init(
                "%2INNM=ERR3",
                .success(.response(.set(.init(pjlinkClass: .two, command: .inputTerminalName, code: .unavailableTime))))
            ),
            .init(
                "%2INNM=ERR3",
                .success(.response(.set(.init(pjlinkClass: .two, command: .inputTerminalName, code: .unavailableTime)))),
                true
            ),
            .init(
                "%2INNM=ERR3",
                .success(.response(.get(.failure(.init(pjLinkClass: .two, command: .inputTerminalName, code: .unavailableTime))))),
                false
            ),
            .init(
                "%2INNM=ERR4",
                .success(.response(.set(.init(pjlinkClass: .two, command: .inputTerminalName, code: .projectorFailure))))
            ),
            .init(
                "%2INNM=ERR4",
                .success(.response(.set(.init(pjlinkClass: .two, command: .inputTerminalName, code: .projectorFailure)))),
                true
            ),
            .init(
                "%2INNM=ERR4",
                .success(.response(.get(.failure(.init(pjLinkClass: .two, command: .inputTerminalName, code: .projectorFailure))))),
                false
            ),
        ]
        try run(testCases)
    }

    @Test
    func inputResolutionRequest() throws {
        let testCases: [TestCase] = [
            .init("%1IRES ?", .failure(.unexpectedGetRequest(.one, .inputResolution, ""))),
            .init("%2IRES ?", .success(.request(.get(.inputResolution)))),
            .init("%3IRES ?", .failure(.invalidClass("3"))),
            .init("%2IRES ?XTRA",  .failure(.unexpectedGetRequest(.two, .inputResolution, "XTRA"))),
        ]
        try run(testCases)
    }

    @Test
    func inputResolutionResponse() throws {
        let testCases: [TestCase] = [
            .init(
                "%2IRES=1920x1080",
                .success(.response(.get(.success(.inputResolution(.ok(.init(horizontal: 1920, vertical: 1080)))))))
            ),
            .init(
                "%2IRES=-",
                .success(.response(.get(.success(.inputResolution(.noSignal)))))
            ),
            .init(
                "%2IRES=*",
                .success(.response(.get(.success(.inputResolution(.unknownSignal)))))
            ),
            .init(
                "%1IRES=1920x1080",
                .failure(.unexpectedGetResponse(.one, .inputResolution))
            ),
            .init(
                "%3IRES=1920x1080",
                .failure(.invalidClass("3"))
            ),
            .init(
                "%2IRES=1920x1080x640",
                .failure(.invalidResolution("1920x1080x640"))
            ),
            .init(
                "%2IRES=1920xfoo",
                .failure(.invalidResolution("1920xfoo"))
            ),
            .init(
                "%2IRES=ERR1",
                .success(.response(.set(.init(pjlinkClass: .two, command: .inputResolution, code: .undefinedCommand))))
            ),
            .init(
                "%2IRES=ERR1",
                .success(.response(.set(.init(pjlinkClass: .two, command: .inputResolution, code: .undefinedCommand)))),
                true
            ),
            .init(
                "%2IRES=ERR1",
                .success(.response(.get(.failure(.init(pjLinkClass: .two, command: .inputResolution, code: .undefinedCommand))))),
                false
            ),
            .init(
                "%2IRES=ERR2",
                .success(.response(.set(.init(pjlinkClass: .two, command: .inputResolution, code: .outOfParameter))))
            ),
            .init(
                "%2IRES=ERR2",
                .success(.response(.set(.init(pjlinkClass: .two, command: .inputResolution, code: .outOfParameter)))),
                true
            ),
            .init(
                "%2IRES=ERR2",
                .success(.response(.get(.failure(.init(pjLinkClass: .two, command: .inputResolution, code: .outOfParameter))))),
                false
            ),
            .init(
                "%2IRES=ERR3",
                .success(.response(.set(.init(pjlinkClass: .two, command: .inputResolution, code: .unavailableTime))))
            ),
            .init(
                "%2IRES=ERR3",
                .success(.response(.set(.init(pjlinkClass: .two, command: .inputResolution, code: .unavailableTime)))),
                true
            ),
            .init(
                "%2IRES=ERR3",
                .success(.response(.get(.failure(.init(pjLinkClass: .two, command: .inputResolution, code: .unavailableTime))))),
                false
            ),
            .init(
                "%2IRES=ERR4",
                .success(.response(.set(.init(pjlinkClass: .two, command: .inputResolution, code: .projectorFailure))))
            ),
            .init(
                "%2IRES=ERR4",
                .success(.response(.set(.init(pjlinkClass: .two, command: .inputResolution, code: .projectorFailure)))),
                true
            ),
            .init(
                "%2IRES=ERR4",
                .success(.response(.get(.failure(.init(pjLinkClass: .two, command: .inputResolution, code: .projectorFailure))))),
                false
            ),
        ]
        try run(testCases)
    }

    @Test
    func recommendedResolutionRequest() throws {
        let testCases: [TestCase] = [
            .init("%1RRES ?", .failure(.unexpectedGetRequest(.one, .recommendedResolution, ""))),
            .init("%2RRES ?", .success(.request(.get(.recommendedResolution)))),
            .init("%3RRES ?", .failure(.invalidClass("3"))),
            .init("%2RRES ?XTRA",  .failure(.unexpectedGetRequest(.two, .recommendedResolution, "XTRA"))),
        ]
        try run(testCases)
    }

    @Test
    func recommendedResolutionResponse() throws {
        let testCases: [TestCase] = [
            .init(
                "%2RRES=1920x1080",
                .success(.response(.get(.success(.recommendedResolution(.init(horizontal: 1920, vertical: 1080))))))
            ),
            .init(
                "%1RRES=1920x1080",
                .failure(.unexpectedGetResponse(.one, .recommendedResolution))
            ),
            .init(
                "%3RRES=1920x1080",
                .failure(.invalidClass("3"))
            ),
            .init(
                "%2RRES=1920x1080x640",
                .failure(.invalidResolution("1920x1080x640"))
            ),
            .init(
                "%2RRES=1920xfoo",
                .failure(.invalidResolution("1920xfoo"))
            ),
            .init(
                "%2RRES=ERR1",
                .success(.response(.set(.init(pjlinkClass: .two, command: .recommendedResolution, code: .undefinedCommand))))
            ),
            .init(
                "%2RRES=ERR1",
                .success(.response(.set(.init(pjlinkClass: .two, command: .recommendedResolution, code: .undefinedCommand)))),
                true
            ),
            .init(
                "%2RRES=ERR1",
                .success(.response(.get(.failure(.init(pjLinkClass: .two, command: .recommendedResolution, code: .undefinedCommand))))),
                false
            ),
            .init(
                "%2RRES=ERR2",
                .success(.response(.set(.init(pjlinkClass: .two, command: .recommendedResolution, code: .outOfParameter))))
            ),
            .init(
                "%2RRES=ERR2",
                .success(.response(.set(.init(pjlinkClass: .two, command: .recommendedResolution, code: .outOfParameter)))),
                true
            ),
            .init(
                "%2RRES=ERR2",
                .success(.response(.get(.failure(.init(pjLinkClass: .two, command: .recommendedResolution, code: .outOfParameter))))),
                false
            ),
            .init(
                "%2RRES=ERR3",
                .success(.response(.set(.init(pjlinkClass: .two, command: .recommendedResolution, code: .unavailableTime))))
            ),
            .init(
                "%2RRES=ERR3",
                .success(.response(.set(.init(pjlinkClass: .two, command: .recommendedResolution, code: .unavailableTime)))),
                true
            ),
            .init(
                "%2RRES=ERR3",
                .success(.response(.get(.failure(.init(pjLinkClass: .two, command: .recommendedResolution, code: .unavailableTime))))),
                false
            ),
            .init(
                "%2RRES=ERR4",
                .success(.response(.set(.init(pjlinkClass: .two, command: .recommendedResolution, code: .projectorFailure))))
            ),
            .init(
                "%2RRES=ERR4",
                .success(.response(.set(.init(pjlinkClass: .two, command: .recommendedResolution, code: .projectorFailure)))),
                true
            ),
            .init(
                "%2RRES=ERR4",
                .success(.response(.get(.failure(.init(pjLinkClass: .two, command: .recommendedResolution, code: .projectorFailure))))),
                false
            ),
        ]
        try run(testCases)
    }

    @Test
    func filterUsageTimeRequest() throws {
        let testCases: [TestCase] = [
            .init("%1FILT ?", .failure(.unexpectedGetRequest(.one, .filterUsageTime, ""))),
            .init("%2FILT ?", .success(.request(.get(.filterUsageTime)))),
            .init("%3FILT ?", .failure(.invalidClass("3"))),
            .init("%2FILT ?XTRA",  .failure(.unexpectedGetRequest(.two, .filterUsageTime, "XTRA"))),
        ]
        try run(testCases)
    }

    @Test
    func filterUsageTimeResponse() throws {
        let testCases: [TestCase] = [
            .init(
                "%2FILT=12345",
                .success(.response(.get(.success(.filterUsageTime(.init(value: 12345))))))
            ),
            .init(
                "%1FILT=12345",
                .failure(.unexpectedGetResponse(.one, .filterUsageTime))
            ),
            .init(
                "%3FILT=12345",
                .failure(.invalidClass("3"))
            ),
            .init(
                "%2FILT=foo",
                .failure(.invalidFilterUsageTime("foo"))
            ),
            .init(
                "%2FILT=100000",
                .failure(.filterUsageTimeOutOfRange(100_000))
            ),
            .init(
                "%2FILT=ERR1",
                .success(.response(.set(.init(pjlinkClass: .two, command: .filterUsageTime, code: .undefinedCommand))))
            ),
            .init(
                "%2FILT=ERR1",
                .success(.response(.set(.init(pjlinkClass: .two, command: .filterUsageTime, code: .undefinedCommand)))),
                true
            ),
            .init(
                "%2FILT=ERR1",
                .success(.response(.get(.failure(.init(pjLinkClass: .two, command: .filterUsageTime, code: .undefinedCommand))))),
                false
            ),
            .init(
                "%2FILT=ERR2",
                .success(.response(.set(.init(pjlinkClass: .two, command: .filterUsageTime, code: .outOfParameter))))
            ),
            .init(
                "%2FILT=ERR2",
                .success(.response(.set(.init(pjlinkClass: .two, command: .filterUsageTime, code: .outOfParameter)))),
                true
            ),
            .init(
                "%2FILT=ERR2",
                .success(.response(.get(.failure(.init(pjLinkClass: .two, command: .filterUsageTime, code: .outOfParameter))))),
                false
            ),
            .init(
                "%2FILT=ERR3",
                .success(.response(.set(.init(pjlinkClass: .two, command: .filterUsageTime, code: .unavailableTime))))
            ),
            .init(
                "%2FILT=ERR3",
                .success(.response(.set(.init(pjlinkClass: .two, command: .filterUsageTime, code: .unavailableTime)))),
                true
            ),
            .init(
                "%2FILT=ERR3",
                .success(.response(.get(.failure(.init(pjLinkClass: .two, command: .filterUsageTime, code: .unavailableTime))))),
                false
            ),
            .init(
                "%2FILT=ERR4",
                .success(.response(.set(.init(pjlinkClass: .two, command: .filterUsageTime, code: .projectorFailure))))
            ),
            .init(
                "%2FILT=ERR4",
                .success(.response(.set(.init(pjlinkClass: .two, command: .filterUsageTime, code: .projectorFailure)))),
                true
            ),
            .init(
                "%2FILT=ERR4",
                .success(.response(.get(.failure(.init(pjLinkClass: .two, command: .filterUsageTime, code: .projectorFailure))))),
                false
            ),
        ]
        try run(testCases)
    }

    @Test
    func lampReplacementModelNumberRequest() throws {
        let testCases: [TestCase] = [
            .init("%1RLMP ?", .failure(.unexpectedGetRequest(.one, .lampReplacementModelNumber, ""))),
            .init("%2RLMP ?", .success(.request(.get(.lampReplacementModelNumber)))),
            .init("%3RLMP ?", .failure(.invalidClass("3"))),
            .init("%2RLMP ?XTRA",  .failure(.unexpectedGetRequest(.two, .lampReplacementModelNumber, "XTRA"))),
        ]
        try run(testCases)
    }

    @Test
    func lampReplacementModelNumberResponse() throws {
        let testCases: [TestCase] = [
            .init(
                "%2RLMP=foo",
                .success(.response(.get(.success(.lampReplacementModelNumber(.init(value: "foo"))))))
            ),
            .init(
                "%2RLMP=",
                .success(.response(.get(.success(.lampReplacementModelNumber(.init(value: ""))))))
            ),
            .init(
                "%1RLMP=foo",
                .failure(.unexpectedGetResponse(.one, .lampReplacementModelNumber))
            ),
            .init(
                "%3RLMP=foo",
                .failure(.invalidClass("3"))
            ),
            .init(
                "%2RLMP=012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678",
                .failure(.stringExceedsMaximumLength(129, 128))
            ),
            .init(
                "%2RLMP=Name\tWith\tTab", // Contains character lower than legal bounds
                .failure(.characterOutOfValidBounds(9, 32...126))
            ),
            .init(
                "%2RLMP=Name With Illegal Character: ≥", // Contains character higher than legal bounds
                .failure(.characterOutOfValidBounds(226, 32...126))
            ),
            .init(
                "%2RLMP=ERR1",
                .success(.response(.set(.init(pjlinkClass: .two, command: .lampReplacementModelNumber, code: .undefinedCommand))))
            ),
            .init(
                "%2RLMP=ERR1",
                .success(.response(.set(.init(pjlinkClass: .two, command: .lampReplacementModelNumber, code: .undefinedCommand)))),
                true
            ),
            .init(
                "%2RLMP=ERR1",
                .success(.response(.get(.failure(.init(pjLinkClass: .two, command: .lampReplacementModelNumber, code: .undefinedCommand))))),
                false
            ),
            .init(
                "%2RLMP=ERR2",
                .success(.response(.set(.init(pjlinkClass: .two, command: .lampReplacementModelNumber, code: .outOfParameter))))
            ),
            .init(
                "%2RLMP=ERR2",
                .success(.response(.set(.init(pjlinkClass: .two, command: .lampReplacementModelNumber, code: .outOfParameter)))),
                true
            ),
            .init(
                "%2RLMP=ERR2",
                .success(.response(.get(.failure(.init(pjLinkClass: .two, command: .lampReplacementModelNumber, code: .outOfParameter))))),
                false
            ),
            .init(
                "%2RLMP=ERR3",
                .success(.response(.set(.init(pjlinkClass: .two, command: .lampReplacementModelNumber, code: .unavailableTime))))
            ),
            .init(
                "%2RLMP=ERR3",
                .success(.response(.set(.init(pjlinkClass: .two, command: .lampReplacementModelNumber, code: .unavailableTime)))),
                true
            ),
            .init(
                "%2RLMP=ERR3",
                .success(.response(.get(.failure(.init(pjLinkClass: .two, command: .lampReplacementModelNumber, code: .unavailableTime))))),
                false
            ),
            .init(
                "%2RLMP=ERR4",
                .success(.response(.set(.init(pjlinkClass: .two, command: .lampReplacementModelNumber, code: .projectorFailure))))
            ),
            .init(
                "%2RLMP=ERR4",
                .success(.response(.set(.init(pjlinkClass: .two, command: .lampReplacementModelNumber, code: .projectorFailure)))),
                true
            ),
            .init(
                "%2RLMP=ERR4",
                .success(.response(.get(.failure(.init(pjLinkClass: .two, command: .lampReplacementModelNumber, code: .projectorFailure))))),
                false
            ),
        ]
        try run(testCases)
    }

    @Test
    func filterReplacementModelNumberRequest() throws {
        let testCases: [TestCase] = [
            .init("%1RFIL ?", .failure(.unexpectedGetRequest(.one, .filterReplacementModelNumber, ""))),
            .init("%2RFIL ?", .success(.request(.get(.filterReplacementModelNumber)))),
            .init("%3RFIL ?", .failure(.invalidClass("3"))),
            .init("%2RFIL ?XTRA",  .failure(.unexpectedGetRequest(.two, .filterReplacementModelNumber, "XTRA"))),
        ]
        try run(testCases)
    }

    @Test
    func filterReplacementModelNumberResponse() throws {
        let testCases: [TestCase] = [
            .init(
                "%2RFIL=foo",
                .success(.response(.get(.success(.filterReplacementModelNumber(.init(value: "foo"))))))
            ),
            .init(
                "%2RFIL=",
                .success(.response(.get(.success(.filterReplacementModelNumber(.init(value: ""))))))
            ),
            .init(
                "%1RFIL=foo",
                .failure(.unexpectedGetResponse(.one, .filterReplacementModelNumber))
            ),
            .init(
                "%3RFIL=foo",
                .failure(.invalidClass("3"))
            ),
            .init(
                "%2RFIL=012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678",
                .failure(.stringExceedsMaximumLength(129, 128))
            ),
            .init(
                "%2RFIL=Name\tWith\tTab", // Contains character lower than legal bounds
                .failure(.characterOutOfValidBounds(9, 32...126))
            ),
            .init(
                "%2RFIL=Name With Illegal Character: ≥", // Contains character higher than legal bounds
                .failure(.characterOutOfValidBounds(226, 32...126))
            ),
            .init(
                "%2RFIL=ERR1",
                .success(.response(.set(.init(pjlinkClass: .two, command: .filterReplacementModelNumber, code: .undefinedCommand))))
            ),
            .init(
                "%2RFIL=ERR1",
                .success(.response(.set(.init(pjlinkClass: .two, command: .filterReplacementModelNumber, code: .undefinedCommand)))),
                true
            ),
            .init(
                "%2RFIL=ERR1",
                .success(.response(.get(.failure(.init(pjLinkClass: .two, command: .filterReplacementModelNumber, code: .undefinedCommand))))),
                false
            ),
            .init(
                "%2RFIL=ERR2",
                .success(.response(.set(.init(pjlinkClass: .two, command: .filterReplacementModelNumber, code: .outOfParameter))))
            ),
            .init(
                "%2RFIL=ERR2",
                .success(.response(.set(.init(pjlinkClass: .two, command: .filterReplacementModelNumber, code: .outOfParameter)))),
                true
            ),
            .init(
                "%2RFIL=ERR2",
                .success(.response(.get(.failure(.init(pjLinkClass: .two, command: .filterReplacementModelNumber, code: .outOfParameter))))),
                false
            ),
            .init(
                "%2RFIL=ERR3",
                .success(.response(.set(.init(pjlinkClass: .two, command: .filterReplacementModelNumber, code: .unavailableTime))))
            ),
            .init(
                "%2RFIL=ERR3",
                .success(.response(.set(.init(pjlinkClass: .two, command: .filterReplacementModelNumber, code: .unavailableTime)))),
                true
            ),
            .init(
                "%2RFIL=ERR3",
                .success(.response(.get(.failure(.init(pjLinkClass: .two, command: .filterReplacementModelNumber, code: .unavailableTime))))),
                false
            ),
            .init(
                "%2RFIL=ERR4",
                .success(.response(.set(.init(pjlinkClass: .two, command: .filterReplacementModelNumber, code: .projectorFailure))))
            ),
            .init(
                "%2RFIL=ERR4",
                .success(.response(.set(.init(pjlinkClass: .two, command: .filterReplacementModelNumber, code: .projectorFailure)))),
                true
            ),
            .init(
                "%2RFIL=ERR4",
                .success(.response(.get(.failure(.init(pjLinkClass: .two, command: .filterReplacementModelNumber, code: .projectorFailure))))),
                false
            ),
        ]
        try run(testCases)
    }

    @Test
    func speakerVolumeAdjustmentRequest() throws {
        let testCases: [TestCase] = [
            .init("%1SVOL 0", .failure(.unexpectedSetRequest(.one, .speakerVolume))),
            .init("%2SVOL 0", .success(.request(.set(.speakerVolume(.decrease))))),
            .init("%2SVOL 1", .success(.request(.set(.speakerVolume(.increase))))),
            .init("%3SVOL 1", .failure(.invalidClass("3"))),
            .init("%2SVOL 2", .failure(.invalidVolume("2"))),
        ]
        try run(testCases)
    }

    @Test
    func speakerVolumeAdjustmentResponse() throws {
        let testCases: [TestCase] = [
            .init(
                "%2SVOL=OK",
                .success(.response(.set(.init(pjlinkClass: .two, command: .speakerVolume, code: .ok))))
            ),
            .init(
                "%2SVOL=OK",
                .success(.response(.set(.init(pjlinkClass: .two, command: .speakerVolume, code: .ok)))),
                true
            ),
            .init(
                "%2SVOL=OK",
                .failure(.unexpectedGetResponse(.two, .speakerVolume)),
                false
            ),
            .init(
                "%2SVOL=ERR1",
                .success(.response(.set(.init(pjlinkClass: .two, command: .speakerVolume, code: .undefinedCommand))))
            ),
            .init(
                "%2SVOL=ERR1",
                .success(.response(.set(.init(pjlinkClass: .two, command: .speakerVolume, code: .undefinedCommand)))),
                true
            ),
            .init(
                "%2SVOL=ERR1",
                .success(.response(.get(.failure(.init(pjLinkClass: .two, command: .speakerVolume, code: .undefinedCommand))))),
                false
            ),
            .init(
                "%2SVOL=ERR2",
                .success(.response(.set(.init(pjlinkClass: .two, command: .speakerVolume, code: .outOfParameter))))
            ),
            .init(
                "%2SVOL=ERR2",
                .success(.response(.set(.init(pjlinkClass: .two, command: .speakerVolume, code: .outOfParameter)))),
                true
            ),
            .init(
                "%2SVOL=ERR2",
                .success(.response(.get(.failure(.init(pjLinkClass: .two, command: .speakerVolume, code: .outOfParameter))))),
                false
            ),
            .init(
                "%2SVOL=ERR3",
                .success(.response(.set(.init(pjlinkClass: .two, command: .speakerVolume, code: .unavailableTime))))
            ),
            .init(
                "%2SVOL=ERR3",
                .success(.response(.set(.init(pjlinkClass: .two, command: .speakerVolume, code: .unavailableTime)))),
                true
            ),
            .init(
                "%2SVOL=ERR3",
                .success(.response(.get(.failure(.init(pjLinkClass: .two, command: .speakerVolume, code: .unavailableTime))))),
                false
            ),
            .init(
                "%2SVOL=ERR4",
                .success(.response(.set(.init(pjlinkClass: .two, command: .speakerVolume, code: .projectorFailure))))
            ),
            .init(
                "%2SVOL=ERR4",
                .success(.response(.set(.init(pjlinkClass: .two, command: .speakerVolume, code: .projectorFailure)))),
                true
            ),
            .init(
                "%2SVOL=ERR4",
                .success(.response(.get(.failure(.init(pjLinkClass: .two, command: .speakerVolume, code: .projectorFailure))))),
                false
            ),
        ]
        try run(testCases)
    }

    @Test
    func microphoneVolumeAdjustmentRequest() throws {
        let testCases: [TestCase] = [
            .init("%1MVOL 0", .failure(.unexpectedSetRequest(.one, .microphoneVolume))),
            .init("%2MVOL 0", .success(.request(.set(.microphoneVolume(.decrease))))),
            .init("%2MVOL 1", .success(.request(.set(.microphoneVolume(.increase))))),
            .init("%3MVOL 1", .failure(.invalidClass("3"))),
            .init("%2MVOL 2", .failure(.invalidVolume("2"))),
        ]
        try run(testCases)
    }

    @Test
    func microphoneVolumeAdjustmentResponse() throws {
        let testCases: [TestCase] = [
            .init(
                "%2MVOL=OK",
                .success(.response(.set(.init(pjlinkClass: .two, command: .microphoneVolume, code: .ok))))
            ),
            .init(
                "%2MVOL=OK",
                .success(.response(.set(.init(pjlinkClass: .two, command: .microphoneVolume, code: .ok)))),
                true
            ),
            .init(
                "%2MVOL=OK",
                .failure(.unexpectedGetResponse(.two, .microphoneVolume)),
                false
            ),
            .init(
                "%2MVOL=ERR1",
                .success(.response(.set(.init(pjlinkClass: .two, command: .microphoneVolume, code: .undefinedCommand))))
            ),
            .init(
                "%2MVOL=ERR1",
                .success(.response(.set(.init(pjlinkClass: .two, command: .microphoneVolume, code: .undefinedCommand)))),
                true
            ),
            .init(
                "%2MVOL=ERR1",
                .success(.response(.get(.failure(.init(pjLinkClass: .two, command: .microphoneVolume, code: .undefinedCommand))))),
                false
            ),
            .init(
                "%2MVOL=ERR2",
                .success(.response(.set(.init(pjlinkClass: .two, command: .microphoneVolume, code: .outOfParameter))))
            ),
            .init(
                "%2MVOL=ERR2",
                .success(.response(.set(.init(pjlinkClass: .two, command: .microphoneVolume, code: .outOfParameter)))),
                true
            ),
            .init(
                "%2MVOL=ERR2",
                .success(.response(.get(.failure(.init(pjLinkClass: .two, command: .microphoneVolume, code: .outOfParameter))))),
                false
            ),
            .init(
                "%2MVOL=ERR3",
                .success(.response(.set(.init(pjlinkClass: .two, command: .microphoneVolume, code: .unavailableTime))))
            ),
            .init(
                "%2MVOL=ERR3",
                .success(.response(.set(.init(pjlinkClass: .two, command: .microphoneVolume, code: .unavailableTime)))),
                true
            ),
            .init(
                "%2MVOL=ERR3",
                .success(.response(.get(.failure(.init(pjLinkClass: .two, command: .microphoneVolume, code: .unavailableTime))))),
                false
            ),
            .init(
                "%2MVOL=ERR4",
                .success(.response(.set(.init(pjlinkClass: .two, command: .microphoneVolume, code: .projectorFailure))))
            ),
            .init(
                "%2MVOL=ERR4",
                .success(.response(.set(.init(pjlinkClass: .two, command: .microphoneVolume, code: .projectorFailure)))),
                true
            ),
            .init(
                "%2MVOL=ERR4",
                .success(.response(.get(.failure(.init(pjLinkClass: .two, command: .microphoneVolume, code: .projectorFailure))))),
                false
            ),
        ]
        try run(testCases)
    }

    @Test
    func freezeRequest() throws {
        let testCases: [TestCase] = [
            .init("%2FREZ ?", .success(.request(.get(.freeze)))),
            .init("%1FREZ ?", .failure(.unexpectedGetRequest(.one, .freeze, ""))),
            .init("%2FREZ ?X", .failure(.unexpectedGetRequest(.two, .freeze, "X"))),
            .init("%2FREZ 1", .success(.request(.set(.freeze(.start))))),
            .init("%2FREZ 0", .success(.request(.set(.freeze(.stop))))),
            .init("%1FREZ 0", .failure(.unexpectedSetRequest(.one, .freeze))),
            .init("%2FREZ x", .failure(.invalidFreeze("x"))),
        ]
        try run(testCases)
    }

    @Test
    func freezeResponse() throws {
        let testCases: [TestCase] = [
            .init("%2FREZ=0", .success(.response(.get(.success(.freeze(.stop)))))),
            .init("%2FREZ=1", .success(.response(.get(.success(.freeze(.start)))))),
            .init("%2FREZ=2", .failure(.invalidFreeze("2"))),
            .init("%1FREZ=0", .failure(.unexpectedGetResponse(.one, .freeze))),
            .init("%2FREZ=OK", .success(.response(.set(.init(pjlinkClass: .two, command: .freeze, code: .ok))))),
            .init("%2FREZ=OK", .success(.response(.set(.init(pjlinkClass: .two, command: .freeze, code: .ok)))), true),
            .init("%2FREZ=OK", .failure(.invalidFreeze("OK")), false),
            .init("%2FREZ=ERR1", .success(.response(.set(.init(pjlinkClass: .two, command: .freeze, code: .undefinedCommand))))),
            .init("%2FREZ=ERR1", .success(.response(.set(.init(pjlinkClass: .two, command: .freeze, code: .undefinedCommand)))), true),
            .init("%2FREZ=ERR1", .success(.response(.get(.failure(.init(pjLinkClass: .two, command: .freeze, code: .undefinedCommand))))), false),
            .init("%2FREZ=ERR2", .success(.response(.set(.init(pjlinkClass: .two, command: .freeze, code: .outOfParameter))))),
            .init("%2FREZ=ERR2", .success(.response(.set(.init(pjlinkClass: .two, command: .freeze, code: .outOfParameter)))), true),
            .init("%2FREZ=ERR2", .success(.response(.get(.failure(.init(pjLinkClass: .two, command: .freeze, code: .outOfParameter))))), false),
            .init("%2FREZ=ERR3", .success(.response(.set(.init(pjlinkClass: .two, command: .freeze, code: .unavailableTime))))),
            .init("%2FREZ=ERR3", .success(.response(.set(.init(pjlinkClass: .two, command: .freeze, code: .unavailableTime)))), true),
            .init("%2FREZ=ERR3", .success(.response(.get(.failure(.init(pjLinkClass: .two, command: .freeze, code: .unavailableTime))))), false),
            .init("%2FREZ=ERR4", .success(.response(.set(.init(pjlinkClass: .two, command: .freeze, code: .projectorFailure))))),
            .init("%2FREZ=ERR4", .success(.response(.set(.init(pjlinkClass: .two, command: .freeze, code: .projectorFailure)))), true),
            .init("%2FREZ=ERR4", .success(.response(.get(.failure(.init(pjLinkClass: .two, command: .freeze, code: .projectorFailure))))), false),
        ]
        try run(testCases)
    }

    private func run(_ testCases: [TestCase]) throws {
        for testCase in testCases {
            let actual: Swift.Result<PJLink.Message, PJLink.Error>
            do {
                actual = .success(try PJLink.Message(testCase.input, isSetResponseHint: testCase.isSetReponseHint))
            } catch let pjlinkError as PJLink.Error {
                actual = .failure(pjlinkError)
            } catch {
                throw error
            }
            #expect(actual == testCase.expected)
        }
    }
}
