//
//  PJLink+GetRequestWithAuth.swift
//  pjlink-client-swift
//
//  Created by Eric Hyche on 9/2/26.
//

extension PJLink {

    public struct GetRequestWithAuth: Equatable, Sendable {
        public let request: GetRequest
        public let authPrefix: AuthPrefix

        public init(_ request: GetRequest, authPrefix: AuthPrefix = .none) {
            self.request = request
            self.authPrefix = authPrefix
        }
    }
}

extension PJLink.GetRequestWithAuth: CustomStringConvertible {

    public var description: String {
        authPrefix.description + request.description
    }
}

extension PJLink.GetRequestWithAuth: PJLink.MessageSizeRange {

    public var messageSizeRange: ClosedRange<Int> {
        let lowerBound = authPrefix.messageSizeRange.lowerBound + request.messageSizeRange.lowerBound
        let upperBound = authPrefix.messageSizeRange.upperBound + request.messageSizeRange.upperBound
        return lowerBound...upperBound
    }
}

extension PJLink.GetRequestWithAuth: CaseIterable {

    public static var allCases: [Self] {
        var result: [Self] = []
        for request in PJLink.GetRequest.allCases {
            for authPrefix in PJLink.AuthPrefix.allCases {
                result.append(.init(request, authPrefix: authPrefix))
            }
        }
        return result
    }
}
