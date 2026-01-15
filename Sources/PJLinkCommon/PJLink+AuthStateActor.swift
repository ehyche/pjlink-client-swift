//
//  PJLink+AuthStateActor.swift
//  pjlink-client-swift
//
//  Created by Eric Hyche on 1/14/26.
//

extension PJLink {

    public actor AuthStateActor {
        public var state: AuthState

        public init(state: AuthState) {
            self.state = state
        }
    }
}
