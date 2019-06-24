//
//  RetryableTestCase.swift
//  Retryable
//

import XCTest

/// A XCTestCase subclass that your test cases can subclass, to opt into
/// retryable behaviour by marking functions or _portions_ of functions as flaky.
open class RetryableTestCase: XCTestCase {
	
	// MARK: - Custom types -
	// MARK: Public
	
	/// Represents the reliability of a test or portion of a test.
	///
	/// - reliable: The test is reliable, this is the default reliability for tests.
	/// - flaky: The test is flaky. When using this case you're also required to provide the type of flakiness.
	public enum Reliability {
		
		case reliable
		
		/// Represents a type of flakiness that a flaky test can be.
		///
		/// - fixable: The flakiness is fixable. When using this case you're also required to provide a reason for using it. Fixable flakes are hard coded to retry a maximum of 1 times.
		/// - notFixable: The flakiness is not fixable (e.g. something the simulator does like not properly saving UserDefaults). When using this case you're also required to provide a reason for using it. Non-fixable flakes also request a max retry count, depending on how severe your flake is you might want to set this to more than 1.
		public enum Flakiness {
            
            case fixable(reason: String)
            case notFixable(reason: String, maxRetryCount: Int)
            
		}
		
		case flaky(Flakiness)
		
	}
	
	// MARK: - Properties -
	// MARK: Overrides
	
    override open class var defaultTestSuite: XCTestSuite {
        _ = RetryCoordinator.shared
        return super.defaultTestSuite
    }
    
	override open var testRunClass: AnyClass? {
		return RetryableTestCaseRun.self
	}
    
    // MARK: Open
    
    /// The reliability of the test case. `.reliable` by default.
    /// If a test fails while it is marked as flaky, so long as the max retry count has not been hit then the test function will automatically retry.
    /// It's very important to understand that each test function in your test case class creates a new instance of your test case class, which is
    /// how only specific failing test functions are re-run, rather than every test function.
    var reliability: Reliability = .reliable
	
	// MARK: Internal
	
	/// The current retry count of the test case. This will start at 0 for every test function in your test case due to the fact that
	/// a new instance is created by XCUI for each test function when running your tests.
	var retryCount: Int = 0
	
	// MARK: - Init -
	// MARK: Internal
	
    required convenience public init(_ selector: Selector) { // Required to get around some weird Swift compiler errors. It doesn't look like it should be needed but trust me it is :)
		self.init(selector: selector)
	}
	
	// MARK: - Functions -
	// MARK: Overrides
	
    override open func recordFailure(withDescription description: String, inFile filePath: String, atLine lineNumber: Int, expected: Bool) {
		switch reliability {
		case .flaky(let flakiness) where retryCount < flakiness.maxRetryCount:
            handleFlakyTestFailed(with: flakiness, description: description, filePath: filePath, lineNumber: lineNumber, expected: expected)
		default:
            super.recordFailure(withDescription: description, inFile: filePath, atLine: lineNumber, expected: expected)
		}
	}
	
	// MARK: Open
	
	/// Use this function to "section off" parts of your test function with different types of flakiness.
	/// This test function is far preferred than setting the `reliability` property yourself during a test run, since
	/// this function automatically manages the reliability during the specific tests you run as part of this block.
	///
	/// - Parameters:
	///   - flakiness: The type of flakiness. I.e. fixable or not fixable.
	///   - tests: The tests to run which are flaky.
	open func flaky(_ flakiness: Reliability.Flakiness, _ tests: () -> Void) {
		reliability = .flaky(flakiness)
		tests()
		reliability = .reliable
	}
    
    /// Use this function to "section off" parts of your test function with different types of flakiness.
    /// This test function is far preferred than setting the `reliability` property yourself during a test run, since
    /// this function automatically manages the reliability during the specific tests you run as part of this block.
    ///
    /// - Parameters:
    ///   - flakiness: The type of flakiness. I.e. fixable or not fixable.
    ///   - tests: The tests to run which are flaky.
    open func flaky(_ flakiness: Reliability.Flakiness, _ tests: @autoclosure () -> Void) {
        reliability = .flaky(flakiness)
        tests()
        reliability = .reliable
    }
	
	// MARK: Private
	
	private func handleFlakyTestFailed(with flakiness: Reliability.Flakiness, description: String, filePath: String, lineNumber: Int, expected: Bool) {
		guard let testRun = testRun as? RetryableTestCaseRun else {
			return super.recordFailure(withDescription: description, inFile: filePath, atLine: lineNumber, expected: expected)
		}
		XCTContext.runActivity(named: "Flaky test failed, queuing to re-run.") { _ in
			let attachment = XCTAttachment(string: """
				Flaky test failed.
				
				Flakiness: \(flakiness)
				
				Retry count: \(retryCount)
				
				Description: \(description)
				
				File: \(filePath)
				
				Line: \(lineNumber)
				
				Expected: \(expected)
				""")
			attachment.lifetime = .keepAlways
			add(attachment)
			RetryCoordinator.shared.addFailedTest(self)
			testRun.temporarilyIgnoreFailuresDuringBlock {
				super.recordFailure(withDescription: description, inFile: filePath, atLine: lineNumber, expected: expected)
			}
		}
	}
	
}

extension RetryableTestCase.Reliability.Flakiness {
    
    var maxRetryCount: Int {
        switch self {
        case .fixable: return 1 // U no get to choose for fixable flakes. If they're annoying you, fix them!
        case .notFixable(_, let maxRetryCount): return maxRetryCount
        }
    }
    
}
