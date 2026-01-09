//
//  PJLink+HexCharacter.swift
//  pjlink-client-swift
//
//  Created by Eric Hyche on 12/19/25.
//

extension PJLink {

    public enum HexCharacter: Character {
        case zero = "0"
        case one = "1"
        case two = "2"
        case three = "3"
        case four = "4"
        case five = "5"
        case six = "6"
        case seven = "7"
        case eight = "8"
        case nine = "9"
        case a = "a"
        case b = "b"
        case c = "c"
        case d = "d"
        case e = "e"
        case f = "f"
    }
}

extension PJLink.HexCharacter {

    init(_ char: Character) throws {
        switch char {
        case "0": self = .zero
        case "1": self = .one
        case "2": self = .two
        case "3": self = .three
        case "4": self = .four
        case "5": self = .five
        case "6": self = .six
        case "7": self = .seven
        case "8": self = .eight
        case "9": self = .nine
        case "a", "A": self = .a
        case "b", "B": self = .b
        case "c", "C": self = .c
        case "d", "D": self = .d
        case "e", "E": self = .e
        case "f", "F": self = .f
        default:
            throw PJLink.Error.invalidHexCharacter(char)
        }
    }

    var uint8Value: UInt8 {
        switch self {
        case .zero: 0
        case .one: 1
        case .two: 2
        case .three: 3
        case .four: 4
        case .five: 5
        case .six: 6
        case .seven: 7
        case .eight: 8
        case .nine: 9
        case .a: 10
        case .b: 11
        case .c: 12
        case .d: 13
        case .e: 14
        case .f: 15
        }
    }
}
