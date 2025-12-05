//
//  StringPrintingTests.swift
//  pjlink-client-swift
//
//  Created by Eric Hyche on 12/4/25.
//

@testable import PJLinkClient
import Testing

@Suite
struct StringPrintingTests {
    struct TestCase {
        var input: PJLink.Message
        var expected: String

        init(_ input: PJLink.Message, _ expected: String) {
            self.input = input
            self.expected = expected
        }
    }

    @Test
    func powerRequest() throws {
        let testCases: [TestCase] = [
            .init(.request(.get(.power)), "%1POWR ?"),
            .init(.request(.set(.power(.off))), "%1POWR 0"),
            .init(.request(.set(.power(.on))), "%1POWR 1"),
        ]
        try run(testCases)
    }

    @Test
    func powerResponse() throws {
        let testCases: [TestCase] = [
            .init(.response(.set(.init(class: .one, command: .power, code: .ok))), "%1POWR=OK"),
            .init(.response(.set(.init(class: .one, command: .power, code: .undefinedCommand))), "%1POWR=ERR1"),
            .init(.response(.set(.init(class: .one, command: .power, code: .outOfParameter))), "%1POWR=ERR2"),
            .init(.response(.set(.init(class: .one, command: .power, code: .unavailableTime))), "%1POWR=ERR3"),
            .init(.response(.set(.init(class: .one, command: .power, code: .projectorFailure))), "%1POWR=ERR4"),
            .init(.response(.get(.failure(.init(class: .one, command: .power, code: .undefinedCommand)))), "%1POWR=ERR1"),
            .init(.response(.get(.failure(.init(class: .one, command: .power, code: .outOfParameter)))), "%1POWR=ERR2"),
            .init(.response(.get(.failure(.init(class: .one, command: .power, code: .unavailableTime)))), "%1POWR=ERR3"),
            .init(.response(.get(.failure(.init(class: .one, command: .power, code: .projectorFailure)))), "%1POWR=ERR4"),
            .init(.response(.get(.success(.power(.standby)))), "%1POWR=0"),
            .init(.response(.get(.success(.power(.lampOn)))), "%1POWR=1"),
            .init(.response(.get(.success(.power(.cooling)))), "%1POWR=2"),
            .init(.response(.get(.success(.power(.warmUp)))), "%1POWR=3"),
        ]
        try run(testCases)
    }

    @Test
    func inputSwitchRequest() throws {
        var testCases: [TestCase] = [
            .init(.request(.get(.inputSwitchClass1)), "%1INPT ?"),
            .init(.request(.get(.inputSwitchClass2)), "%2INPT ?"),
        ]
        PJLink.InputSwitchClass1.allCases.forEach { inputSwitch in
            testCases.append(
                .init(
                    .request(.set(.inputSwitchClass1(inputSwitch))),
                    "%1INPT \(inputSwitch.input.rawValue)\(inputSwitch.channel.rawValue)"
                )
            )
        }
        PJLink.InputSwitchClass2.allCases.forEach { inputSwitch in
            testCases.append(
                .init(
                    .request(.set(.inputSwitchClass2(inputSwitch))),
                    "%2INPT \(inputSwitch.input.rawValue)\(inputSwitch.channel.rawValue)"
                )
            )
        }
        try run(testCases)
    }

    @Test
    func inputSwitchResponse() throws {
        var testCases: [TestCase] = [
            .init(.response(.set(.init(class: .one, command: .inputSwitch, code: .ok))), "%1INPT=OK"),
            .init(.response(.set(.init(class: .one, command: .inputSwitch, code: .undefinedCommand))), "%1INPT=ERR1"),
            .init(.response(.set(.init(class: .one, command: .inputSwitch, code: .outOfParameter))), "%1INPT=ERR2"),
            .init(.response(.set(.init(class: .one, command: .inputSwitch, code: .unavailableTime))), "%1INPT=ERR3"),
            .init(.response(.set(.init(class: .one, command: .inputSwitch, code: .projectorFailure))), "%1INPT=ERR4"),
            .init(.response(.set(.init(class: .two, command: .inputSwitch, code: .ok))), "%2INPT=OK"),
            .init(.response(.set(.init(class: .two, command: .inputSwitch, code: .undefinedCommand))), "%2INPT=ERR1"),
            .init(.response(.set(.init(class: .two, command: .inputSwitch, code: .outOfParameter))), "%2INPT=ERR2"),
            .init(.response(.set(.init(class: .two, command: .inputSwitch, code: .unavailableTime))), "%2INPT=ERR3"),
            .init(.response(.set(.init(class: .two, command: .inputSwitch, code: .projectorFailure))), "%2INPT=ERR4"),
            .init(.response(.get(.failure(.init(class: .one, command: .inputSwitch, code: .undefinedCommand)))), "%1INPT=ERR1"),
            .init(.response(.get(.failure(.init(class: .one, command: .inputSwitch, code: .outOfParameter)))), "%1INPT=ERR2"),
            .init(.response(.get(.failure(.init(class: .one, command: .inputSwitch, code: .unavailableTime)))), "%1INPT=ERR3"),
            .init(.response(.get(.failure(.init(class: .one, command: .inputSwitch, code: .projectorFailure)))), "%1INPT=ERR4"),
            .init(.response(.get(.failure(.init(class: .two, command: .inputSwitch, code: .undefinedCommand)))), "%2INPT=ERR1"),
            .init(.response(.get(.failure(.init(class: .two, command: .inputSwitch, code: .outOfParameter)))), "%2INPT=ERR2"),
            .init(.response(.get(.failure(.init(class: .two, command: .inputSwitch, code: .unavailableTime)))), "%2INPT=ERR3"),
            .init(.response(.get(.failure(.init(class: .two, command: .inputSwitch, code: .projectorFailure)))), "%2INPT=ERR4"),
        ]
        PJLink.InputSwitchClass1.allCases.forEach { inputSwitch in
            testCases.append(
                .init(
                    .response(.get(.success(.inputSwitchClass1(inputSwitch)))),
                    "%1INPT=\(inputSwitch.input.rawValue)\(inputSwitch.channel.rawValue)"
                )
            )
        }
        PJLink.InputSwitchClass2.allCases.forEach { inputSwitch in
            testCases.append(
                .init(
                    .response(.get(.success(.inputSwitchClass2(inputSwitch)))),
                    "%2INPT=\(inputSwitch.input.rawValue)\(inputSwitch.channel.rawValue)"
                )
            )
        }
        try run(testCases)
    }

    @Test
    func muteRequest() throws {
        var testCases: [TestCase] = [
            .init(.request(.get(.avMute)), "%1AVMT ?"),
        ]
        PJLink.MuteState.allCases.forEach { muteState in
            testCases.append(
                .init(
                    .request(.set(.avMute(muteState))),
                    "%1AVMT \(muteState.mute.rawValue)\(muteState.state.rawValue)"
                )
            )
        }
        try run(testCases)
    }

    @Test
    func muteResponse() throws {
        var testCases: [TestCase] = [
            .init(.response(.set(.init(class: .one, command: .avMute, code: .ok))), "%1AVMT=OK"),
            .init(.response(.set(.init(class: .one, command: .avMute, code: .undefinedCommand))), "%1AVMT=ERR1"),
            .init(.response(.set(.init(class: .one, command: .avMute, code: .outOfParameter))), "%1AVMT=ERR2"),
            .init(.response(.set(.init(class: .one, command: .avMute, code: .unavailableTime))), "%1AVMT=ERR3"),
            .init(.response(.set(.init(class: .one, command: .avMute, code: .projectorFailure))), "%1AVMT=ERR4"),
            .init(.response(.get(.failure(.init(class: .one, command: .avMute, code: .undefinedCommand)))), "%1AVMT=ERR1"),
            .init(.response(.get(.failure(.init(class: .one, command: .avMute, code: .outOfParameter)))), "%1AVMT=ERR2"),
            .init(.response(.get(.failure(.init(class: .one, command: .avMute, code: .unavailableTime)))), "%1AVMT=ERR3"),
            .init(.response(.get(.failure(.init(class: .one, command: .avMute, code: .projectorFailure)))), "%1AVMT=ERR4"),
        ]
        PJLink.MuteState.allCases.forEach { muteState in
            testCases.append(
                .init(
                    .response(.get(.success(.avMute(muteState)))),
                    "%1AVMT=\(muteState.mute.rawValue)\(muteState.state.rawValue)"
                )
            )
        }
        try run(testCases)
    }

    @Test
    func errorStatusRequest() throws {
        let testCases: [TestCase] = [
            .init(.request(.get(.errorStatus)), "%1ERST ?"),
        ]
        try run(testCases)
    }

    @Test
    func errorStatusResponse() throws {
        var testCases: [TestCase] = [
            .init(.response(.get(.failure(.init(class: .one, command: .errorStatus, code: .undefinedCommand)))), "%1ERST=ERR1"),
            .init(.response(.get(.failure(.init(class: .one, command: .errorStatus, code: .outOfParameter)))), "%1ERST=ERR2"),
            .init(.response(.get(.failure(.init(class: .one, command: .errorStatus, code: .unavailableTime)))), "%1ERST=ERR3"),
            .init(.response(.get(.failure(.init(class: .one, command: .errorStatus, code: .projectorFailure)))), "%1ERST=ERR4"),
        ]
        PJLink.ErrorStatus.allCases.forEach { st in
            testCases.append(
                .init(
                    .response(.get(.success(.errorStatus(st)))),
                    "%1ERST=\(st.fan.rawValue)\(st.lamp.rawValue)\(st.temperature.rawValue)\(st.coverOpen.rawValue)\(st.filter.rawValue)\(st.other.rawValue)"
                )
            )
        }
        try run(testCases)
    }

    @Test
    func lampRequest() throws {
        let testCases: [TestCase] = [
            .init(.request(.get(.lamp)), "%1LAMP ?"),
        ]
        try run(testCases)
    }

    @Test
    func lampResponse() throws {
        let testCases: [TestCase] = [
            .init(.response(.get(.failure(.init(class: .one, command: .lamp, code: .undefinedCommand)))), "%1LAMP=ERR1"),
            .init(.response(.get(.failure(.init(class: .one, command: .lamp, code: .outOfParameter)))), "%1LAMP=ERR2"),
            .init(.response(.get(.failure(.init(class: .one, command: .lamp, code: .unavailableTime)))), "%1LAMP=ERR3"),
            .init(.response(.get(.failure(.init(class: .one, command: .lamp, code: .projectorFailure)))), "%1LAMP=ERR4"),
            .init(
                .response(
                    .get(
                        .success(
                            .lamp(
                                .init(lampStatus: [.mock1, .mock2, .mock3])
                            )
                        )
                    )
                ),
                """
                %1LAMP=\(PJLink.LampStatus.mock1.usageTime) \(PJLink.LampStatus.mock1.state.rawValue) \
                \(PJLink.LampStatus.mock2.usageTime) \(PJLink.LampStatus.mock2.state.rawValue) \
                \(PJLink.LampStatus.mock3.usageTime) \(PJLink.LampStatus.mock3.state.rawValue)
                """
            )
        ]
        try run(testCases)
    }

    @Test
    func inputListRequest() throws {
        let testCases: [TestCase] = [
            .init(.request(.get(.inputListClass1)), "%1INST ?"),
            .init(.request(.get(.inputListClass2)), "%2INST ?"),
        ]
        try run(testCases)
    }

    @Test
    func inputListResponse() throws {
        var testCases: [TestCase] = [
            .init(.response(.get(.failure(.init(class: .one, command: .inputList, code: .undefinedCommand)))), "%1INST=ERR1"),
            .init(.response(.get(.failure(.init(class: .one, command: .inputList, code: .outOfParameter)))), "%1INST=ERR2"),
            .init(.response(.get(.failure(.init(class: .one, command: .inputList, code: .unavailableTime)))), "%1INST=ERR3"),
            .init(.response(.get(.failure(.init(class: .one, command: .inputList, code: .projectorFailure)))), "%1INST=ERR4"),
            .init(.response(.get(.failure(.init(class: .two, command: .inputList, code: .undefinedCommand)))), "%2INST=ERR1"),
            .init(.response(.get(.failure(.init(class: .two, command: .inputList, code: .outOfParameter)))), "%2INST=ERR2"),
            .init(.response(.get(.failure(.init(class: .two, command: .inputList, code: .unavailableTime)))), "%2INST=ERR3"),
            .init(.response(.get(.failure(.init(class: .two, command: .inputList, code: .projectorFailure)))), "%2INST=ERR4"),
        ]
        PJLink.InputSwitchClass1.allCases.forEach { inputSwitch in
            testCases.append(
                .init(
                    .response(.get(.success(.inputListClass1(.init(switches: [inputSwitch]))))),
                    "%1INST=\(inputSwitch.input.rawValue)\(inputSwitch.channel.rawValue)"
                )
            )
        }
        testCases.append(
            .init(
                .response(.get(.success(.inputListClass1(.mock)))),
                "%1INST=\(PJLink.InputSwitchClass1.allCases.map({ "\($0.input.rawValue)\($0.channel.rawValue)" }).joined(separator: " "))"
            )
        )
        PJLink.InputSwitchClass2.allCases.forEach { inputSwitch in
            testCases.append(
                .init(
                    .response(.get(.success(.inputListClass2(.init(switches: [inputSwitch]))))),
                    "%2INST=\(inputSwitch.input.rawValue)\(inputSwitch.channel.rawValue)"
                )
            )
        }
        testCases.append(
            .init(
                .response(.get(.success(.inputListClass2(.mock)))),
                "%2INST=\(PJLink.InputSwitchClass2.allCases.map({ "\($0.input.rawValue)\($0.channel.rawValue)" }).joined(separator: " "))"
            )
        )
        try run(testCases)
    }

    @Test
    func projectorNameRequest() throws {
        let testCases: [TestCase] = [
            .init(.request(.get(.projectorName)), "%1NAME ?"),
        ]
        try run(testCases)
    }

    @Test
    func projectorNameResponse() throws {
        let testCases: [TestCase] = [
            .init(
                .response(.get(.failure(.init(class: .one, command: .projectorName, code: .undefinedCommand)))),
                "%1NAME=ERR1"
            ),
            .init(
                .response(.get(.failure(.init(class: .one, command: .projectorName, code: .outOfParameter)))),
                "%1NAME=ERR2"
            ),
            .init(
                .response(.get(.failure(.init(class: .one, command: .projectorName, code: .unavailableTime)))),
                "%1NAME=ERR3"
            ),
            .init(
                .response(.get(.failure(.init(class: .one, command: .projectorName, code: .projectorFailure)))),
                "%1NAME=ERR4"
            ),
            .init(
                .response(.get(.success(.projectorName(.mock)))),
                "%1NAME=\(PJLink.ProjectorName.mock.value)"
            )
        ]
        try run(testCases)
    }

    @Test
    func manufacturerNameRequest() throws {
        let testCases: [TestCase] = [
            .init(.request(.get(.manufacturerName)), "%1INF1 ?"),
        ]
        try run(testCases)
    }

    @Test
    func manufacturerNameResponse() throws {
        let testCases: [TestCase] = [
            .init(
                .response(.get(.failure(.init(class: .one, command: .manufacturerName, code: .undefinedCommand)))),
                "%1INF1=ERR1"
            ),
            .init(
                .response(.get(.failure(.init(class: .one, command: .manufacturerName, code: .outOfParameter)))),
                "%1INF1=ERR2"
            ),
            .init(
                .response(.get(.failure(.init(class: .one, command: .manufacturerName, code: .unavailableTime)))),
                "%1INF1=ERR3"
            ),
            .init(
                .response(.get(.failure(.init(class: .one, command: .manufacturerName, code: .projectorFailure)))),
                "%1INF1=ERR4"
            ),
            .init(
                .response(.get(.success(.manufacturerName(.mock)))),
                "%1INF1=\(PJLink.ManufacturerName.mock.value)"
            )
        ]
        try run(testCases)
    }

    @Test
    func productNameRequest() throws {
        let testCases: [TestCase] = [
            .init(.request(.get(.productName)), "%1INF2 ?"),
        ]
        try run(testCases)
    }

    @Test
    func productNameResponse() throws {
        let testCases: [TestCase] = [
            .init(
                .response(.get(.failure(.init(class: .one, command: .productName, code: .undefinedCommand)))),
                "%1INF2=ERR1"
            ),
            .init(
                .response(.get(.failure(.init(class: .one, command: .productName, code: .outOfParameter)))),
                "%1INF2=ERR2"
            ),
            .init(
                .response(.get(.failure(.init(class: .one, command: .productName, code: .unavailableTime)))),
                "%1INF2=ERR3"
            ),
            .init(
                .response(.get(.failure(.init(class: .one, command: .productName, code: .projectorFailure)))),
                "%1INF2=ERR4"
            ),
            .init(
                .response(.get(.success(.productName(.mock)))),
                "%1INF2=\(PJLink.ProductName.mock.value)"
            )
        ]
        try run(testCases)
    }

    @Test
    func otherInformationRequest() throws {
        let testCases: [TestCase] = [
            .init(.request(.get(.otherInformation)), "%1INFO ?"),
        ]
        try run(testCases)
    }

    @Test
    func otherInformationResponse() throws {
        let testCases: [TestCase] = [
            .init(
                .response(.get(.failure(.init(class: .one, command: .otherInformation, code: .undefinedCommand)))),
                "%1INFO=ERR1"
            ),
            .init(
                .response(.get(.failure(.init(class: .one, command: .otherInformation, code: .outOfParameter)))),
                "%1INFO=ERR2"
            ),
            .init(
                .response(.get(.failure(.init(class: .one, command: .otherInformation, code: .unavailableTime)))),
                "%1INFO=ERR3"
            ),
            .init(
                .response(.get(.failure(.init(class: .one, command: .otherInformation, code: .projectorFailure)))),
                "%1INFO=ERR4"
            ),
            .init(
                .response(.get(.success(.otherInformation(.mock)))),
                "%1INFO=\(PJLink.OtherInformation.mock.value)"
            )
        ]
        try run(testCases)
    }

    @Test
    func classRequest() throws {
        let testCases: [TestCase] = [
            .init(.request(.get(.projectorClass)), "%1CLSS ?"),
        ]
        try run(testCases)
    }

    @Test
    func classResponse() throws {
        let testCases: [TestCase] = [
            .init(
                .response(.get(.failure(.init(class: .one, command: .projectorClass, code: .undefinedCommand)))),
                "%1CLSS=ERR1"
            ),
            .init(
                .response(.get(.failure(.init(class: .one, command: .projectorClass, code: .outOfParameter)))),
                "%1CLSS=ERR2"
            ),
            .init(
                .response(.get(.failure(.init(class: .one, command: .projectorClass, code: .unavailableTime)))),
                "%1CLSS=ERR3"
            ),
            .init(
                .response(.get(.failure(.init(class: .one, command: .projectorClass, code: .projectorFailure)))),
                "%1CLSS=ERR4"
            ),
            .init(
                .response(.get(.success(.projectorClass(.one)))),
                "%1CLSS=1"
            ),
            .init(
                .response(.get(.success(.projectorClass(.two)))),
                "%1CLSS=2"
            ),
        ]
        try run(testCases)
    }

    @Test
    func serialNumberRequest() throws {
        let testCases: [TestCase] = [
            .init(.request(.get(.serialNumber)), "%2SNUM ?"),
        ]
        try run(testCases)
    }

    @Test
    func serialNumberResponse() throws {
        let testCases: [TestCase] = [
            .init(
                .response(.get(.failure(.init(class: .two, command: .serialNumber, code: .undefinedCommand)))),
                "%2SNUM=ERR1"
            ),
            .init(
                .response(.get(.failure(.init(class: .two, command: .serialNumber, code: .outOfParameter)))),
                "%2SNUM=ERR2"
            ),
            .init(
                .response(.get(.failure(.init(class: .two, command: .serialNumber, code: .unavailableTime)))),
                "%2SNUM=ERR3"
            ),
            .init(
                .response(.get(.failure(.init(class: .two, command: .serialNumber, code: .projectorFailure)))),
                "%2SNUM=ERR4"
            ),
            .init(
                .response(.get(.success(.serialNumber(.mock)))),
                "%2SNUM=\(PJLink.SerialNumber.mock.value)"
            ),
        ]
        try run(testCases)
    }


    @Test
    func softwareVersionRequest() throws {
        let testCases: [TestCase] = [
            .init(.request(.get(.softwareVersion)), "%2SVER ?"),
        ]
        try run(testCases)
    }

    @Test
    func softwareVersionResponse() throws {
        let testCases: [TestCase] = [
            .init(
                .response(.get(.failure(.init(class: .two, command: .softwareVersion, code: .undefinedCommand)))),
                "%2SVER=ERR1"
            ),
            .init(
                .response(.get(.failure(.init(class: .two, command: .softwareVersion, code: .outOfParameter)))),
                "%2SVER=ERR2"
            ),
            .init(
                .response(.get(.failure(.init(class: .two, command: .softwareVersion, code: .unavailableTime)))),
                "%2SVER=ERR3"
            ),
            .init(
                .response(.get(.failure(.init(class: .two, command: .softwareVersion, code: .projectorFailure)))),
                "%2SVER=ERR4"
            ),
            .init(
                .response(.get(.success(.softwareVersion(.mock)))),
                "%2SVER=\(PJLink.SoftwareVersion.mock.value)"
            ),
        ]
        try run(testCases)
    }

    @Test
    func inputTerminalNameRequest() throws {
        var testCases: [TestCase] = []
        PJLink.InputSwitchClass2.allCases.forEach { inputSwitch in
            testCases.append(
                .init(
                    .request(.get(.inputTerminalName(inputSwitch))),
                    "%2INNM ?\(inputSwitch.input.rawValue)\(inputSwitch.channel.rawValue)"
                )
            )
        }
        try run(testCases)
    }

    @Test
    func inputTerminalNameResponse() throws {
        let testCases: [TestCase] = [
            .init(
                .response(.get(.failure(.init(class: .two, command: .inputTerminalName, code: .undefinedCommand)))),
                "%2INNM=ERR1"
            ),
            .init(
                .response(.get(.failure(.init(class: .two, command: .inputTerminalName, code: .outOfParameter)))),
                "%2INNM=ERR2"
            ),
            .init(
                .response(.get(.failure(.init(class: .two, command: .inputTerminalName, code: .unavailableTime)))),
                "%2INNM=ERR3"
            ),
            .init(
                .response(.get(.failure(.init(class: .two, command: .inputTerminalName, code: .projectorFailure)))),
                "%2INNM=ERR4"
            ),
            .init(
                .response(.get(.success(.inputTerminalName(.mock)))),
                "%2INNM=\(PJLink.InputTerminalName.mock.value)"
            ),
        ]
        try run(testCases)
    }

    @Test
    func inputResolutionRequest() throws {
        let testCases: [TestCase] = [
            .init(.request(.get(.inputResolution)), "%2IRES ?"),
        ]
        try run(testCases)
    }

    @Test
    func inputResolutionResponse() throws {
        let testCases: [TestCase] = [
            .init(
                .response(.get(.failure(.init(class: .two, command: .inputResolution, code: .undefinedCommand)))),
                "%2IRES=ERR1"
            ),
            .init(
                .response(.get(.failure(.init(class: .two, command: .inputResolution, code: .outOfParameter)))),
                "%2IRES=ERR2"
            ),
            .init(
                .response(.get(.failure(.init(class: .two, command: .inputResolution, code: .unavailableTime)))),
                "%2IRES=ERR3"
            ),
            .init(
                .response(.get(.failure(.init(class: .two, command: .inputResolution, code: .projectorFailure)))),
                "%2IRES=ERR4"
            ),
            .init(
                .response(.get(.success(.inputResolution(.noSignal)))),
                "%2IRES=-"
            ),
            .init(
                .response(.get(.success(.inputResolution(.unknownSignal)))),
                "%2IRES=*"
            ),
            .init(
                .response(.get(.success(.inputResolution(.ok(.mock))))),
                "%2IRES=1920x1080"
            ),
        ]
        try run(testCases)
    }


    @Test
    func recommendedResolutionRequest() throws {
        let testCases: [TestCase] = [
            .init(.request(.get(.recommendedResolution)), "%2RRES ?"),
        ]
        try run(testCases)
    }

    @Test
    func recommendedResolutionResponse() throws {
        let testCases: [TestCase] = [
            .init(
                .response(.get(.failure(.init(class: .two, command: .recommendedResolution, code: .undefinedCommand)))),
                "%2RRES=ERR1"
            ),
            .init(
                .response(.get(.failure(.init(class: .two, command: .recommendedResolution, code: .outOfParameter)))),
                "%2RRES=ERR2"
            ),
            .init(
                .response(.get(.failure(.init(class: .two, command: .recommendedResolution, code: .unavailableTime)))),
                "%2RRES=ERR3"
            ),
            .init(
                .response(.get(.failure(.init(class: .two, command: .recommendedResolution, code: .projectorFailure)))),
                "%2RRES=ERR4"
            ),
            .init(
                .response(.get(.success(.recommendedResolution(.mock)))),
                "%2RRES=1920x1080"
            ),
        ]
        try run(testCases)
    }

    @Test
    func filterUsageTimeRequest() throws {
        let testCases: [TestCase] = [
            .init(.request(.get(.filterUsageTime)), "%2FILT ?"),
        ]
        try run(testCases)
    }

    @Test
    func filterUsageTimeResponse() throws {
        let testCases: [TestCase] = [
            .init(
                .response(.get(.failure(.init(class: .two, command: .filterUsageTime, code: .undefinedCommand)))),
                "%2FILT=ERR1"
            ),
            .init(
                .response(.get(.failure(.init(class: .two, command: .filterUsageTime, code: .outOfParameter)))),
                "%2FILT=ERR2"
            ),
            .init(
                .response(.get(.failure(.init(class: .two, command: .filterUsageTime, code: .unavailableTime)))),
                "%2FILT=ERR3"
            ),
            .init(
                .response(.get(.failure(.init(class: .two, command: .filterUsageTime, code: .projectorFailure)))),
                "%2FILT=ERR4"
            ),
            .init(
                .response(.get(.success(.filterUsageTime(.mock)))),
                "%2FILT=\(PJLink.FilterUsageTime.mock.value)"
            ),
        ]
        try run(testCases)
    }

    @Test
    func lampReplacementModelNumberRequest() throws {
        let testCases: [TestCase] = [
            .init(.request(.get(.lampReplacementModelNumber)), "%2RLMP ?"),
        ]
        try run(testCases)
    }

    @Test
    func lampReplacementModelNumberResponse() throws {
        let testCases: [TestCase] = [
            .init(
                .response(.get(.failure(.init(class: .two, command: .lampReplacementModelNumber, code: .undefinedCommand)))),
                "%2RLMP=ERR1"
            ),
            .init(
                .response(.get(.failure(.init(class: .two, command: .lampReplacementModelNumber, code: .outOfParameter)))),
                "%2RLMP=ERR2"
            ),
            .init(
                .response(.get(.failure(.init(class: .two, command: .lampReplacementModelNumber, code: .unavailableTime)))),
                "%2RLMP=ERR3"
            ),
            .init(
                .response(.get(.failure(.init(class: .two, command: .lampReplacementModelNumber, code: .projectorFailure)))),
                "%2RLMP=ERR4"
            ),
            .init(
                .response(.get(.success(.lampReplacementModelNumber(.mock)))),
                "%2RLMP=\(PJLink.ModelNumber.mock.value)"
            ),
        ]
        try run(testCases)
    }

    @Test
    func filterReplacementModelNumberRequest() throws {
        let testCases: [TestCase] = [
            .init(.request(.get(.filterReplacementModelNumber)), "%2RFIL ?"),
        ]
        try run(testCases)
    }

    @Test
    func filterReplacementModelNumberResponse() throws {
        let testCases: [TestCase] = [
            .init(
                .response(.get(.failure(.init(class: .two, command: .filterReplacementModelNumber, code: .undefinedCommand)))),
                "%2RFIL=ERR1"
            ),
            .init(
                .response(.get(.failure(.init(class: .two, command: .filterReplacementModelNumber, code: .outOfParameter)))),
                "%2RFIL=ERR2"
            ),
            .init(
                .response(.get(.failure(.init(class: .two, command: .filterReplacementModelNumber, code: .unavailableTime)))),
                "%2RFIL=ERR3"
            ),
            .init(
                .response(.get(.failure(.init(class: .two, command: .filterReplacementModelNumber, code: .projectorFailure)))),
                "%2RFIL=ERR4"
            ),
            .init(
                .response(.get(.success(.filterReplacementModelNumber(.mock)))),
                "%2RFIL=\(PJLink.ModelNumber.mock.value)"
            ),
        ]
        try run(testCases)
    }

    @Test
    func speakerVolumeAdjustmentRequest() throws {
        let testCases: [TestCase] = [
            .init(.request(.set(.speakerVolume(.increase))), "%2SVOL 1"),
            .init(.request(.set(.speakerVolume(.decrease))), "%2SVOL 0"),
        ]
        try run(testCases)
    }

    @Test
    func speakerVolumeAdjustmentResponse() throws {
        let testCases: [TestCase] = [
            .init(
                .response(.set(.init(class: .two, command: .speakerVolume, code: .ok))),
                "%2SVOL=OK"
            ),
            .init(
                .response(.set(.init(class: .two, command: .speakerVolume, code: .undefinedCommand))),
                "%2SVOL=ERR1"
            ),
            .init(
                .response(.set(.init(class: .two, command: .speakerVolume, code: .outOfParameter))),
                "%2SVOL=ERR2"
            ),
            .init(
                .response(.set(.init(class: .two, command: .speakerVolume, code: .unavailableTime))),
                "%2SVOL=ERR3"
            ),
            .init(
                .response(.set(.init(class: .two, command: .speakerVolume, code: .projectorFailure))),
                "%2SVOL=ERR4"
            ),
        ]
        try run(testCases)
    }

    @Test
    func microphoneVolumeAdjustmentRequest() throws {
        let testCases: [TestCase] = [
            .init(.request(.set(.microphoneVolume(.increase))), "%2MVOL 1"),
            .init(.request(.set(.microphoneVolume(.decrease))), "%2MVOL 0"),
        ]
        try run(testCases)
    }

    @Test
    func microphoneVolumeAdjustmentResponse() throws {
        let testCases: [TestCase] = [
            .init(
                .response(.set(.init(class: .two, command: .microphoneVolume, code: .ok))),
                "%2MVOL=OK"
            ),
            .init(
                .response(.set(.init(class: .two, command: .microphoneVolume, code: .undefinedCommand))),
                "%2MVOL=ERR1"
            ),
            .init(
                .response(.set(.init(class: .two, command: .microphoneVolume, code: .outOfParameter))),
                "%2MVOL=ERR2"
            ),
            .init(
                .response(.set(.init(class: .two, command: .microphoneVolume, code: .unavailableTime))),
                "%2MVOL=ERR3"
            ),
            .init(
                .response(.set(.init(class: .two, command: .microphoneVolume, code: .projectorFailure))),
                "%2MVOL=ERR4"
            ),
        ]
        try run(testCases)
    }

    @Test
    func freezeRequest() throws {
        let testCases: [TestCase] = [
            .init(.request(.get(.freeze)), "%2FREZ ?"),
            .init(.request(.set(.freeze(.start))), "%2FREZ 1"),
            .init(.request(.set(.freeze(.stop))), "%2FREZ 0"),
        ]
        try run(testCases)
    }

    @Test
    func freezeResponse() throws {
        let testCases: [TestCase] = [
            .init(
                .response(.set(.init(class: .two, command: .freeze, code: .ok))),
                "%2FREZ=OK"
            ),
            .init(
                .response(.set(.init(class: .two, command: .freeze, code: .undefinedCommand))),
                "%2FREZ=ERR1"
            ),
            .init(
                .response(.set(.init(class: .two, command: .freeze, code: .outOfParameter))),
                "%2FREZ=ERR2"
            ),
            .init(
                .response(.set(.init(class: .two, command: .freeze, code: .unavailableTime))),
                "%2FREZ=ERR3"
            ),
            .init(
                .response(.set(.init(class: .two, command: .freeze, code: .projectorFailure))),
                "%2FREZ=ERR4"
            ),
            .init(
                .response(.get(.failure(.init(class: .two, command: .freeze, code: .undefinedCommand)))),
                "%2FREZ=ERR1"
            ),
            .init(
                .response(.get(.failure(.init(class: .two, command: .freeze, code: .outOfParameter)))),
                "%2FREZ=ERR2"
            ),
            .init(
                .response(.get(.failure(.init(class: .two, command: .freeze, code: .unavailableTime)))),
                "%2FREZ=ERR3"
            ),
            .init(
                .response(.get(.success(.freeze(.stop)))),
                "%2FREZ=0"
            ),
            .init(
                .response(.get(.success(.freeze(.start)))),
                "%2FREZ=1"
            ),
        ]
        try run(testCases)
    }

    private func run(_ testCases: [TestCase]) throws {
        for testCase in testCases {
            let actual = testCase.input.description
            #expect(actual == testCase.expected, "Expected \"\(testCase.expected)\", but got \"\(actual)\".")
        }
    }
}
