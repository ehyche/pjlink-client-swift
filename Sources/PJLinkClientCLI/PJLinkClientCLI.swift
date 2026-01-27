// The Swift Programming Language
// https://docs.swift.org/swift-book
// 
// Swift Argument Parser
// https://swiftpackageindex.com/apple/swift-argument-parser/documentation

import ArgumentParser
import Foundation
import Network
import os
import PJLinkCommon
import PJLinkClient

@main
struct PJLinkClientCLI: AsyncParsableCommand {
    @Option(help: "The IP address of the projector host.")
    var host: String

    @Option(help: "The password to use to authenticate with the projector.")
    var password: String?

    mutating func run() async throws {
        let logger = Logger(sub: .client, cat: .connection)
        let connection = NetworkConnection(to: .hostPort(host: .init(host), port: 4352)) {
            TCP()
        }

        connection.onBetterPathUpdate { connection, newValue in
            logger.debug("Connection[\(connection.id)] onBetterPathUpdate: \(newValue)")
        }
        connection.onPathUpdate { connection, newPath in
            logger.debug("Connection[\(connection.id)] onPathUpdate: \(newPath.debugDescription)")
        }
        connection.onViabilityUpdate { connection, newViable in
            logger.debug("Connection[\(connection.id)] onViabilityUpdate: \(newViable)")
        }
        connection.onStateUpdate { connection, state in
            let stateDesc: String
            switch state {
            case .setup:
                stateDesc = "Setup"
            case .waiting(let error):
                stateDesc = "Waiting(\(error))"
            case .preparing:
                stateDesc = "Preparing"
            case .ready:
                stateDesc = "Ready"
            case .failed(let error):
                stateDesc = "Failed(\(error))"
            case .cancelled:
                stateDesc = "Cancelled"
            @unknown default:
                stateDesc = "Unknown"
            }
            logger.debug("Connection[\(connection.id)] onViabilityUpdate: \(stateDesc, privacy: .public)")
        }

        // Do authentication
        print("Authenticating...")
        let connectionState = try await PJLink.Client.authenticate(on: connection, password: password)

        print("Fetching current state...")
        var state = try await PJLink.Client.fetchState(from: connectionState)
        print("Current state: \n\(state)")

        while true {
            printMenu()
            print("Enter an option to perform (or just Enter to exit): ", terminator: "")
            guard let line = readLine(), !line.isEmpty else { break }

            guard let optionIndex = Int(line), let menuOption = MenuOption(rawValue: optionIndex) else {
                print("\"\(line)\" is not a valid option. Please try again.")
                continue
            }

            switch menuOption {
            case .setPowerStatus:
                // Get the user input
                printPowerStatusMenu()
                print("Enter 0 for off, 1 for on, or Enter to return to main menu: ", terminator: "")
                guard let powerLine = readLine(), let onOff = PJLink.OnOff(rawValue: powerLine) else { break }
                // Make the API call
                let updatedPowerStatus = try await PJLink.Client.setPower(to: onOff, from: connectionState)
                // Update the state
                state.power = updatedPowerStatus
                print("Power Status updated to: \(updatedPowerStatus)")
                print("Current state: \n\(state)")
            case .setInput:
                // Get the user input
                printInputMenu(state: state)
                print("Enter index of input, or Enter to return to main menu: ", terminator: "")
                guard let inputLine = readLine(), let inputIndex = Int(inputLine) else {
                    print("This is not a valid integer. Please re-enter.")
                    break
                }
                let inputs = state.inputs
                guard inputIndex >= 0, inputIndex < inputs.count else {
                    print("\(inputIndex) is not in the range [0, \(inputs.count - 1)]. Please re-enter.")
                    break
                }
                // Make the API call
                let newActiveInput = try await PJLink.Client.setInput(to: inputs[inputIndex], from: connectionState)
                // Update the state
                state.activeInput = newActiveInput
                print("Active Input changed to: \(newActiveInput.displayName)")
                print("Current state: \n\(state)")
            case .setMuteStatus:
                // Get the user input
                printMuteMenu()
                print("Enter index of mute state, or Enter to return to main menu: ", terminator: "")
                guard let inputLine = readLine(), let inputIndex = Int(inputLine) else {
                    print("This is not a valid integer. Please re-enter.")
                    break
                }
                let allMuteStates = PJLink.MuteState.allCases
                guard inputIndex >= 0, inputIndex < allMuteStates.count else {
                    print("\(inputIndex) is not in the range [0, \(allMuteStates.count - 1)]. Please re-enter.")
                    break
                }
                // Make the API call
                let newMuteState = try await PJLink.Client.setMuteState(to: allMuteStates[inputIndex], from: connectionState)
                // Update the state
                state.mute = newMuteState
                print("Mute State set to: \(newMuteState)")
                print("Current state: \n\(state)")
            case .setSpeakerVolume:
                printSpeakerVolumeMenu()
                print("Enter index, or Enter to return to main menu: ", terminator: "")
                guard let inputLine = readLine(), let inputIndex = Int(inputLine) else {
                    print("This is not a valid integer. Please re-enter.")
                    break
                }
                let allVolumeAdjustments = PJLink.VolumeAdjustment.allCases
                guard inputIndex >= 0, inputIndex < allVolumeAdjustments.count else {
                    print("\(inputIndex) is not in the range [0, \(allVolumeAdjustments.count - 1)]. Please re-enter.")
                    break
                }
                // Make the API call
                let volumeAdjustment = allVolumeAdjustments[inputIndex]
                try await PJLink.Client.setSpeakerVolume(to: volumeAdjustment, from: connectionState)
                print("Speaker Volume set to: \(volumeAdjustment.displayName)")
            case .setMicrophoneVolume:
                printMicrophoneVolumeMenu()
                print("Enter index, or Enter to return to main menu: ", terminator: "")
                guard let inputLine = readLine(), let inputIndex = Int(inputLine) else {
                    print("This is not a valid integer. Please re-enter.")
                    break
                }
                let allVolumeAdjustments = PJLink.VolumeAdjustment.allCases
                guard inputIndex >= 0, inputIndex < allVolumeAdjustments.count else {
                    print("\(inputIndex) is not in the range [0, \(allVolumeAdjustments.count - 1)]. Please re-enter.")
                    break
                }
                // Make the API call
                let volumeAdjustment = allVolumeAdjustments[inputIndex]
                try await PJLink.Client.setMicrophoneVolume(to: volumeAdjustment, from: connectionState)
                print("Microphone Volume set to: \(volumeAdjustment.displayName)")
            case .setFreeze:
                printFreezeMenu()
                print("Enter index, or Enter to return to main menu: ", terminator: "")
                guard let inputLine = readLine(), let inputIndex = Int(inputLine) else {
                    print("This is not a valid integer. Please re-enter.")
                    break
                }
                let allFreeze = PJLink.Freeze.allCases
                guard inputIndex >= 0, inputIndex < allFreeze.count else {
                    print("\(inputIndex) is not in the range [0, \(allFreeze.count - 1)]. Please re-enter.")
                    break
                }
                // Make the API call
                let newFreeze = try await PJLink.Client.setFreeze(to: allFreeze[inputIndex], from: connectionState)
                print("Freeze State set to: \(newFreeze.displayName)")
                print("Current state: \n\(state)")
            }
        }

        print("Client exiting.")
    }

    private func printMenu() {
        MenuOption.allCases.forEach { menuOption in
            print("\(menuOption.rawValue)) \(menuOption.title)")
        }
    }

    private func printPowerStatusMenu() {
        print("Set Power To:")
        PJLink.OnOff.allCases.forEach { onOff in
            print("\(onOff.rawValue): \(onOff.displayName)")
        }
    }

    private func printInputMenu(state: PJLink.State) {
        print("Set Input To:")
        state.inputs.enumerated().forEach { index, input in
            print("\(index)) \(input.displayName)")
        }
    }

    private func printMuteMenu() {
        print("Set Mute To:")
        PJLink.MuteState.allCases.enumerated().forEach { index, muteState in
            print("\(index)) \(muteState.displayName)")
        }
    }

    private func printSpeakerVolumeMenu() {
        print("Change Speaker Volume:")
        printVolumeAdjustmentMenu()
    }

    private func printMicrophoneVolumeMenu() {
        print("Change Microphone Volume:")
        printVolumeAdjustmentMenu()
    }

    private func printFreezeMenu() {
        print("Set Freeze To:")
        PJLink.Freeze.allCases.enumerated().forEach { index, freeze in
            print("\(index)) \(freeze.displayName)")
        }
    }

    private func printVolumeAdjustmentMenu() {
        PJLink.VolumeAdjustment.allCases.enumerated().forEach { index, volumeAdjustment in
            print("\(index)) \(volumeAdjustment.displayName)")
        }
    }

    private enum MenuOption: Int, CaseIterable {
        case setPowerStatus = 1
        case setInput = 2
        case setMuteStatus = 3
        case setSpeakerVolume = 4
        case setMicrophoneVolume = 5
        case setFreeze = 6

        var title: String {
            switch self {
            case .setPowerStatus: "Set Power Status"
            case .setInput: "Set Input"
            case .setMuteStatus: "Set Mute Status"
            case .setSpeakerVolume: "Set Speaker Volume"
            case .setMicrophoneVolume: "Set Microphone Volume"
            case .setFreeze: "Set Freeze"
            }
        }
    }
}
