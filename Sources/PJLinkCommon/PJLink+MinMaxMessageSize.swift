//
//  PJLink+MinMaxMessageSize.swift
//  pjlink-client-swift
//
//  Created by Eric Hyche on 9/2/26.
//

extension PJLink {

    public protocol MinMaxMessageSize {

        static var minMaxMessageSize: ClosedRange<Int> { get }
    }
}
