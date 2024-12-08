public struct AnyAsyncSequence<Element, Failure: Error>: AsyncSequence {
    
    @available(iOS 18.0, *)
    public init(sequence: some AsyncSequence<Element, Failure>) {
        self.makeAsyncIteratorFunc = {
            AnyAsyncIterator(iterator: sequence.makeAsyncIterator())
        }
    }
    
    @available(iOS 17.0, *)
    @available(iOS, obsoleted: 18.0, message: "use the typed initializer.")
    public init(sequence: any AsyncSequence) {
        guard #unavailable(iOS 18.0)
        else {
            preconditionFailure("This should have triggered an error during build")
        }
        self.init(legacy: sequence)
    }
    
    // accessible for testing
    internal init(element: Element.Type = Element.self, failure: Failure.Type = Failure.self, legacy: any AsyncSequence) {
        self.makeAsyncIteratorFunc = {
            return AnyAsyncIterator(element: Element.self, failure: Failure.self, legacyIterator: legacy.makeAsyncIterator())
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
    
    @available(iOS 17.0, *)
    @available(iOS, obsoleted: 18.0, message: "use the typed initializer.")
    fileprivate init<I: AsyncIteratorProtocol>(element: Element.Type, failure: Failure.Type, legacyIterator: I) {
        if #available(iOS 18.0, *) {
#if DEBUG
            precondition(ProcessInfo.processInfo.isTesting, "This should have triggered an error during build")
#else
            precondition("This should have triggered an error during build")
#endif
        }
        self.iterator = legacyIterator
    }
    var iterator: any AsyncIteratorProtocol
    
    @available(iOS 18.0, macOS 18.0, tvOS 18.0, watchOS 18.0, *)
    var modern: ModernIterator<Element, Failure> {
        _read {
            yield (iterator as! ModernIterator<Element, Failure>)
        }
        _modify {
            var it = (iterator as! ModernIterator<Element, Failure>)
            yield &it
            iterator = it
        }
    }
    @available(iOS 18.0, *)
    public mutating func next(isolation isolatedToActor: isolated (any Actor)?) async throws(Failure) -> Element? {
        try await modern.next(isolation: isolatedToActor)
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
