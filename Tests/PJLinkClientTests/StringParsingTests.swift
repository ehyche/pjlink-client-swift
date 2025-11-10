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

    }

    @Test
    func muteResponse() throws {

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
