//
//  XCTestCase+MemoryLeakTracking.swift
//  Tests
//
//  Created by Fabio Vendramin on 14/04/2020.
//  Copyright © 2020 Essential Developer. All rights reserved.
//

import XCTest


extension XCTestCase {
    func trackForMemoryLeaks(_ instance: AnyObject, file: StaticString = #file, line: UInt = #line) {
        addTeardownBlock { [weak instance] in
            XCTAssertNil(instance, "Instance should have been deallocated. Potential memory leak.", file: file, line: line)
        }
    }
}
