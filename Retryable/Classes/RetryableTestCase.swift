//
//  RetryableTestCase.swift
//  RestartableUITests
//
//  Created by Kane Cheshire on 14/06/2019.
//  Copyright © 2019 kane.codes. All rights reserved.
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
		/// - fixable: The flakiness is fixable. When using this case you're also required to provide a reason for using it.
		/// - notFixable: The flakiness is not fixable (e.g. something the simulator does like not properly saving UserDefaults). When using this case you're also required to provide a reason for using it.
		public enum Flakiness {
            
			case fixable(reason: String)
			case notFixable(reason: String)
            
		}
		
		case flaky(Flakiness)
		
	}
	
	// MARK: - Properties -
	// MARK: Overrides
	
	override open var testRunClass: AnyClass? {
		return RetryableTestCaseRun.self
	}
    
    // MARK: Open
    
    /// The reliability of the test case. `.reliable` by default.
    /// Do not change this in `setUp` this should be set in individual test functions.
    /// Although you can change this setting manually in a test function, instead it's recommended to use the `flaky()` function which
    /// allows you to define a specific portion of your test as flaky but let the rest run as normal.
    /// If a test fails while it is marked as flaky, so long as the max retry count has not been hit then the test function will automatically retry.
    /// It's very important to understand that each test function in your test case class creates a new instance of your test case class, which is
    /// how only specific failing test functions are re-run, rather than every test function.
    open var reliability: Reliability = .reliable
    
    /// The maximum number of times a test can be retried. Default is 1.
    open var maxRetryCount: Int = 1
	
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
		case .flaky(let flakiness) where retryCount < maxRetryCount:
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
