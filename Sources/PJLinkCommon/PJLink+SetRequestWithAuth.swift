//
//  PJLink+SetRequestWithAuth.swift
//  pjlink-client-swift
//
//  Created by Eric Hyche on 9/2/26.
//

extension PJLink {

    public struct SetRequestWithAuth: Equatable, Sendable {
        public let request: SetRequest
        public let authPrefix: AuthPrefix

        public init(_ request: SetRequest, authPrefix: AuthPrefix = .none) {
            self.request = request
            self.authPrefix = authPrefix
        }
    }
}

extension PJLink.SetRequestWithAuth: CustomStringConvertible {

    public var description: String {
        authPrefix.description + request.description
    }
}

extension PJLink.SetRequestWithAuth: PJLink.MessageSizeRange {

    public var messageSizeRange: ClosedRange<Int> {
        let lowerBound = authPrefix.messageSizeRange.lowerBound + request.messageSizeRange.lowerBound
        let upperBound = authPrefix.messageSizeRange.upperBound + request.messageSizeRange.upperBound
        return lowerBound...upperBound
    }
}

extension PJLink.SetRequestWithAuth: CaseIterable {

    public static var allCases: [Self] {
        var result: [Self] = []
        for request in PJLink.SetRequest.allCases {
            for authPrefix in PJLink.AuthPrefix.allCases {
                result.append(.init(request, authPrefix: authPrefix))
            }
        }
        return result
    }
}
