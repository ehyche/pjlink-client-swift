extension Array where Element == ClosedRange<Int> {

    public var minMax: ClosedRange<Int>? {
        guard !isEmpty else { return nil }
        return reduce(self[0]) { partialResult, element in
            let lowerBound = Swift.min(partialResult.lowerBound, element.lowerBound)
            let upperBound = Swift.max(partialResult.upperBound, element.upperBound)
            return lowerBound...upperBound
        }
    }
}
