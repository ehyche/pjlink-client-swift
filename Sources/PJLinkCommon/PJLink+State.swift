//
//  PJLink+State.swift
//  pjlink-client-swift
//
//  Created by Eric Hyche on 12/12/25.
//

extension PJLink {

    public enum State: Sendable, Codable {
        case class1(Class1State)
        case class2(Class2State)
    }

    public struct Class1State: Sendable, Codable {
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

        public init(
            power: PowerStatus,
            mute: MuteState,
            error: ErrorStatus,
            lamps: LampsStatus,
            inputSwitches: InputSwitchesClass1,
            activeInputSwitch: InputSwitchClass1,
            projectorName: ProjectorName,
            manufacturerName: ManufacturerName,
            productName: ProductName,
            otherInformation: OtherInformation
        ) {
            self.power = power
            self.mute = mute
            self.error = error
            self.lamps = lamps
            self.inputSwitches = inputSwitches
            self.activeInputSwitch = activeInputSwitch
            self.projectorName = projectorName
            self.manufacturerName = manufacturerName
            self.productName = productName
            self.otherInformation = otherInformation
        }
    }

    public struct Class2State: Sendable, Codable {
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
        public var speakerVolume: Volume
        public var microphoneVolume: Volume

        public init(
            power: PowerStatus,
            mute: MuteState,
            error: ErrorStatus,
            lamps: LampsStatus,
            inputSwitches: InputSwitchesClass2,
            activeInputSwitch: InputSwitchClass2,
            inputNames: [InputSwitchClass2 : InputTerminalName],
            projectorName: ProjectorName,
            manufacturerName: ManufacturerName,
            productName: ProductName,
            otherInformation: OtherInformation,
            serialNumber: SerialNumber,
            softwareVersion: SoftwareVersion,
            inputResolution: InputResolution,
            recommendedResolution: Resolution,
            filterUsageTime: FilterUsageTime,
            lampReplacementModelNumber: ModelNumber,
            filterReplacementModelNumber: ModelNumber,
            freeze: Freeze,
            speakerVolume: Volume = .init(),
            microphoneVolume: Volume = .init()
        ) {
            self.power = power
            self.mute = mute
            self.error = error
            self.lamps = lamps
            self.inputSwitches = inputSwitches
            self.activeInputSwitch = activeInputSwitch
            self.inputNames = inputNames
            self.projectorName = projectorName
            self.manufacturerName = manufacturerName
            self.productName = productName
            self.otherInformation = otherInformation
            self.serialNumber = serialNumber
            self.softwareVersion = softwareVersion
            self.inputResolution = inputResolution
            self.recommendedResolution = recommendedResolution
            self.filterUsageTime = filterUsageTime
            self.lampReplacementModelNumber = lampReplacementModelNumber
            self.filterReplacementModelNumber = filterReplacementModelNumber
            self.freeze = freeze
            self.speakerVolume = speakerVolume
            self.microphoneVolume = microphoneVolume
        }
    }
}

extension PJLink.Class1State {

    var inputs: [PJLink.Input] { inputSwitches.switches.map(\.asInput) }

    var activeInputIndex: Int? { inputSwitches.switches.firstIndex(of: activeInputSwitch) }

    func withPower(_ power: PJLink.PowerStatus) -> PJLink.Class1State {
        var mutableSelf = self
        mutableSelf.power = power
        return mutableSelf
    }

    public func withActiveInputSwitch(_ inputSwitch: PJLink.InputSwitchClass1) -> Self {
        var mutableSelf = self
        if let foundSwitchIndex = inputSwitches.switches.firstIndex(of: inputSwitch) {
            mutableSelf.activeInputSwitch = inputSwitches.switches[foundSwitchIndex]
        }
        return mutableSelf
    }

    public func withAVMute(_ muteState: PJLink.MuteState) -> Self {
        var mutableSelf = self
        mutableSelf.mute = muteState
        return mutableSelf
    }
}

extension PJLink.Class2State {

    var inputs: [PJLink.Input] { inputSwitches.switches.map { PJLink.Input(input: $0.input, channel: $0.channel, name: inputNames[$0]) } }

    var activeInputIndex: Int? { inputSwitches.switches.firstIndex(of: activeInputSwitch) }

    func withPower(_ power: PJLink.PowerStatus) -> Self {
        var mutableSelf = self
        mutableSelf.power = power
        return mutableSelf
    }

    public func withActiveInputSwitch(_ inputSwitch: PJLink.InputSwitchClass2) -> Self {
        var mutableSelf = self
        if let foundSwitchIndex = inputSwitches.switches.firstIndex(of: inputSwitch) {
            mutableSelf.activeInputSwitch = inputSwitches.switches[foundSwitchIndex]
        }
        return mutableSelf
    }

    public func withAVMute(_ muteState: PJLink.MuteState) -> Self {
        var mutableSelf = self
        mutableSelf.mute = muteState
        return mutableSelf
    }

    public func withSpeakerVolumeAdjustment(_ volumeAdjustment: PJLink.VolumeAdjustment) -> Self {
        var mutableSelf = self
        mutableSelf.speakerVolume = mutableSelf.speakerVolume.applyingAdjustment(volumeAdjustment)
        return mutableSelf
    }

    public func withMicrophoneVolumeAdjustment(_ volumeAdjustment: PJLink.VolumeAdjustment) -> Self {
        var mutableSelf = self
        mutableSelf.microphoneVolume = mutableSelf.microphoneVolume.applyingAdjustment(volumeAdjustment)
        return mutableSelf
    }

    public func withFreeze(_ freeze: PJLink.Freeze) -> Self {
        var mutableSelf = self
        mutableSelf.freeze = freeze
        return mutableSelf
    }
}

extension PJLink.State {

    public var `class`: PJLink.Class {
        switch self {
        case .class1: .one
        case .class2: .two
        }
    }

    public var power: PJLink.PowerStatus {
        set {
            switch self {
            case .class1(let class1State):
                self = .class1(class1State.withPower(newValue))
            case .class2(let class2State):
                self = .class2(class2State.withPower(newValue))
            }
        }
        get {
            switch self {
            case .class1(let class1State): class1State.power
            case .class2(let class2State): class2State.power
            }
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
        set {
            switch self {
            case .class1(let class1State):
                self = .class1(class1State.withAVMute(newValue))
            case .class2(let class2State):
                self = .class2(class2State.withAVMute(newValue))
            }
        }
        get {
            switch self {
            case .class1(let class1State): class1State.mute
            case .class2(let class2State): class2State.mute
            }
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

extension PJLink.State: CustomStringConvertible {

    public var description: String {
        switch self {
        case .class1(let class1State): class1State.description
        case .class2(let class2State): class2State.description
        }
    }
}

extension PJLink.Class1State: CustomStringConvertible {

    public var description: String {
        """
        class: 1
        power: \(power)
        mute: \(mute)
        error: \(error)
        lamps: \(lamps)
        inputSwitches: \(inputSwitches)
        activeInputSwitch: \(activeInputSwitch)
        projectorName: \(projectorName)
        manufacturerName: \(manufacturerName)
        productName: \(productName)
        otherInformation: \(otherInformation)
        """
    }
}

extension PJLink.Class2State: CustomStringConvertible {

    public var description: String {
        """
        class: 2
        power: \(power)
        mute: \(mute)
        error: \(error)
        lamps: \(lamps)
        inputSwitches: \(inputSwitches)
        activeInputSwitch: \(activeInputSwitch)
        projectorName: \(projectorName)
        manufacturerName: \(manufacturerName)
        productName: \(productName)
        otherInformation: \(otherInformation)
        serialNumber: \(serialNumber)
        softwareVersion: \(softwareVersion)
        inputResolution: \(inputResolution)
        recommendedResolution: \(recommendedResolution)
        filterUsageTime: \(filterUsageTime)
        lampReplacementModelNumber: \(lampReplacementModelNumber)
        filterReplacementModelNumber: \(filterReplacementModelNumber)
        freeze: \(freeze)
        """
    }
}
