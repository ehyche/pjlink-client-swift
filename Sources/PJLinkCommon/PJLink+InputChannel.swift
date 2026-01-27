//
//  PJLink+InputChannel.swift
//  pjlink-client-swift
//
//  Created by Eric Hyche on 10/20/25.
//

extension PJLink {
    public enum InputChannelClass1: String, CaseIterable, Sendable, Codable {
        case one = "1"
        case two = "2"
        case three = "3"
        case four = "4"
        case five = "5"
        case six = "6"
        case seven = "7"
        case eight = "8"
        case nine = "9"
    }

    public enum InputChannelClass2: String, CaseIterable, Sendable, Codable {
        case one = "1"
        case two = "2"
        case three = "3"
        case four = "4"
        case five = "5"
        case six = "6"
        case seven = "7"
        case eight = "8"
        case nine = "9"
        case a = "A"
        case b = "B"
        case c = "C"
        case d = "D"
        case e = "E"
        case f = "F"
        case g = "G"
        case h = "H"
        case i = "I"
        case j = "J"
        case k = "K"
        case l = "L"
        case m = "M"
        case n = "N"
        case o = "O"
        case p = "P"
        case q = "Q"
        case r = "R"
        case s = "S"
        case t = "T"
        case u = "U"
        case v = "V"
        case w = "W"
        case x = "X"
        case y = "Y"
        case z = "Z"
    }
}

extension PJLink.InputChannelClass1 {

    public var asClass2: PJLink.InputChannelClass2 {
        switch self {
        case .one: .one
        case .two: .two
        case .three: .three
        case .four: .four
        case .five: .five
        case .six: .six
        case .seven: .seven
        case .eight: .eight
        case .nine: .nine
        }
    }
}

extension PJLink.InputChannelClass2 {

    public var asClass1: PJLink.InputChannelClass1? {
        switch self {
        case .one: .one
        case .two: .two
        case .three: .three
        case .four: .four
        case .five: .five
        case .six: .six
        case .seven: .seven
        case .eight: .eight
        case .nine: .nine
        default: nil
        }
    }
}
