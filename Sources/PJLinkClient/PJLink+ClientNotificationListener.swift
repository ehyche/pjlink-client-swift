//
//  PJLink+ClientNotificationListener.swift
//  pjlink-client-swift
//
//  Created by Eric Hyche on 2/2/26.
//

import ConcurrencyExtras
import Network
import os
import PJLinkCommon

extension PJLink {

    public struct ClientNotificationListener {
        public struct NotificationInfo: Equatable, Sendable {
            public let host: NWEndpoint.Host
            public let notification: PJLink.Notification
        }

        private let udpListener: UDPListener
        public let notificationStream: AsyncThrowingStream<NotificationInfo, Swift.Error>
        private let logger: Logger

        public init() throws {
            logger = Logger(sub: .client, cat: .listener)
            logger.debug("Create ClientNotificationListener")
            udpListener = try UDPListener(port: .pjlink)
            notificationStream = udpListener
                .outputStream
                .compactMap(Self.toNotificationInfo(_:))
                .eraseToThrowingStream()
        }

        public func cancel() {
            logger.debug("Cancel ClientNotificationListener")
            udpListener.cancel()
        }

        private static func toNotificationInfo(_ output: PJLink.UDPListener.Output) -> NotificationInfo? {
            let logger = Logger(sub: .client, cat: .listener)
            guard let utf8String = String(data: output.data, encoding: .utf8) else {
                logger.error("Could not convert data to UTF8 string.")
                return nil
            }
            guard let host = output.host else {
                logger.error("Client notification \"\(utf8String, privacy: .public)\" missing host.")
                return nil
            }
            let utf8MinusCR = utf8String.removingCRSuffix
            guard let notification = try? PJLink.Notification(utf8MinusCR) else {
                logger.error("Could not parse \"\(utf8MinusCR)\" as notification")
                return nil
            }
            return .init(host: host, notification: notification)
        }
    }
}
