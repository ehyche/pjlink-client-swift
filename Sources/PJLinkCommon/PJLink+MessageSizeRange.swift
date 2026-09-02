extension PJLink {

    public protocol MessageSizeRange {
        var messageSizeRange: ClosedRange<Int> { get }
    }
}

extension PJLink.MessageSizeRange where Self: CaseIterable {

    static var minMaxMessageSize: ClosedRange<Int> {
        return allCases.map(\.messageSizeRange).minMax ?? 0...0
    }
}
