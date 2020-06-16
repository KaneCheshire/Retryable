//
//  RetryTestSuite.swift
//  Retryable
//

import XCTest

/// A test suite designed specifically for re-running failed test cases.
final class RetryTestSuite: XCTestSuite {
	
	/// Creates a new instance configured with failed tests.
	///
	/// - Parameter failures: The failures to configure the test suite with.
	init(_ failures: Set<RetryableTestCase>) {
		super.init(name: .retryableTestSuiteName(from: failures))
		failures.sorted(by: { $0.name < $1.name }).forEach { failure in
			guard let selector = failure.invocation?.selector else { fatalError("Tests for \(failure.name) should have a selector") }
			let test = type(of: failure).init(selector) // Creates a new instance of the test case for the selector that failed
			test.retryCount = failure.retryCount + 1 // Bumps the retry count of the new instance using the previously failed instance's count
			addTest(test)
		}
	}
	
}

private extension String {
    
    static func retryableTestSuiteName(from failures: Set<RetryableTestCase>) -> String {
        let types = failures.reduce(into: "", { result, failure in
            guard !result.contains("\(type(of: failure))") else { return }
            if !result.isEmpty {
                result += ", "
            }
            result += "\(type(of: failure))"
        })
        return "Retrying \(types)"
    }
    
}
