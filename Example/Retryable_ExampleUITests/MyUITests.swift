//
//  MyUITests.swift
//  Retryable_ExampleUITests
//
//  Created by Kane Cheshire on 15/06/2019.
//  Copyright © 2019 CocoaPods. All rights reserved.
//

import XCTest
import Retryable

var shouldPass = false

class MyUITests: RetryableTestCase {

    override func setUp() {
        continueAfterFailure = false
        XCUIApplication().launch()
    }

    override func tearDown() {
        XCUIApplication().terminate()
    }

    func test_awesomeFeature() {
        // ... Your automation code you're always expecting to work ...
        
        flaky(.notFixable(reason: "UserDefaults doesn't always save properly on the iOS 11 simulator")) {
            // ... Your automation code that sometimes fails because UserDefaults is unreliable
            let old = shouldPass
            shouldPass = true
            XCTAssert(old)
        }
        
        // ... Some more of your automation code you're always expecting to work ...
    }

}
