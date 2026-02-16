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
        var client = PJLink.Client(host: .init(host), password: password)

        let clientListener = try PJLink.ClientNotificationListener { [state = client.state] host, notification in
            print("Client Received Notification \"\(notification)\" from \"\(String(describing: host))\"")
            state.withValue { mutableState in
                mutableState?.applyingNotification(notification)
            }
            if let currentState = state.value {
                print("Current state: \n\(currentState)")
            }
        }

        // Do setup
        print("Setting Up...")
        try await client.setup()

        print("Fetching current state...")
        try await client.refreshState()
        print("Current state: \n\(client.stateDescription)")

        async let runResult = self.runMenu(client: &client)
        async let listenerResult = clientListener.run()
        let _ = try await [runResult, listenerResult]

        print("Client exiting.")
    }

    private func runMenu(
        client: inout PJLink.Client
    ) async throws -> Bool {
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
                try await client.setPower(to: onOff)
                print("Current state: \n\(client.stateDescription)")
            case .setInput:
                // Get the user input
                let inputs = client.inputs
                printInputMenu(inputs: inputs)
                print("Enter index of input, or Enter to return to main menu: ", terminator: "")
                guard let inputLine = readLine(), let inputIndex = Int(inputLine) else {
                    print("This is not a valid integer. Please re-enter.")
                    break
                }
                guard inputIndex >= 0, inputIndex < inputs.count else {
                    print("\(inputIndex) is not in the range [0, \(inputs.count - 1)]. Please re-enter.")
                    break
                }
                // Make the API call
                try await client.setInput(to: inputs[inputIndex])
                print("Current state: \n\(client.stateDescription)")
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
                try await client.setMuteState(to: allMuteStates[inputIndex])
                print("Current state: \n\(client.stateDescription)")
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
                try await client.setSpeakerVolume(to: volumeAdjustment)
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
                try await client.setMicrophoneVolume(to: volumeAdjustment)
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
                try await client.setFreeze(to: allFreeze[inputIndex])
                print("Current state: \n\(client.stateDescription)")
            case .sendNotification:
                printNotificationMenu()
                print("Enter index of notification to send, or Enter to return to main menu: ", terminator: "")
                guard let inputLine = readLine(), let inputIndex = Int(inputLine) else {
                    print("This is not a valid integer. Please re-enter.")
                    break
                }
                let allNotifications = PJLink.Notification.allCases
                guard inputIndex >= 0, inputIndex < allNotifications.count else {
                    print("\(inputIndex) is not in the range [0, \(allNotifications.count - 1)]. Please re-enter.")
                    break
                }
                // Send the UDP notification
                try await client.sendNotification(allNotifications[inputIndex])
            }
        }

        return true
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

    private func printInputMenu(inputs: [PJLink.Input]) {
        print("Set Input To:")
        inputs.enumerated().forEach { index, input in
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

    private func printNotificationMenu() {
        PJLink.Notification.allCases.enumerated().forEach { index, notification in
            print("\(index)) \(notification.displayName)")
        }
    }

    private enum MenuOption: Int, CaseIterable {
        case setPowerStatus = 1
        case setInput = 2
        case setMuteStatus = 3
        case setSpeakerVolume = 4
        case setMicrophoneVolume = 5
        case setFreeze = 6
        case sendNotification = 7

        var title: String {
            switch self {
            case .setPowerStatus: "Set Power Status"
            case .setInput: "Set Input"
            case .setMuteStatus: "Set Mute Status"
            case .setSpeakerVolume: "Set Speaker Volume"
            case .setMicrophoneVolume: "Set Microphone Volume"
            case .setFreeze: "Set Freeze"
            case .sendNotification: "Send Notification"
            }
        }
    }
}
