# The `FeedStore` challenge - iOSLeadEssentials.com

[![Build Status](https://travis-ci.com/essentialdevelopercom/ios-lead-essentials-feed-store-challenge.svg?branch=master)](https://travis-ci.com/essentialdevelopercom/ios-lead-essentials-feed-store-challenge)

You are called to build your own persistence infrastructure implementation by creating a new component that conforms to the `<FeedStore>` protocol.

Your custom persistence infrastructure implementation can be backed by any persistence stack you wish, i.e. CoreData, Realm, in memory, etc, as shown in the diagram below.

![Infrastructure Dependency Diagram](infrastructure_dependency_diagram.png)

We advise you to invest some time and effort to produce a clean and well-presented solution to demonstrate your knowledge as it can be **an ideal addition to your project portfolio**!

## Instructions

1. Fork the latest version of [the challenge repo](https://github.com/essentialdevelopercom/ios-lead-essentials-feed-store-challenge).
2. Implement **at least one** `<FeedStore>` implementation of your choice.
3. Use the `Tests/FeedStoreChallengeTests.swift` to validate your implementation. We recommend you to implement one test at a time. Follow the process: Make the test pass, commit, and move to the next one. In the end, all tests **must pass**. 
4. If your implementation has failable operations (e.g., it might fail to load data from disk), uncomment and implement the failable test extensions at the bottom of the `Tests/FeedStoreChallengeTests.swift` test file. 
5. When you’re done implementing your `<FeedStore>` solution, create a Pull Request from your branch to the [main challenge repo](https://github.com/essentialdevelopercom/ios-lead-essentials-feed-store-challenge). Use the name of your implementation as the title for the Pull Request, for example, *“CoreData implementation”*.
6. Extra (optional): If your implementation persists the data across app launches (e.g., CoreData/Realm), you should add Integration Tests to check this behavior. In the lectures, we tested this behavior with Integration Tests in another target, but for this challenge, you can do it in the same test target.

## Guidelines

1. Aim to commit your changes every time you add/alter the behavior of your system or refactor your code.
2. The system should always be in a green state, meaning that in each commit all tests should be passing.
3. The project should build without warnings.
4. The code should be carefully organized and easy to read (e.g. indentation must be consistent, etc.).
5. Aim to create short methods respecting the Single Responsibility Principle.
6. Aim to declare dependencies explicitly, instead of implicitly, leveraging dependency injection wherever necessary.
7. Aim **not** to block the main thread. Strive to run operations in a background queue.
8. Aim for descriptive commit messages that clarify the intent of your contribution which will help other developers understand your train of thought and purpose of changes.
9. Make careful and proper use of access control, marking as `private` any implementation details that aren’t referenced from other external components.
10. Aim to write self-documenting code by providing context and detail when naming your components, avoiding explanations in comments.

Finally, add to this README file:

### Comments and remarks you think other developers will find useful.

#### `setUp()` & `tearDown()` methods

In the `RealmFeedStoreTests` class, a _"InMemory"_ realm implementation is used.
When async queue management for the FeedStore operations was introduced, ARC has started to release the DB between the call of write and read cache operations destroying all the content of the cache 
(this behaviour happen because the realm object must be instantiated in every thread to avoid race conditions and Realm Exceptions).
This does not happen if we use persistent storage, but for the test, I have decided to set up a strong reference to the realm _"In Memory"_ object.

The `setUp()` and `tearDown()` methods are used to **set** and **release** this realm reference avoiding the release of the DB.


#### `RealmAdapter` protocol, why I'm not convinced...🤔

When I was searching for a method to simulate writing errors to realm (I'm new to TDD), I found the nice solution of [danillahtin](https://github.com/danillahtin) in this course challenge, and I have decided to follow his methodology to stub the realm component.

Practically, the `RealmAdapter` protocol exposes the `Realm` methods needed for the `(Realm)FeedStore` implementation 
(`Realm` component is a `struct`, the protocol is the best way to achieve this functionality); so in the tests, it is possible to use a Stub (`RealmStub`)
to inject the behaviour we want to test (generate a write error in my case).

> Notice that I have modified the parameter of the constructor passing the closure that returns the `Realm` instance (instead of a `Realm.Configuration` as previously): this because the Realm instances are **thread-confined** 
so calling the closure into the async code block make the instance to respect the [Realm requisites](https://realm.io/docs/swift/latest/#threading).

##### Ok, why I'm not convinced?

This solution breaks some rules like:
- Don’t Mock Types You Don’t Own: the realm library could change breaking the protocol and the tests
- I have to _rewrite_ all the `Realm` methods used by the `RealmFeedStore` though I have to modify only the `write` method to simulate the error
- The protocol was introduced only to test a specific behaviour (inject write error)
- I have to make the original `Realm` struct to conforms to the `RealmAdapter` protocol


### The Dependency Diagram demonstrating the architecture of your solution. 

...
