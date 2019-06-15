# Retryable

[![CI Status](https://img.shields.io/travis/kanecheshire/Retryable.svg?style=flat)](https://travis-ci.org/kanecheshire/Retryable)
[![Version](https://img.shields.io/cocoapods/v/Retryable.svg?style=flat)](https://cocoapods.org/pods/Retryable)
[![License](https://img.shields.io/cocoapods/l/Retryable.svg?style=flat)](https://cocoapods.org/pods/Retryable)
[![Platform](https://img.shields.io/cocoapods/p/Retryable.svg?style=flat)](https://cocoapods.org/pods/Retryable)

Retryable is a small library for being able to make your iOS UI/automation tests retry when a flaky test fails.

Unlike other options for making your automation tests re-run when a failure occurs, Retryable will only re-run the individual test functions that have failed, rather than running the entire suite again which can be incredibly time consuming.

Even better, Retryable lets you mark specific portions of a test as flaky, so that any other failure during the test function is not automatically retried and will fail normally.

Retryable also works great with parallel automation tests.

### Opting into retries

To opt into retries you only need to do two things:

1: Make your test cases subclass the `RetryableTestCase` instead of `XCTestCase`:

```swift
class MyUITests: RetryableTestCase {

}
```

- Mark the portion of your test case that sometimes fails as flaky:

```swift
class MyUITests: RetryableTestCase {

    func test_awesomeFeature() {
        // ... Your automation code you're always expecting to work ...
        
        flaky(.notFixable(reason: "UserDefaults doesn't always save properly on the iOS 11 simulator")) {
            // ... Your automation code that sometimes fails because UserDefaults is unreliable
        }
        
        // ... Some more of your automation code you're always expecting to work ...
    }

}
```

Note how part of the function is marked as flaky, and when marking as flaky you are required to determine whether it's a fixable flake or not. 

Regardless of whether you think it's fixable, you're also required to provide a reason. 

These two requirements help prevent bad habits of marking everything as flaky without properly investigating it, and helps document what's wrong for future developers on your codebase.

## Installation

Retryable is currently available through Cocoapods. When Xcode 11 is released Retryable will only be available through Swift Package Manager.

## Author

kanecheshire, @kanecheshrie

## License

Retryable is available under the MIT license. See the LICENSE file for more info.
