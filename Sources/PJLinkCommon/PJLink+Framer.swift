import Network
import os

public final class PJLinkFramer: NWProtocolFramerImplementation, FramerProtocol {
    public static let label = "PJLinkFramer"
    public static let definition = NWProtocolFramer.Definition(implementation: PJLinkFramer.self)
    static let delimiter: UInt8 = 0x0d // CR
    let logger: Logger

    public required init(framer: NWProtocolFramer.Instance) {
        logger = Logger(sub: .common, cat: .framer)
    }

    public func start(framer: NWProtocolFramer.Instance) -> NWProtocolFramer.StartResult {
        logger.debug("start(framer:)")
        return .ready
    }

    public func handleInput(framer: NWProtocolFramer.Instance) -> Int {
        logger.debug("handleInput(framer[\(framer.debugDescription)]")
        while true {
            var delimiterIndex: Int? = nil
            let parseResult = framer.parseInput(
                minimumIncompleteLength: PJLink.minRequestSize,
                maximumLength: 1024 // TODO: provide exact number here
            ) { buffer, isComplete in
                guard let buffer else {
                    logger.debug("\tparseInput(find) completion: nil buffer, returning 0")
                    return 0
                }
                let debugStr = String(bytes: buffer, encoding: .utf8)?.replacingCR ?? "<Non-UTF8 buffer of length \(buffer.count)>"
                logger.debug("\tparseInput(find) completion: (buffer: \"\(debugStr)\", isComplete: \(isComplete))")
                if let index = buffer.firstIndex(of: Self.delimiter) {
                    delimiterIndex = index
                }
                return 0
            }
            guard parseResult else {
                logger.debug("\tparseInput(find) returned false, returning 0")
                return 0
            }
            if let delimiterIndex {
                logger.debug("\tdelimiter found at index \(delimiterIndex)")
                // Deliver delimiterIndex bytes to the application
                let deliverResult = framer.deliverInputNoCopy(length: delimiterIndex, message: .init(instance: framer), isComplete: true)
                if !deliverResult {
                    logger.debug("\tframer.deliverInputNoCopy(length: \(delimiterIndex),,) returned false.")
                    return 0
                }
                // Advance the cursor by 1 byte (skipping the delimiter)
                let skipResult = framer.parseInput(
                    minimumIncompleteLength: 0,
                    maximumLength: 1024
                ) { buffer, isComplete in
                    guard let buffer else {
                        logger.debug("\tparseInput(skip) completion: nil buffer, returning 0")
                        return 0
                    }
                    let debugStr = String(bytes: buffer, encoding: .utf8)?.replacingCR ?? "<Non-UTF8 buffer of length \(buffer.count)>"
                    logger.debug("\tparseInput(skip) completion: (buffer: \"\(debugStr)\", isComplete: \(isComplete))")
                    return 1
                }
                if !skipResult {
                    logger.debug("\tframer.parseInput(skip) returned false.")
                    return 0
                }
            } else {
                logger.debug("\tNo delimiter found, returning 0")
                return 0
            }
        }
        return 0
    }

    public func handleOutput(framer: NWProtocolFramer.Instance, message: NWProtocolFramer.Message, messageLength: Int, isComplete: Bool) {
        logger.debug("handleOutput(framer[\(framer.debugDescription)], message:, messageLength: \(messageLength), isComplete: \(isComplete))")
        do {
            try framer.writeOutputNoCopy(length: messageLength)
            framer.writeOutput(data: [Self.delimiter])
        } catch {
            logger.error("framer.writeOutputNoCopy(length: \(messageLength)) threw error: \(error)")
        }
    }

    public func wakeup(framer: NWProtocolFramer.Instance) {
        logger.debug("wakeup(framer:)")
    }

    public func stop(framer: NWProtocolFramer.Instance) -> Bool {
        logger.debug("stop(framer:)")
        return true
    }

    public func cleanup(framer: NWProtocolFramer.Instance) {
        logger.debug("cleanup(framer:)")
    }
}
