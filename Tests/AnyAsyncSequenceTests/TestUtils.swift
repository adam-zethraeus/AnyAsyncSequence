import Testing

enum TestUtils {
    struct TestError: Error {
        var description: String
    }
    
    static func yieldZeroTo(_ n: Int, with continuation: AsyncStream<Int>.Continuation) {
        Task {
            for i in 0..<10_000 {
                _ = continuation.yield(i)
                try #require(try await Task.sleep(for: .microseconds(Int.random(in: 1...10))))
            }
            continuation.finish()
        }
    }
    static func yieldZeroTo(_ n: Int, with continuation: AsyncThrowingStream<Int, any Error>.Continuation) {
        Task {
            for i in 0..<10_000 {
                _ = continuation.yield(i)
                try #require(try await Task.sleep(for: .microseconds(Int.random(in: 1...10))))
            }
            continuation.finish()
        }
    }
}
