//
//  RetryCoordinator.swift
//  Retryable
//

import XCTest

/// Coordidates retrying failing test cases.
final class RetryCoordinator: NSObject {
	
    // MARK: - Custom types -
    // MARK: Private
    
    fileprivate struct Retries: Codable {
        
        struct Test: Codable {
            
            let name: String
            let fixable: Bool
            let reason: String
            let attemptedRetries: Int
            let maxRetriesAllowed: Int
            
        }
        
        let retries: [Test]
        
    }
    
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
    
    // MARK: Private
    
    private func addRetriedTestsToXCResultBundle() {
        guard let url = URL.xcresultBundle?.appendingPathComponent("retryable-retries.json") else { return }
        let data = (try? Data(contentsOf: url)) ?? Data()
        let existingRetries = (try? JSONDecoder().decode(Retries.self, from: data)) ?? Retries(retries: [])
        let newRetriedTests: [Retries.Test] = failures.compactMap { .init(testCase: $0) }
        let filteredExisting = existingRetries.retries.filter { retry in !newRetriedTests.contains { $0.name == retry.name } }
        let sortedTests = (filteredExisting + newRetriedTests).sorted(by: { $0.name < $1.name })
        let newRetries = Retries(retries: sortedTests)
        let newData = try? JSONEncoder().encode(newRetries)
        try? newData?.write(to: url)
    }
	
}

extension RetryCoordinator: XCTestObservation {
    
	func testSuiteDidFinish(_ testSuite: XCTestSuite) {
        guard !failures.isEmpty else { return }
        let suite = RetryTestSuite(failures)
        addRetriedTestsToXCResultBundle()
        failures = []
        suite.run()
	}
	
}

private extension URL {
    
    /// Attempts to find the URL to the xcresult bundle for this test run.
    static var xcresultBundle: URL? {
        guard let pathToConfig = ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] else { return nil }
        var url = URL(fileURLWithPath: pathToConfig)
        guard url.pathComponents.contains(where: { $0.contains(".xcresult") }) else { return nil }
        while !url.lastPathComponent.contains(".xcresult") { url.deleteLastPathComponent() }
        return url
    }
    
}

private extension RetryCoordinator.Retries.Test {
    
    init(testCase: RetryableTestCase) {
        switch testCase.reliability {
        case .flaky(let flakiness):
            self.init(name: testCase.name, fixable: flakiness.isFixable, reason: flakiness.reason, attemptedRetries: testCase.retryCount + 1, maxRetriesAllowed: flakiness.maxRetryCount)
        case .reliable: fatalError()
        }
    }
    
}

private extension RetryableTestCase.Reliability.Flakiness {
    
    var isFixable: Bool {
        switch self {
        case .fixable: return true
        case .notFixable: return false
        }
    }
    
    var reason: String {
        switch self {
        case .fixable(let reason), .notFixable(let reason, _): return reason
        }
    }
    
}
