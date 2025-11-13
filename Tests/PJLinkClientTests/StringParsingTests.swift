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
            .init("%1POWR=OK", .success(.response(.set(.init(class: .one, command: .power, code: .ok))))),
            .init("%1POWR=OK", .success(.response(.set(.init(class: .one, command: .power, code: .ok)))), true),
            .init("%1POWR=OK", .failure(.invalidPowerStatus("OK")), false),
            .init("%1POWR=ERR1", .success(.response(.set(.init(class: .one, command: .power, code: .undefinedCommand))))),
            .init("%1POWR=ERR1", .success(.response(.set(.init(class: .one, command: .power, code: .undefinedCommand)))), true),
            .init("%1POWR=ERR1", .success(.response(.get(.failure(.init(class: .one, command: .power, code: .undefinedCommand))))), false),
            .init("%1POWR=ERR2", .success(.response(.set(.init(class: .one, command: .power, code: .outOfParameter))))),
            .init("%1POWR=ERR2", .success(.response(.set(.init(class: .one, command: .power, code: .outOfParameter)))), true),
            .init("%1POWR=ERR2", .success(.response(.get(.failure(.init(class: .one, command: .power, code: .outOfParameter))))), false),
            .init("%1POWR=ERR3", .success(.response(.set(.init(class: .one, command: .power, code: .unavailableTime))))),
            .init("%1POWR=ERR3", .success(.response(.set(.init(class: .one, command: .power, code: .unavailableTime)))), true),
            .init("%1POWR=ERR3", .success(.response(.get(.failure(.init(class: .one, command: .power, code: .unavailableTime))))), false),
            .init("%1POWR=ERR4", .success(.response(.set(.init(class: .one, command: .power, code: .projectorFailure))))),
            .init("%1POWR=ERR4", .success(.response(.set(.init(class: .one, command: .power, code: .projectorFailure)))), true),
            .init("%1POWR=ERR4", .success(.response(.get(.failure(.init(class: .one, command: .power, code: .projectorFailure))))), false),
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
                .success(.response(.set(.init(class: .one, command: .inputSwitch, code: .ok))))
            ),
            .init(
                "%1INPT=OK",
                .success(.response(.set(.init(class: .one, command: .inputSwitch, code: .ok)))),
                true
            ),
            .init(
                "%1INPT=OK",
                .failure(.invalidClass1Input("O")),
                false
            ),
            .init(
                "%1INPT=ERR1",
                .success(.response(.set(.init(class: .one, command: .inputSwitch, code: .undefinedCommand))))
            ),
            .init(
                "%1INPT=ERR1",
                .success(.response(.set(.init(class: .one, command: .inputSwitch, code: .undefinedCommand)))),
                true
            ),
            .init(
                "%1INPT=ERR1",
                .success(.response(.get(.failure(.init(class: .one, command: .inputSwitch, code: .undefinedCommand))))),
                false
            ),
            .init(
                "%1INPT=ERR2",
                .success(.response(.set(.init(class: .one, command: .inputSwitch, code: .outOfParameter))))
            ),
            .init(
                "%1INPT=ERR2",
                .success(.response(.set(.init(class: .one, command: .inputSwitch, code: .outOfParameter)))),
                true
            ),
            .init(
                "%1INPT=ERR2",
                .success(.response(.get(.failure(.init(class: .one, command: .inputSwitch, code: .outOfParameter))))),
                false
            ),
            .init(
                "%1INPT=ERR3",
                .success(.response(.set(.init(class: .one, command: .inputSwitch, code: .unavailableTime))))
            ),
            .init(
                "%1INPT=ERR3",
                .success(.response(.set(.init(class: .one, command: .inputSwitch, code: .unavailableTime)))),
                true
            ),
            .init(
                "%1INPT=ERR3",
                .success(.response(.get(.failure(.init(class: .one, command: .inputSwitch, code: .unavailableTime))))),
                false
            ),
            .init(
                "%1INPT=ERR4",
                .success(.response(.set(.init(class: .one, command: .inputSwitch, code: .projectorFailure))))
            ),
            .init(
                "%1INPT=ERR4",
                .success(.response(.set(.init(class: .one, command: .inputSwitch, code: .projectorFailure)))),
                true
            ),
            .init(
                "%1INPT=ERR4",
                .success(.response(.get(.failure(.init(class: .one, command: .inputSwitch, code: .projectorFailure))))),
                false
            ),
            .init(
                "%2INPT=OK",
                .success(.response(.set(.init(class: .two, command: .inputSwitch, code: .ok))))
            ),
            .init(
                "%2INPT=OK",
                .success(.response(.set(.init(class: .two, command: .inputSwitch, code: .ok)))),
                true
            ),
            .init(
                "%2INPT=OK",
                .failure(.invalidClass2Input("O")),
                false
            ),
            .init(
                "%2INPT=ERR1",
                .success(.response(.set(.init(class: .two, command: .inputSwitch, code: .undefinedCommand))))
            ),
            .init(
                "%2INPT=ERR1",
                .success(.response(.set(.init(class: .two, command: .inputSwitch, code: .undefinedCommand)))),
                true
            ),
            .init(
                "%2INPT=ERR1",
                .success(.response(.get(.failure(.init(class: .two, command: .inputSwitch, code: .undefinedCommand))))),
                false
            ),
            .init(
                "%2INPT=ERR2",
                .success(.response(.set(.init(class: .two, command: .inputSwitch, code: .outOfParameter))))
            ),
            .init(
                "%2INPT=ERR2",
                .success(.response(.set(.init(class: .two, command: .inputSwitch, code: .outOfParameter)))),
                true
            ),
            .init(
                "%2INPT=ERR2",
                .success(.response(.get(.failure(.init(class: .two, command: .inputSwitch, code: .outOfParameter))))),
                false
            ),
            .init(
                "%2INPT=ERR3",
                .success(.response(.set(.init(class: .two, command: .inputSwitch, code: .unavailableTime))))
            ),
            .init(
                "%2INPT=ERR3",
                .success(.response(.set(.init(class: .two, command: .inputSwitch, code: .unavailableTime)))),
                true
            ),
            .init(
                "%2INPT=ERR3",
                .success(.response(.get(.failure(.init(class: .two, command: .inputSwitch, code: .unavailableTime))))),
                false
            ),
            .init(
                "%2INPT=ERR4",
                .success(.response(.set(.init(class: .two, command: .inputSwitch, code: .projectorFailure))))
            ),
            .init(
                "%2INPT=ERR4",
                .success(.response(.set(.init(class: .two, command: .inputSwitch, code: .projectorFailure)))),
                true
            ),
            .init(
                "%2INPT=ERR4",
                .success(.response(.get(.failure(.init(class: .two, command: .inputSwitch, code: .projectorFailure))))),
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
                .success(.response(.set(.init(class: .one, command: .avMute, code: .ok))))
            ),
            .init(
                "%1AVMT=OK",
                .success(.response(.set(.init(class: .one, command: .avMute, code: .ok)))),
                true
            ),
            .init(
                "%1AVMT=OK",
                .failure(.invalidMute("O")),
                false
            ),
            .init(
                "%1AVMT=ERR1",
                .success(.response(.set(.init(class: .one, command: .avMute, code: .undefinedCommand))))
            ),
            .init(
                "%1AVMT=ERR1",
                .success(.response(.set(.init(class: .one, command: .avMute, code: .undefinedCommand)))),
                true
            ),
            .init(
                "%1AVMT=ERR1",
                .success(.response(.get(.failure(.init(class: .one, command: .avMute, code: .undefinedCommand))))),
                false
            ),
            .init(
                "%1AVMT=ERR2",
                .success(.response(.set(.init(class: .one, command: .avMute, code: .outOfParameter))))
            ),
            .init(
                "%1AVMT=ERR2",
                .success(.response(.set(.init(class: .one, command: .avMute, code: .outOfParameter)))),
                true
            ),
            .init(
                "%1AVMT=ERR2",
                .success(.response(.get(.failure(.init(class: .one, command: .avMute, code: .outOfParameter))))),
                false
            ),
            .init(
                "%1AVMT=ERR3",
                .success(.response(.set(.init(class: .one, command: .avMute, code: .unavailableTime))))
            ),
            .init(
                "%1AVMT=ERR3",
                .success(.response(.set(.init(class: .one, command: .avMute, code: .unavailableTime)))),
                true
            ),
            .init(
                "%1AVMT=ERR3",
                .success(.response(.get(.failure(.init(class: .one, command: .avMute, code: .unavailableTime))))),
                false
            ),
            .init(
                "%1AVMT=ERR4",
                .success(.response(.set(.init(class: .one, command: .avMute, code: .projectorFailure))))
            ),
            .init(
                "%1AVMT=ERR4",
                .success(.response(.set(.init(class: .one, command: .avMute, code: .projectorFailure)))),
                true
            ),
            .init(
                "%1AVMT=ERR4",
                .success(.response(.get(.failure(.init(class: .one, command: .avMute, code: .projectorFailure))))),
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
                .success(.response(.set(.init(class: .one, command: .lamp, code: .undefinedCommand))))
            ),
            .init(
                "%1LAMP=ERR1",
                .success(.response(.set(.init(class: .one, command: .lamp, code: .undefinedCommand)))),
                true
            ),
            .init(
                "%1LAMP=ERR1",
                .success(.response(.get(.failure(.init(class: .one, command: .lamp, code: .undefinedCommand))))),
                false
            ),
            .init(
                "%1LAMP=ERR2",
                .success(.response(.set(.init(class: .one, command: .lamp, code: .outOfParameter))))
            ),
            .init(
                "%1LAMP=ERR2",
                .success(.response(.set(.init(class: .one, command: .lamp, code: .outOfParameter)))),
                true
            ),
            .init(
                "%1LAMP=ERR2",
                .success(.response(.get(.failure(.init(class: .one, command: .lamp, code: .outOfParameter))))),
                false
            ),
            .init(
                "%1LAMP=ERR3",
                .success(.response(.set(.init(class: .one, command: .lamp, code: .unavailableTime))))
            ),
            .init(
                "%1LAMP=ERR3",
                .success(.response(.set(.init(class: .one, command: .lamp, code: .unavailableTime)))),
                true
            ),
            .init(
                "%1LAMP=ERR3",
                .success(.response(.get(.failure(.init(class: .one, command: .lamp, code: .unavailableTime))))),
                false
            ),
            .init(
                "%1LAMP=ERR4",
                .success(.response(.set(.init(class: .one, command: .lamp, code: .projectorFailure))))
            ),
            .init(
                "%1LAMP=ERR4",
                .success(.response(.set(.init(class: .one, command: .lamp, code: .projectorFailure)))),
                true
            ),
            .init(
                "%1LAMP=ERR4",
                .success(.response(.get(.failure(.init(class: .one, command: .lamp, code: .projectorFailure))))),
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
                .success(.response(.set(.init(class: .one, command: .inputList, code: .undefinedCommand))))
            ),
            .init(
                "%1INST=ERR1",
                .success(.response(.set(.init(class: .one, command: .inputList, code: .undefinedCommand)))),
                true
            ),
            .init(
                "%1INST=ERR1",
                .success(.response(.get(.failure(.init(class: .one, command: .inputList, code: .undefinedCommand))))),
                false
            ),
            .init(
                "%1INST=ERR2",
                .success(.response(.set(.init(class: .one, command: .inputList, code: .outOfParameter))))
            ),
            .init(
                "%1INST=ERR2",
                .success(.response(.set(.init(class: .one, command: .inputList, code: .outOfParameter)))),
                true
            ),
            .init(
                "%1INST=ERR2",
                .success(.response(.get(.failure(.init(class: .one, command: .inputList, code: .outOfParameter))))),
                false
            ),
            .init(
                "%1INST=ERR3",
                .success(.response(.set(.init(class: .one, command: .inputList, code: .unavailableTime))))
            ),
            .init(
                "%1INST=ERR3",
                .success(.response(.set(.init(class: .one, command: .inputList, code: .unavailableTime)))),
                true
            ),
            .init(
                "%1INST=ERR3",
                .success(.response(.get(.failure(.init(class: .one, command: .inputList, code: .unavailableTime))))),
                false
            ),
            .init(
                "%1INST=ERR4",
                .success(.response(.set(.init(class: .one, command: .inputList, code: .projectorFailure))))
            ),
            .init(
                "%1INST=ERR4",
                .success(.response(.set(.init(class: .one, command: .inputList, code: .projectorFailure)))),
                true
            ),
            .init(
                "%1INST=ERR4",
                .success(.response(.get(.failure(.init(class: .one, command: .inputList, code: .projectorFailure))))),
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
                .success(.response(.set(.init(class: .one, command: .projectorName, code: .undefinedCommand))))
            ),
            .init(
                "%1NAME=ERR1",
                .success(.response(.set(.init(class: .one, command: .projectorName, code: .undefinedCommand)))),
                true
            ),
            .init(
                "%1NAME=ERR1",
                .success(.response(.get(.failure(.init(class: .one, command: .projectorName, code: .undefinedCommand))))),
                false
            ),
            .init(
                "%1NAME=ERR2",
                .success(.response(.set(.init(class: .one, command: .projectorName, code: .outOfParameter))))
            ),
            .init(
                "%1NAME=ERR2",
                .success(.response(.set(.init(class: .one, command: .projectorName, code: .outOfParameter)))),
                true
            ),
            .init(
                "%1NAME=ERR2",
                .success(.response(.get(.failure(.init(class: .one, command: .projectorName, code: .outOfParameter))))),
                false
            ),
            .init(
                "%1NAME=ERR3",
                .success(.response(.set(.init(class: .one, command: .projectorName, code: .unavailableTime))))
            ),
            .init(
                "%1NAME=ERR3",
                .success(.response(.set(.init(class: .one, command: .projectorName, code: .unavailableTime)))),
                true
            ),
            .init(
                "%1NAME=ERR3",
                .success(.response(.get(.failure(.init(class: .one, command: .projectorName, code: .unavailableTime))))),
                false
            ),
            .init(
                "%1NAME=ERR4",
                .success(.response(.set(.init(class: .one, command: .projectorName, code: .projectorFailure))))
            ),
            .init(
                "%1NAME=ERR4",
                .success(.response(.set(.init(class: .one, command: .projectorName, code: .projectorFailure)))),
                true
            ),
            .init(
                "%1NAME=ERR4",
                .success(.response(.get(.failure(.init(class: .one, command: .projectorName, code: .projectorFailure))))),
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
                .success(.response(.set(.init(class: .one, command: .manufacturerName, code: .undefinedCommand))))
            ),
            .init(
                "%1INF1=ERR1",
                .success(.response(.set(.init(class: .one, command: .manufacturerName, code: .undefinedCommand)))),
                true
            ),
            .init(
                "%1INF1=ERR1",
                .success(.response(.get(.failure(.init(class: .one, command: .manufacturerName, code: .undefinedCommand))))),
                false
            ),
            .init(
                "%1INF1=ERR2",
                .success(.response(.set(.init(class: .one, command: .manufacturerName, code: .outOfParameter))))
            ),
            .init(
                "%1INF1=ERR2",
                .success(.response(.set(.init(class: .one, command: .manufacturerName, code: .outOfParameter)))),
                true
            ),
            .init(
                "%1INF1=ERR2",
                .success(.response(.get(.failure(.init(class: .one, command: .manufacturerName, code: .outOfParameter))))),
                false
            ),
            .init(
                "%1INF1=ERR3",
                .success(.response(.set(.init(class: .one, command: .manufacturerName, code: .unavailableTime))))
            ),
            .init(
                "%1INF1=ERR3",
                .success(.response(.set(.init(class: .one, command: .manufacturerName, code: .unavailableTime)))),
                true
            ),
            .init(
                "%1INF1=ERR3",
                .success(.response(.get(.failure(.init(class: .one, command: .manufacturerName, code: .unavailableTime))))),
                false
            ),
            .init(
                "%1INF1=ERR4",
                .success(.response(.set(.init(class: .one, command: .manufacturerName, code: .projectorFailure))))
            ),
            .init(
                "%1INF1=ERR4",
                .success(.response(.set(.init(class: .one, command: .manufacturerName, code: .projectorFailure)))),
                true
            ),
            .init(
                "%1INF1=ERR4",
                .success(.response(.get(.failure(.init(class: .one, command: .manufacturerName, code: .projectorFailure))))),
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
                .success(.response(.set(.init(class: .one, command: .productName, code: .undefinedCommand))))
            ),
            .init(
                "%1INF2=ERR1",
                .success(.response(.set(.init(class: .one, command: .productName, code: .undefinedCommand)))),
                true
            ),
            .init(
                "%1INF2=ERR1",
                .success(.response(.get(.failure(.init(class: .one, command: .productName, code: .undefinedCommand))))),
                false
            ),
            .init(
                "%1INF2=ERR2",
                .success(.response(.set(.init(class: .one, command: .productName, code: .outOfParameter))))
            ),
            .init(
                "%1INF2=ERR2",
                .success(.response(.set(.init(class: .one, command: .productName, code: .outOfParameter)))),
                true
            ),
            .init(
                "%1INF2=ERR2",
                .success(.response(.get(.failure(.init(class: .one, command: .productName, code: .outOfParameter))))),
                false
            ),
            .init(
                "%1INF2=ERR3",
                .success(.response(.set(.init(class: .one, command: .productName, code: .unavailableTime))))
            ),
            .init(
                "%1INF2=ERR3",
                .success(.response(.set(.init(class: .one, command: .productName, code: .unavailableTime)))),
                true
            ),
            .init(
                "%1INF2=ERR3",
                .success(.response(.get(.failure(.init(class: .one, command: .productName, code: .unavailableTime))))),
                false
            ),
            .init(
                "%1INF2=ERR4",
                .success(.response(.set(.init(class: .one, command: .productName, code: .projectorFailure))))
            ),
            .init(
                "%1INF2=ERR4",
                .success(.response(.set(.init(class: .one, command: .productName, code: .projectorFailure)))),
                true
            ),
            .init(
                "%1INF2=ERR4",
                .success(.response(.get(.failure(.init(class: .one, command: .productName, code: .projectorFailure))))),
                false
            ),
        ]
        try run(testCases)
    }

    /*
    @Test
    func getRequestsHappyPath() throws {
        var testCases: [TestCase] = [
            .init("%1POWR ?", .init(class: .one, command: .power, body: .request(.get(.power)))),
            .init("%1INPT ?", .init(class: .one, command: .inputSwitch, body: .request(.get(.inputSwitchClass1)))),
            .init("%2INPT ?", .init(class: .two, command: .inputSwitch, body: .request(.get(.inputSwitchClass2)))),
            .init("%1AVMT ?", .init(class: .one, command: .avMute, body: .request(.get(.avMute)))),
            .init("%1ERST ?", .init(class: .one, command: .errorStatus, body: .request(.get(.errorStatus)))),
            .init("%1LAMP ?", .init(class: .one, command: .lamp, body: .request(.get(.lamp)))),
            .init("%1INST ?", .init(class: .one, command: .inputList, body: .request(.get(.inputListClass1)))),
            .init("%2INST ?", .init(class: .two, command: .inputList, body: .request(.get(.inputListClass2)))),
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

    @Test
    func getResponsesHappyPath() throws {
        var testCases = [TestCase]()
        // Add cases for POWR?
        PJLink.PowerStatus.allCases.forEach { powerStatus in
            testCases.append(
                .init(
                    "%1POWR=\(powerStatus.rawValue)",
                    .init(
                        class: .one,
                        command: .power,
                        body: .response(.body(.power(powerStatus)))
                    )
                )
            )
        }
        // Add cases for INPT? (class 1)
        PJLink.InputSwitchClass1.allCases.forEach { inputSwitch in
            testCases.append(
                .init(
                    "%1INPT=\(inputSwitch.description)",
                    .init(
                        class: .one,
                        command: .inputSwitch,
                        body: .response(.body(.inputSwitchClass1(inputSwitch)))
                    )
                )
            )
        }
        // Add cases for INPT? (class 2)
        PJLink.InputSwitchClass2.allCases.forEach { inputSwitch in
            testCases.append(
                .init(
                    "%2INPT=\(inputSwitch.description)",
                    .init(
                        class: .two,
                        command: .inputSwitch,
                        body: .response(.body(.inputSwitchClass2(inputSwitch)))
                    )
                )
            )
        }
        // Add cases for AVMT?
        PJLink.MuteState.allCases.forEach { muteState in
            testCases.append(
                .init(
                    "%1AVMT=\(muteState.description)",
                    .init(
                        class: .one,
                        command: .avMute,
                        body: .response(.body(.avMute(muteState)))
                    )
                )
            )
        }
        // Add cases for ERST?
        PJLink.ErrorStatus.allCases.forEach { errorStatus in
            testCases.append(
                .init(
                    "%1ERST=\(errorStatus.description)",
                    .init(
                        class: .one,
                        command: .errorStatus,
                        body: .response(.body(.errorStatus(errorStatus)))
                    )
                )
            )
        }
        // Add cases for LAMP?
        testCases.append(
            .init(
                "%1LAMP=\(PJLink.LampsStatus.mock.description)",
                .init(
                    class: .one,
                    command: .lamp,
                    body: .response(.body(.lamp(PJLink.LampsStatus.mock)))
                )
            )
        )
        // Add cases for INST? (Class 1)
        testCases.append(
            .init(
                "%1INST=\(PJLink.InputSwitchesClass1.mock.description)",
                .init(
                    class: .one,
                    command: .inputList,
                    body: .response(.body(.inputListClass1(.mock)))
                )
            )
        )
        // Add cases for INST? (Class 2)
        testCases.append(
            .init(
                "%2INST=\(PJLink.InputSwitchesClass2.mock.description)",
                .init(
                    class: .two,
                    command: .inputList,
                    body: .response(.body(.inputListClass2(.mock)))
                )
            )
        )
        // Add cases for NAME?
        testCases.append(
            .init(
                "%1NAME=\(PJLink.ProjectorName.mock.value)",
                .init(
                    class: .one,
                    command: .projectorName,
                    body: .response(.body(.projectorName(.mock)))
                )
            )
        )
        // Add cases for INF2?
        testCases.append(
            .init(
                "%1INF2=\(PJLink.ProductName.mock.value)",
                .init(
                    class: .one,
                    command: .productName,
                    body: .response(.body(.productName(.mock)))
                )
            )
        )
        // Add cases for INFO?
        testCases.append(
            .init(
                "%1INFO=\(PJLink.OtherInformation.mock.value)",
                .init(
                    class: .one,
                    command: .otherInformation,
                    body: .response(.body(.otherInformation(.mock)))
                )
            )
        )
        // Add cases for CLSS?
        PJLink.Class.allCases.forEach { projectorClass in
            testCases.append(
                .init(
                    "%1CLSS=\(projectorClass.rawValue)",
                    .init(
                        class: .one,
                        command: .projectorClass,
                        body: .response(.body(.projectorClass(projectorClass)))
                    )
                )
            )
        }
        // Add cases for SNUM?
        testCases.append(
            .init(
                "%2SNUM=\(PJLink.SerialNumber.mock.value)",
                .init(
                    class: .two,
                    command: .serialNumber,
                    body: .response(.body(.serialNumber(.mock)))
                )
            )
        )
        // Add cases for SVER?
        testCases.append(
            .init(
                "%2SVER=\(PJLink.SoftwareVersion.mock.value)",
                .init(
                    class: .two,
                    command: .softwareVersion,
                    body: .response(.body(.softwareVersion(.mock)))
                )
            )
        )
        // Add cases for INNM?
        testCases.append(
            .init(
                "%2INNM=\(PJLink.InputTerminalName.mock.value)",
                .init(
                    class: .two,
                    command: .inputTerminalName,
                    body: .response(.body(.inputTerminalName(.mock)))
                )
            )
        )
        // Add cases for IRES?
        PJLink.InputResolution.allCases.forEach { inputResolution in
            testCases.append(
                .init(
                    "%2IRES=\(inputResolution.description)",
                    .init(
                        class: .two,
                        command: .inputResolution,
                        body: .response(.body(.inputResolution(inputResolution)))
                    )
                )
            )
        }
        // Add cases for RRES?
        testCases.append(
            .init(
                "%2RRES=\(PJLink.Resolution.mock.description)",
                .init(
                    class: .two,
                    command: .recommendedResolution,
                    body: .response(.body(.recommendedResolution(.mock)))
                )
            )
        )
        // Add cases for FILT?
        testCases.append(
            .init(
                "%2FILT=\(PJLink.FilterUsageTime.mock.description)",
                .init(
                    class: .two,
                    command: .filterUsageTime,
                    body: .response(.body(.filterUsageTime(.mock)))
                )
            )
        )
        // Add cases for RLMP?
        testCases.append(
            .init(
                "%2RLMP=\(PJLink.ModelNumber.mock.value)",
                .init(
                    class: .two,
                    command: .lampReplacementModelNumber,
                    body: .response(.body(.lampReplacementModelNumber(.mock)))
                )
            )
        )
        // Add cases for RFIL?
        testCases.append(
            .init(
                "%2RFIL=\(PJLink.ModelNumber.mock.value)",
                .init(
                    class: .two,
                    command: .filterReplacementModelNumber,
                    body: .response(.body(.filterReplacementModelNumber(.mock)))
                )
            )
        )
        // Add cases for FREZ?
        PJLink.Freeze.allCases.forEach { freeze in
            testCases.append(
                .init(
                    "%2FREZ=\(freeze.rawValue)",
                    .init(
                        class: .two,
                        command: .freeze,
                        body: .response(.body(.freeze(freeze)))
                    )
                )
            )
        }
        try run(testCases)
    }
     */

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
