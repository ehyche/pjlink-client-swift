//
//  PJLink+GetResponse.swift
//  pjlink-client-swift
//
//  Created by Eric Hyche on 10/20/25.
//

extension PJLink {

    public enum GetResponse {
        case power(GetResult<PJLink.PowerStatus>)
        case inputSwitch(GetResult<PJLink.InputSwitch>)
        case avMute(GetResult<PJLink.MuteState>)
        case errorStatus(GetResult<PJLink.ErrorStatus>)
        case lamp(GetResult<PJLink.LampsStatus>)
        case inputList(GetResult<PJLink.InputSwitches>)
        case projectorName(GetResult<String>)
        case manufacturerName(GetResult<String>)
        case productName(GetResult<String>)
        case otherInformation(GetResult<String>)
        case projectorClass(GetResult<PJLink.Class>)
        case serialNumber(GetResult<String>)
        case softwareVersion(GetResult<String>)
        case inputTerminalName(GetResult<String>)
        case inputResolution(GetResult<InputResolution>)
        case recommendedResolution(GetResult<Resolution>)
        case filterUsageTime(GetResult<Int>)
        case lampReplacementModelNumber(GetResult<[String]>)
        case filterReplacementModelNumber(GetResult<[String]>)
        case freeze(GetResult<OnOff>)
    }
}
