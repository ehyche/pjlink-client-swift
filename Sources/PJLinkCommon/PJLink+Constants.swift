//
//  PJLink+Constants.swift
//  pjlink-client-swift
//
//  Created by Eric Hyche on 10/17/25.
//

extension PJLink {
    public static let identifier = "%"
    public static let identifierCharacter: Character = "%"
    public static let terminatorByte: UInt8 = 13
    public static let separatorRequest = " "
    public static let separatorResponse = "="
    public static let prefixGet = "?"
    public static let terminator = "\r"
    public static let pjlink = "PJLINK"
    public static let maxRequestSize = 136
    public static let maxResponseSize = 136
    public static let maxAuthRequestSize = 96
    public static let class1AuthRequestSize = 32
    public static let class2AuthRequestSize = 96
    public static let class2RandomNumberCount = 32
    public static let class2HashCount = 64
}
