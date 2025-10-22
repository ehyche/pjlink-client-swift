//
//  PJLink+GetResult.swift
//  pjlink-client-swift
//
//  Created by Eric Hyche on 10/20/25.
//

extension PJLink {

    public enum GetResult<T> {
        case ok(T)
        case error(PJLink.Error)
    }
}
