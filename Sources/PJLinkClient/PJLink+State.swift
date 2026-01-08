//
//  PJLink+State.swift
//  pjlink-client-swift
//
//  Created by Eric Hyche on 12/12/25.
//

extension PJLink {

    public enum State {
        case class1(Class1State)
        case class2(Class2State)
    }

    public struct Class1State {
        public var power: PowerStatus
        public var mute: MuteState
        public var error: ErrorStatus
        public var lamps: LampsStatus
        public var inputSwitches: InputSwitchesClass1
        public var activeInputSwitch: InputSwitchClass1
        public var projectorName: ProjectorName
        public var manufacturerName: ManufacturerName
        public var productName: ProductName
        public var otherInformation: OtherInformation
    }

    public struct Class2State {
        public var power: PowerStatus
        public var mute: MuteState
        public var error: ErrorStatus
        public var lamps: LampsStatus
        public var inputSwitches: InputSwitchesClass2
        public var activeInputSwitch: InputSwitchClass2
        public var inputNames: [InputSwitchClass2: InputTerminalName]
        public var projectorName: ProjectorName
        public var manufacturerName: ManufacturerName
        public var productName: ProductName
        public var otherInformation: OtherInformation
        public var serialNumber: SerialNumber
        public var softwareVersion: SoftwareVersion
        public var inputResolution: InputResolution
        public var recommendedResolution: Resolution
        public var filterUsageTime: FilterUsageTime
        public var lampReplacementModelNumber: ModelNumber
        public var filterReplacementModelNumber: ModelNumber
        public var freeze: Freeze
    }
}

extension PJLink.Class1State {

    var inputs: [PJLink.Input] { inputSwitches.switches.map(\.asInput) }

    var activeInputIndex: Int? { inputSwitches.switches.firstIndex(of: activeInputSwitch) }
}

extension PJLink.Class2State {

    var inputs: [PJLink.Input] { inputSwitches.switches.map { PJLink.Input(input: $0.input, channel: $0.channel, name: inputNames[$0]) } }

    var activeInputIndex: Int? { inputSwitches.switches.firstIndex(of: activeInputSwitch) }
}

extension PJLink.State {

    public var `class`: PJLink.Class {
        switch self {
        case .class1: .one
        case .class2: .two
        }
    }

    public var power: PJLink.PowerStatus {
        switch self {
        case .class1(let class1State): class1State.power
        case .class2(let class2State): class2State.power
        }
    }

    public var inputs: [PJLink.Input] {
        switch self {
        case .class1(let class1State): class1State.inputs
        case .class2(let class2State): class2State.inputs
        }
    }

    public var activeInputIndex: Int? {
        switch self {
        case .class1(let class1State): class1State.activeInputIndex
        case .class2(let class2State): class2State.activeInputIndex
        }
    }

    public var mute: PJLink.MuteState {
        switch self {
        case .class1(let class1State): class1State.mute
        case .class2(let class2State): class2State.mute
        }
    }

    public var error: PJLink.ErrorStatus {
        switch self {
        case .class1(let class1State): class1State.error
        case .class2(let class2State): class2State.error
        }
    }

    public var lamps: PJLink.LampsStatus {
        switch self {
        case .class1(let class1State): class1State.lamps
        case .class2(let class2State): class2State.lamps
        }
    }

    public var projectorName: PJLink.ProjectorName {
        switch self {
        case .class1(let class1State): class1State.projectorName
        case .class2(let class2State): class2State.projectorName
        }
    }

    public var manufacturerName: PJLink.ManufacturerName {
        switch self {
        case .class1(let class1State): class1State.manufacturerName
        case .class2(let class2State): class2State.manufacturerName
        }
    }

    public var productName: PJLink.ProductName {
        switch self {
        case .class1(let class1State): class1State.productName
        case .class2(let class2State): class2State.productName
        }
    }

    public var otherInformation: PJLink.OtherInformation {
        switch self {
        case .class1(let class1State): class1State.otherInformation
        case .class2(let class2State): class2State.otherInformation
        }
    }

    public var serialNumber: PJLink.SerialNumber? {
        switch self {
        case .class1: nil
        case .class2(let class2State): class2State.serialNumber
        }
    }

    public var softwareVersion: PJLink.SoftwareVersion? {
        switch self {
        case .class1: nil
        case .class2(let class2State): class2State.softwareVersion
        }
    }

    public var inputResolution: PJLink.InputResolution? {
        switch self {
        case .class1: nil
        case .class2(let class2State): class2State.inputResolution
        }
    }

    public var recommendedResolution: PJLink.Resolution? {
        switch self {
        case .class1: nil
        case .class2(let class2State): class2State.recommendedResolution
        }
    }

    public var filterUsageTime: PJLink.FilterUsageTime? {
        switch self {
        case .class1: nil
        case .class2(let class2State): class2State.filterUsageTime
        }
    }

    public var lampReplacementModelNumber: PJLink.ModelNumber? {
        switch self {
        case .class1: nil
        case .class2(let class2State): class2State.lampReplacementModelNumber
        }
    }

    public var filterReplacementModelNumber: PJLink.ModelNumber? {
        switch self {
        case .class1: nil
        case .class2(let class2State): class2State.filterReplacementModelNumber
        }
    }

    public var freeze: PJLink.Freeze? {
        switch self {
        case .class1: nil
        case .class2(let class2State): class2State.freeze
        }
    }
}
