//
//  SomeMoreUITests.swift
//  Retryable_ExampleUITests
//
//  Created by Kane Cheshire on 16/06/2019.
//  Copyright © 2019 CocoaPods. All rights reserved.
//

import XCTest
import Retryable

private var shouldPass = false // Allows us to simulate an initial failure

class SomeMoreUITests: RetryableTestCase {
    
    override func setUp() {
        continueAfterFailure = false
        XCUIApplication().launch()
    }
    
    override func tearDown() {
        XCUIApplication().terminate()
    }
    
    func test_anotherAwesomeFeature() {
        // ... Your automation code you're always expecting to work ...

        flaky(.fixable(reason: "We've got a race condition here")) {
            // ... Your automation code that sometimes fails because there's a race condition with the server
            let old = shouldPass
            shouldPass = true
            XCTAssert(old)
        }
        
        // ... Some more of your automation code you're always expecting to work ...
    }
    
}

