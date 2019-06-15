//
//  RetryCoordinator.swift
//  Retryable
//

import XCTest

/// Coordidates retrying failing test cases.
final class RetryCoordinator: NSObject {
	
	// MARK: - Properties -
	// MARK: Internal
	
	static let shared = RetryCoordinator()
	
	// MARK: Private
	
	private var failures: Set<RetryableTestCase> = []
	
	// MARK: - Init -
	// MARK: Private
	
	private override init() {
		super.init()
		XCTestObservationCenter.shared.addTestObserver(self)
	}
	
	// MARK: - Functions -
	// MARK: Internal
	
	/// Adds a failed test to retry.
	/// Note that although you're passing in an instance of a test case, although it may seem like it it's not the entire test case that re-runs.
	/// The test case is initialised with a specific `Selector`, so you actually get multiple instances of your test cases created by XCTest, each with a different
	/// Selector from the list of test functions defined in the test case.
	///
	/// It's a bit of a head scratcher at first, but once you get your head around it it makes sense,
	/// and it's how we can create a test suite to retry only the test functions that failed without re-running the entire suite.
	///
	/// - Parameter failedTest: The failed test to retry.
	func addFailedTest(_ failedTest: RetryableTestCase) {
		failures.insert(failedTest)
	}
	
}

extension RetryCoordinator: XCTestObservation {
	
	func testSuiteDidFinish(_ testSuite: XCTestSuite) {
		guard !failures.isEmpty else { return }
		let suite = RetryTestSuite(failures)
		failures = []
		suite.run()
	}
	
}
