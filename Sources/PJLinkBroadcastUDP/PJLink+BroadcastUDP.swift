//
//  PJLink+BroadcastUDP.swift
//  pjlink-client-swift
//
//  Created by Eric Hyche on 2/23/26.
//

import Foundation
import PJLinkCommon
import NIOCore
import NIOPosix
import os
#if canImport(Darwin)
import CNIODarwin
#endif

extension PJLink {
    public enum BroadcastUDP {
        public static func sendBroadcastUDP(
            data: String,
            broadcastHost: String,
            broadcastPort: Int
        ) throws -> Int {
            let logger = Logger(sub: .client, cat: .search)
            do {
                logger.debug("Creating SocketAddress with host=\(broadcastHost), port=\(broadcastPort)")
                let remoteAddress = try SocketAddress.makeAddressResolvingHost(broadcastHost, port: broadcastPort)

                // Create datagram socket
                logger.debug("Creating Socket(\(remoteAddress.protocol), .datagram, .default")
                let socket = try Socket(protocolFamily: remoteAddress.protocol, type: .datagram, protocolSubtype: .default)

                // Set the SO_BROADCAST option
                let value: Int32 = 1
                try socket.setOption(level: .socket, name: .so_broadcast, value: value)

                // Check to make sure the SO_BROADCAST flag is set
                let optionValue: Int32 = try socket.getOption(level: .socket, name: .so_broadcast)
                guard optionValue != 0 else {
                    throw PJLink.Error.broadcastUDPSocketBroadcastFlagCannotBeSet
                }
                logger.debug("Successfully set SO_BROADCAST flag on socket.")

                // Send a message
                logger.debug("Sending \"\(data)\" to socket.")
                let msgBuffer = ByteBuffer(string: data)
                let writeResult = try remoteAddress.withSockAddr { (addrPtr, addrSize) in
                    try msgBuffer.withUnsafeReadableBytes { buffPtr in
                        try socket.sendmsg(
                            pointer: buffPtr,
                            destinationPtr: addrPtr,
                            destinationSize: socklen_t(addrSize),
                            controlBytes: UnsafeMutableRawBufferPointer(start: nil, count: 0)
                        )
                    }
                }

                logger.debug("Closing socket.")
                try socket.close()

                switch writeResult {
                case .processed(let count):
                    logger.debug("Successfully sent \(count) bytes to socket.")
                    return count
                case .wouldBlock:
                    throw PJLink.Error.broadcastUDPSocketWouldBlock
                }
            } catch let socketAddressError as SocketAddressError {
                logger.error("BroadcastUDP: SocketAddressError: \(socketAddressError)")
                throw PJLink.Error.broadcastUDPSocketAddress(socketAddressError.localizedDescription)
            } catch let ioError as IOError {
                logger.error("BroadcastUDP: IOError: \(ioError)")
                throw PJLink.Error.broadcastUDPSocketIO(ioError.errnoCode, ioError.description)
            } catch let pjlinkError as PJLink.Error {
                logger.error("BroadcastUDP: PJLink.Error: \(pjlinkError)")
                throw pjlinkError
            } catch {
                logger.error("BroadcastUDP: General Error: \(error)")
                throw PJLink.Error.broadcastUDPSocketGeneral(error.localizedDescription)
            }
        }
    }
}

extension NIOBSDSocket.ProtocolFamily: @retroactive CustomStringConvertible {

    public var description: String {
        switch rawValue {
        case PF_INET: ".inet"
        case PF_INET6: ".inet6"
#if !os(WASI)
        case PF_UNIX: ".unix"
#endif
#if !os(Windows) && !os(WASI)
        case PF_LOCAL: ".local"
#endif
#if canImport(Darwin) || os(Linux) || os(Android)
        case PF_VSOCK: ".vsock"
#endif
        default: "ProtocolFamily(rawValue: \(rawValue))"
        }
    }
}
