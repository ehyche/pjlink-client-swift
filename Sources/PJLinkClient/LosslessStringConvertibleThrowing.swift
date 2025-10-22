//
//  LosslessStringConvertibleThrowing.swift
//  pjlink-client-swift
//
//  Created by Eric Hyche on 10/21/25.
//

public protocol LosslessStringConvertibleThrowing: CustomStringConvertible {
    init(_ description: String) throws
}
