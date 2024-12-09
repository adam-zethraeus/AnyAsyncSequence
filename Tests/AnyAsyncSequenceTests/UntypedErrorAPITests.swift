import Testing
import AnyAsyncSequence

@Suite("AnyAsyncSequence legacy untyped error API tests")
struct UntypedErrorAPITests {

    @Test func nonThrowingForAwait() async throws {
        let (stream, continuation) = AsyncStream.makeStream(of: Int.self)
        let sequence = AnyAsyncSequence(sequence: stream)
        var values: [Int] = []
        
        TestUtils.yieldZeroTo(10_000, with: continuation)
        for try await value in sequence {
            values.append(value)
        }
        
        #expect(values == Array(0..<10_000))
    }

    @Test func throwingForAwait_thatThrows() async throws {
        let (stream, continuation) = AsyncStream.makeStream(of: Int.self)
        let throwingStream = stream.map { (i: Int) throws -> Int in
            if i == 8998 {
                throw TestUtils.TestError(description: "value would be 8998")
            }
            return i
        }
        let sequence = AnyAsyncSequence<Int, any Error>(sequence: throwingStream)
        var values: [Int] = []
        
        TestUtils.yieldZeroTo(10_000, with: continuation)
        
        await #expect(throws: TestUtils.TestError.self, performing: {
            for try await value in sequence {
                values.append(value)
            }
        })
        #expect(values == Array(0..<8998))
    }
}
