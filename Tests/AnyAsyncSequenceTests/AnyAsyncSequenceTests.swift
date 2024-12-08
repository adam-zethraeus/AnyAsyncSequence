import Testing
@testable import AnyAsyncSequence

@available(iOS 18.0, *)
@Test func ios18_test() async throws {
    let (stream, continuation) = AsyncStream.makeStream(of: Int.self)
    let sequence = AnyAsyncSequence(sequence: stream)
    var values: [Int] = []
    Task { [continuation] in
        for i in 0..<100 {
            _ = continuation.yield(i)
            try await Task.sleep(for: .milliseconds(Int.random(in: 1...10)))
        }
        continuation.finish()
    }
    for await value in sequence {
        values.append(value)
    }
    #expect(values == Array(repeating: 0, count: 100).reduce(into: [], { partialResult, next in
        let last = partialResult.last ?? -1
        partialResult.append(last + 1)
    }))
}

@available(iOS 17.0, *)
@Test func ios17_test() async throws {
    let (stream, continuation) = AsyncStream.makeStream(of: Int.self)
    let sequence = AnyAsyncSequence(element: Int.self, failure: Never.self, legacy: stream)
    var values: [Int] = []
    Task { [continuation] in
        for i in 0..<100 {
            _ = continuation.yield(i)
            try await Task.sleep(for: .milliseconds(Int.random(in: 1...10)))
        }
        continuation.finish()
    }
    for await value in sequence {
        values.append(value)
    }
    #expect(values == Array(repeating: 0, count: 100).reduce(into: [], { partialResult, next in
        let last = partialResult.last ?? -1
        partialResult.append(last + 1)
    }))
}
