public struct AnyAsyncSequence<Element, Failure: Error>: AsyncSequence {
    
    @available(iOS 18, *)
    public init(sequence: some AsyncSequence<Element, Failure>) {
        self.makeAsyncIteratorFunc = {
            AnyAsyncIterator(iterator: sequence.makeAsyncIterator())
        }
    }
    
    @_disfavoredOverload
    public init<S: AsyncSequence>(sequence: S) where Element == S.Element, Failure == any Error {
        self.makeAsyncIteratorFunc = {
            AnyAsyncIterator(legacyIterator: sequence.makeAsyncIterator())
        }
    }
    
    private let makeAsyncIteratorFunc: () -> AnyAsyncIterator<Element, Failure>
    
    public func makeAsyncIterator() -> AnyAsyncIterator<Element, Failure> {
        makeAsyncIteratorFunc()
    }
    
    public typealias AsyncIterator = AnyAsyncIterator<Element, Failure>
    
    
}

public struct AnyAsyncIterator<Element, Failure: Error>: AsyncIteratorProtocol {
    @available(iOS 18.0, *)
    fileprivate init(iterator: some AsyncIteratorProtocol<Element, Failure>) {
        self.iterator = ModernIterator(iterator: iterator)
    }
    fileprivate init<I: AsyncIteratorProtocol>(legacyIterator: I) where Element == I.Element, Failure == any Error {
        self.iterator = legacyIterator
    }
    var iterator: any AsyncIteratorProtocol
    
    @available(iOS 18.0, macOS 18.0, tvOS 18.0, watchOS 18.0, *)
    var modernIterator: (any AsyncIteratorProtocol<Element, Failure>) {
        _read {
            yield (iterator as! (any AsyncIteratorProtocol<Element, Failure>))
        }
        _modify {
            var it = (iterator as! (any AsyncIteratorProtocol<Element, Failure>))
            yield &it
            iterator = it
        }
    }
    @available(iOS 18.0, *)
    public mutating func next(isolation isolatedToActor: isolated (any Actor)?) async throws(Failure) -> Element? {
        try await modernIterator.next(isolation: isolatedToActor)
    }
    
    public mutating func next() async throws(Failure) -> Element? {
        do {
            return try await iterator.next() as? Element
        } catch {
            throw error as! Failure
        }
    }
}

@available(iOS 18.0, macOS 18.0, tvOS 18.0, watchOS 18.0, *)
struct ModernIterator<Element, Failure: Error>: AsyncIteratorProtocol {
    public mutating func next() async throws -> Element? {
        try await iterator.next()
    }
    
    public typealias Element = Element
    public typealias Failure = Failure
    
    public init(iterator: some AsyncIteratorProtocol<Element, Failure>) {
        self.iterator = iterator
    }

    var iterator: any AsyncIteratorProtocol<Element, Failure>
    
    public mutating func next(isolation actor: isolated (any Actor)?) async throws(Failure) -> Element? {
        try await iterator.next(isolation: actor)
    }
}

#if DEBUG
import Foundation
extension ProcessInfo {
  fileprivate var isTesting: Bool {
    if environment.keys.contains("XCTestBundlePath") { return true }
    if environment.keys.contains("XCTestConfigurationFilePath") { return true }
    if environment.keys.contains("XCTestSessionIdentifier") { return true }

    return arguments.contains { argument in
      let path = URL(fileURLWithPath: argument)
      return path.lastPathComponent == "swiftpm-testing-helper"
        || argument == "--testing-library"
        || path.lastPathComponent == "xctest"
        || path.pathExtension == "xctest"
    }
  }
}
#endif
