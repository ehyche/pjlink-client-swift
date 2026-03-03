//
//  PJLink+AsyncTimer.swift
//  pjlink-client-swift
//
//  Created by Eric Hyche on 2/6/26.
//

import AsyncAlgorithms
import Foundation

extension PJLink {

    public struct AsyncTimer: Sendable {
        let timerTask: Task<Void, any Swift.Error>

        public init(
            every duration: Duration,
            count: Int? = nil,
            work: @escaping @Sendable () -> Void
        ) {
            let asyncSequence: any AsyncSequence
            if let count {
                asyncSequence = AsyncTimerSequence.repeating(every: duration).prefix(count)
            } else {
                asyncSequence = AsyncTimerSequence.repeating(every: duration)
            }
            timerTask = Task {
                for try await _ in asyncSequence {
                    try Task.checkCancellation()
                    work()
                }
            }
        }

        public init(
            every duration: Duration,
            count: Int? = nil,
            work: @escaping @Sendable () async -> Void
        ) {
            let asyncSequence: any AsyncSequence
            if let count {
                asyncSequence = AsyncTimerSequence.repeating(every: duration).prefix(count)
            } else {
                asyncSequence = AsyncTimerSequence.repeating(every: duration)
            }
            timerTask = Task {
                for try await _ in asyncSequence {
                    try Task.checkCancellation()
                    await work()
                }
            }
        }

        public init(
            every duration: Duration,
            count: Int? = nil,
            work: @escaping @Sendable () async throws -> Void
        ) {
            let asyncSequence: any AsyncSequence
            if let count {
                asyncSequence = AsyncTimerSequence.repeating(every: duration).prefix(count)
            } else {
                asyncSequence = AsyncTimerSequence.repeating(every: duration)
            }
            timerTask = Task {
                for try await _ in asyncSequence {
                    try Task.checkCancellation()
                    try await work()
                }
            }
        }

        public func cancel() {
            timerTask.cancel()
        }
    }
}
