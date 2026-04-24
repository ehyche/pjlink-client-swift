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
import PJLinkBroadcastUDP

@main
struct PJLinkClientCLI: AsyncParsableCommand {
    @Flag(help: "Perform projector discovery instead of specifying host.")
    var discovery = false

    @Option(help: "The IP address of the projector host.")
    var host: String?

    @Option(help: "The password to use to authenticate with the projectors.")
    var password: String?

    mutating func run() async throws {
        var projectors = [NWEndpoint.Host]()
        if discovery {
            let broadcastAddress = try PJLink.IPAddressDiscovery.getBroadcastAddress()
            guard let broadcastAddress else {
                print("Could not determine broadcast address. Exiting.")
                return
            }
            print("Discovering projectors using broadcast address of \(broadcastAddress) for 30 seconds...")
            let projectorDiscovery = try PJLink.UDPProjectorDiscovery(broadcastHost: broadcastAddress.host, duration: .seconds(30))
            for try await projector in projectorDiscovery.outputStream {
                print("Discovered projector at \(String(describing: projector.host))")
                if let host = projector.host {
                    projectors.append(host)
                }
            }
            guard !projectors.isEmpty else {
                print("No projectors discovered. Exiting.")
                return
            }
        } else if let host {
            projectors.append(.init(host))
        } else {
            print("Either --discovery or --host must be specified. Exiting.")
            return
        }

        var clients = try await withThrowingTaskGroup(of: PJLink.Client.self, returning: [PJLink.Client].self) { [password = self.password] group in
            for host in projectors {
                group.addTask {
                    var client = PJLink.Client(host: host, password: password)
                    print("Setting up client for projector at \(host)")
                    try await client.setup()
                    print("Fetching current state for projector at \(host)")
                    try await client.refreshState()
                    return client
                }
            }
            var clients = [PJLink.Client]()
            for try await client in group {
                clients.append(client)
            }
            return clients
        }

        let notificationListener = try PJLink.ClientNotificationListener()

        let listenerTask = Task { [clients] in
            for try await notification in notificationListener.notificationStream {
                print("Received \(notification.notification) from \(notification.host)")
                if let client = clients.first(where: { $0.host == notification.host }) {
                    client.handleNotification(notification.notification)
                } else {
                    print("Could not find Client for \(notification.host).")
                }
            }
            return true
        }

        var result = true
        while result {
            var clientIndex = 0
            if clients.count > 1 {
                printProjectorsMenu(clients)
                print("Select a projector (or just Enter to exit): ", terminator: "")
                guard let line = readLine(), !line.isEmpty else { break }
                guard let index = Int(line), index >= 0, index < clients.count else {
                    print("\"\(line)\" is not a valid projector index. Please enter an integer between 0 and \(clients.count - 1) inclusive.")
                    continue
                }
                clientIndex = index
            }
            result = try await runMenuOnce(client: &clients[clientIndex])
        }

        print("Cancelling ClientNotificationListener.")
        notificationListener.cancel()
        _ = try await listenerTask.value

        print("PJLinkClientCLI exiting.")
    }

    private func runMenuOnce(
        client: inout PJLink.Client
    ) async throws -> Bool {
        printMenu()
        print("Enter an option to perform (or just Enter to exit): ", terminator: "")
        guard let line = readLine(), !line.isEmpty else { return false }

        guard let optionIndex = Int(line), let menuOption = MenuOption(rawValue: optionIndex) else {
            print("\"\(line)\" is not a valid option. Please try again.")
            return true
        }

        switch menuOption {
        case .showState:
            print("Current state: \n\(client.stateDescription)")
        case .setPowerStatus:
            // Get the user input
            printPowerStatusMenu()
            print("Enter 0 for Off, 1 for On (or Enter to return to main menu): ", terminator: "")
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
        }

        return true
    }

    private func printProjectorsMenu(_ clients: [PJLink.Client]) {
        clients.enumerated().forEach { index, client in
            print("\(index)) \(client.host)")
        }
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
        case showState = 1
        case setPowerStatus = 2
        case setInput = 3
        case setMuteStatus = 4
        case setSpeakerVolume = 5
        case setMicrophoneVolume = 6
        case setFreeze = 7

        var title: String {
            switch self {
            case .showState: "Show State"
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
