//
//  RetryableTestCaseRun.swift
//  Retryable
//
//  Created by Kane Cheshire on 15/06/2019.
//  Copyright © 2019 The App Business. All rights reserved.
//

import XCTest

/// A custom subclass of `XCTestCaseRun` that allows us to control when
/// failures are recorded.
/// This is needed because we need to be able to stop an entire test run from
/// failing during a flaky test, but we need to still let the actual test case itself
/// record its failure so that the test will stop after a failure rather than continuing
/// the test, which will likely fail because the app isn't in the right state anymore.
final class RetryableTestCaseRun: XCTestCaseRun {
	
	// MARK: - Properties -
	// MARK: Private
	
	private var shouldRecordFailure: Bool = true
	
	// MARK: - Functions -
	// MARK: Overrides
	
	override func recordFailure(withDescription description: String, inFile filePath: String?, atLine lineNumber: Int, expected: Bool) {
		guard shouldRecordFailure else { return }
		super.recordFailure(withDescription: description, inFile: filePath, atLine: lineNumber, expected: expected)
	}
	
	// MARK: Internal
	
	/// Temporarily stops any failures being recorded during the block of code that is
	/// passed in.
	/// Once the block has finished failures will be recorded again.
	///  Ultimatley this is used when a flaky test fails and we want to mark the test case as a failure
	///  but not the entire test run.
	///
	/// - Parameter block: The block of code to run while ignoring failures.
	func temporarilyIgnoreFailuresDuringBlock(_ block: () -> Void) {
		shouldRecordFailure = false
		block()
		shouldRecordFailure = true
	}
	
}
