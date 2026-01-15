//
//  PJLink+StateActor.swift
//  pjlink-client-swift
//
//  Created by Eric Hyche on 1/14/26.
//

extension PJLink {

    public actor StateActor {
        public var state: State

        public init(state: State) {
            self.state = state
        }
    }
}
