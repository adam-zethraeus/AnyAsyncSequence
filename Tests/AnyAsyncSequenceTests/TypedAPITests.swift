import Testing
import AnyAsyncSequence

@Suite("AnyAsyncSequence API tests")
struct TypedAPITests {

    @available(iOS 18, *)
    @Test func nonThrowingForAwait() async throws {
        let (stream, continuation) = AsyncStream.makeStream(of: Int.self)
        let sequence = AnyAsyncSequence<Int, Never>(sequence: stream)
        var values: [Int] = []
        
        TestUtils.yieldZeroTo(10_000, with: continuation)
        for await value in sequence {
            values.append(value)
        }
        
        #expect(values == Array(0..<10_000))
    }
    
    @available(iOS 18, *)
    @Test func throwingForAwait() async throws {
        let (stream, continuation) = AsyncThrowingStream.makeStream(of: Int.self, throwing: (any Error).self, bufferingPolicy: .unbounded)
        let sequence = AnyAsyncSequence<Int, any Error>(sequence: stream)
        var values: [Int] = []
        
        TestUtils.yieldZeroTo(10_000, with: continuation)
        for try await value in sequence {
            values.append(value)
        }
        
        #expect(values == Array(0..<10_000))
    }
}
