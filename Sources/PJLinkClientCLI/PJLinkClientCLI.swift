// The Swift Programming Language
// https://docs.swift.org/swift-book
// 
// Swift Argument Parser
// https://swiftpackageindex.com/apple/swift-argument-parser/documentation

import ArgumentParser
import ConcurrencyExtras
import Foundation
import Network
import os
import PJLinkCommon
import PJLinkClient
import PJLinkBroadcastUDP

struct HostState: Equatable, Sendable {
    let host: NWEndpoint.Host
    let state: PJLink.State
}

@main
struct PJLinkClientCLI: AsyncParsableCommand {
    enum Discovery: String, ExpressibleByArgument {
        case broadcast
        case pingSweep
    }

    @Option(help: "Perform projector discovery instead of specifying host.")
    var discovery: Discovery?

    @Option(help: "The IP address of the projector host.")
    var host: String?

    @Option(help: "The password to use to authenticate with the projectors.")
    var password: String?

    mutating func run() async throws {
        let hosts: [NWEndpoint.Host]
        if let discovery {
            switch discovery {
            case .broadcast:
                hosts = try await discoverByBroadcast()
            case .pingSweep:
                hosts = try await discoverByPingSweep()
            }
            guard !hosts.isEmpty else {
                print("No projectors found. Exiting.")
                return
            }
        } else if let host {
            hosts = [.init(host)]
        } else {
            print("Either --discovery or --host must be specified. Exiting.")
            return
        }

        let stateMap = try await withThrowingTaskGroup(
            of: HostState.self,
            returning: [NWEndpoint.Host: PJLink.State].self
        ) { [password = self.password] group in
            for host in hosts {
                group.addTask {
                    let client = PJLink.Client(host: host, password: password)
                    print("Fetching current state for projector at \(host)")
                    let state = try await client.fetchState()
                    return HostState(host: host, state: state)
                }
            }
            var map = [NWEndpoint.Host: PJLink.State]()
            for try await hostState in group {
                map[hostState.host] = hostState.state
            }
            return map
        }

        let stateMapIsolated = LockIsolated(stateMap)

        let notificationListener = try PJLink.ClientNotificationListener()

        let listenerTask = Task {
            do {
                for try await notification in notificationListener.notificationStream {
                    print("Received \(notification.notification) from \(notification.host)")
                    // Look up the state with this host
                    stateMapIsolated.withValue { map in
                        if let state = map[notification.host] {
                            map[notification.host] = state.withNotification(notification.notification)
                        } else {
                            print("Could not find state for \(notification.host).")
                        }
                    }
                }
            } catch {
                print("Error in client notification stream: \(error)")
            }
            return true
        }

        var result = true
        while result {
            var clientIndex = 0
            let hosts = stateMapIsolated.value.keys.sorted()
            if hosts.count > 1 {
                printProjectorsMenu(hosts)
                print("Select a projector (or just Enter to exit): ", terminator: "")
                guard let line = readLine(), !line.isEmpty else { break }
                guard let index = Int(line), index >= 0, index < hosts.count else {
                    print("\"\(line)\" is not a valid projector index. Please enter an integer between 0 and \(hosts.count - 1) inclusive.")
                    continue
                }
                clientIndex = index
            }
            let host = hosts[clientIndex]
            if var state = stateMapIsolated.value[host] {
                result = await runMenuOnce(host: host, password: password, state: &state)
                stateMapIsolated.withValue { [state] map in
                    map[host] = state
                }
            }
        }

        print("Cancelling ClientNotificationListener.")
        notificationListener.cancel()
        _ = await listenerTask.value

        print("PJLinkClientCLI exiting.")
    }

    private func discoverByBroadcast() async throws -> [NWEndpoint.Host] {
        var projectors = [NWEndpoint.Host]()
        let broadcastAddress = try PJLink.IPAddressDiscovery.getBroadcastAddress()
        guard let broadcastAddress else {
            print("Could not determine broadcast address. Exiting.")
            return []
        }
        print("Discovering projectors using broadcast address of \(broadcastAddress) for 15 seconds...")
        let projectorDiscovery = try PJLink.UDPProjectorDiscovery(
            broadcastHost: broadcastAddress.host,
            duration: .seconds(15),
            progressUpdateCount: 15
        )
        for try await discoveryEvent in projectorDiscovery.outputStream {
            switch discoveryEvent {
            case .progressUpdate(let progress):
                print("\(progress.formatted(.percent.precision(.fractionLength(1))))...", terminator: "")
            case .projectorDiscovered(let projector):
                print("Discovered projector at \(projector.host)")
                projectors.append(projector.host)
            }
        }
        return projectors
    }

    private func discoverByPingSweep() async throws -> [NWEndpoint.Host] {
        guard let v4 = try PJLink.IPAddressDiscovery.enumerateInterfaces().compactMap(\.v4Triple).first else {
            print("Could not get an IPv4 interface. Exiting.")
            return []
        }
        // Compute the hosts to try
        let hosts = try PJLink.PingSweepProjectorDiscovery.hostsToPing(
            address: v4.address,
            netmask: v4.netmask,
            broadcast: v4.broadcast
        )
        let pingSweep = try PJLink.PingSweepProjectorDiscovery(hosts: hosts)
        var projectors = [NWEndpoint.Host]()
        for try await pingEvent in pingSweep.outputStream {
            switch pingEvent {
            case .progressUpdate(let progress):
                print("Ping Sweep Progress: \(progress * 100.0)")
                break
            case .projectorFound(let projector):
                print("Discovered projector at \(projector.host)")
                projectors.append(projector.host)
            }
        }
        return projectors
    }

    private func runMenuOnce(
        host: NWEndpoint.Host,
        password: String?,
        state: inout PJLink.State
    ) async -> Bool {
        printMenu()
        print("Enter an option to perform (or just Enter to exit): ", terminator: "")
        guard let line = readLine(), !line.isEmpty else { return false }

        guard let optionIndex = Int(line), let menuOption = MenuOption(rawValue: optionIndex) else {
            print("\"\(line)\" is not a valid option. Please try again.")
            return true
        }

        let client = PJLink.Client(host: host, password: password)

        switch menuOption {
        case .showState:
            print("Current state: \n\(state.description)")
        case .refreshState:
            do {
                let newState = try await client.fetchState()
                print("Refreshed state: \n\(newState.description)")
                state = newState
            } catch {
                print("Error refreshing state: \(error)")
            }
        case .setPowerStatus:
            // Get the user input
            printPowerStatusMenu()
            print("Enter 0 for Off, 1 for On (or Enter to return to main menu): ", terminator: "")
            guard let powerLine = readLine(), let onOff = PJLink.OnOff(rawValue: powerLine) else { break }
            do {
                // Make the API call
                let powerStatus = try await client.setPower(to: onOff)
                state.power = powerStatus
                print("Power Status set to \(powerStatus)")
            } catch {
                print("Error setting power status: \(error)")
            }
        case .setInput:
            // Get the user input
            let inputs = state.inputs
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
            do {
                // Make the API call
                let newInput = try await client.setInput(to: inputs[inputIndex])
                state.activeInput = newInput
                print("Input set to: \(newInput)")
            } catch {
                print("Error setting input: \(error)")
            }
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
            do {
                // Make the API call
                let newMuteState = try await client.setMuteState(to: allMuteStates[inputIndex])
                state.mute = newMuteState
                print("Mute set to: \(newMuteState)")
            } catch {
                print("Error setting mute: \(error)")
            }
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
            do {
                // Make the API call
                let volumeAdjustment = allVolumeAdjustments[inputIndex]
                try await client.setSpeakerVolume(to: volumeAdjustment)
                print("Speaker Volume set to: \(volumeAdjustment.displayName)")
            } catch {
                print("Error setting speaker volume: \(error)")
            }
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
            do {
                // Make the API call
                let volumeAdjustment = allVolumeAdjustments[inputIndex]
                try await client.setMicrophoneVolume(to: volumeAdjustment)
                print("Microphone Volume set to: \(volumeAdjustment.displayName)")
            } catch {
                print("Error setting microphone volume: \(error)")
            }
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
            do {
                // Make the API call
                let newFreeze = try await client.setFreeze(to: allFreeze[inputIndex])
                state.freeze = newFreeze
                print("Freeze set to: \(newFreeze)")
            } catch {
                print("Error setting freeze: \(error)")
            }
        }

        return true
    }

    private func printProjectorsMenu(_ hosts: [NWEndpoint.Host]) {
        hosts.enumerated().forEach { index, host in
            print("\(index)) \(host)")
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
        case refreshState = 2
        case setPowerStatus = 3
        case setInput = 4
        case setMuteStatus = 5
        case setSpeakerVolume = 6
        case setMicrophoneVolume = 7
        case setFreeze = 8

        var title: String {
            switch self {
            case .showState: "Show State"
            case .refreshState: "Refresh State"
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
