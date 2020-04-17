//
//  Copyright © 2019 Essential Developer. All rights reserved.
//

import XCTest
import FeedStoreChallenge
import RealmSwift


class RealmFeedStoreTests: XCTestCase, FeedStoreSpecs {
  
    override func setUp() {
        super.setUp()
        
        setupRealmStrongReference()
    }
    
    override func tearDown() {
        super.tearDown()
        
        undoRealmSideEffects()
    }
    
	func test_retrieve_deliversEmptyOnEmptyCache() {
		let sut = makeSUT()

		assertThatRetrieveDeliversEmptyOnEmptyCache(on: sut)
	}

	func test_retrieve_hasNoSideEffectsOnEmptyCache() {
		let sut = makeSUT()

		assertThatRetrieveHasNoSideEffectsOnEmptyCache(on: sut)
	}

	func test_retrieve_deliversFoundValuesOnNonEmptyCache() {
		let sut = makeSUT()

		assertThatRetrieveDeliversFoundValuesOnNonEmptyCache(on: sut)
	}

	func test_retrieve_hasNoSideEffectsOnNonEmptyCache() {
		let sut = makeSUT()

		assertThatRetrieveHasNoSideEffectsOnNonEmptyCache(on: sut)
	}

	func test_insert_deliversNoErrorOnEmptyCache() {
		let sut = makeSUT()

		assertThatInsertDeliversNoErrorOnEmptyCache(on: sut)
	}

	func test_insert_deliversNoErrorOnNonEmptyCache() {
		let sut = makeSUT()

		assertThatInsertDeliversNoErrorOnNonEmptyCache(on: sut)
	}

	func test_insert_overridesPreviouslyInsertedCacheValues() {
		let sut = makeSUT()

		assertThatInsertOverridesPreviouslyInsertedCacheValues(on: sut)
	}

	func test_delete_deliversNoErrorOnEmptyCache() {
		let sut = makeSUT()

		assertThatDeleteDeliversNoErrorOnEmptyCache(on: sut)
	}

	func test_delete_hasNoSideEffectsOnEmptyCache() {
		let sut = makeSUT()

		assertThatDeleteHasNoSideEffectsOnEmptyCache(on: sut)
	}

	func test_delete_deliversNoErrorOnNonEmptyCache() {
		let sut = makeSUT()

		assertThatDeleteDeliversNoErrorOnNonEmptyCache(on: sut)
	}

	func test_delete_emptiesPreviouslyInsertedCache() {
		let sut = makeSUT()

		assertThatDeleteEmptiesPreviouslyInsertedCache(on: sut)
	}

	func test_storeSideEffects_runSerially() {
		let sut = makeSUT()

		assertThatSideEffectsRunSerially(on: sut)
	}
	
	// - MARK: Helpers
    private var strongRealmReference: Realm?
	
    private func makeSUT(_ configuration: Realm.Configuration? = nil, setWriteError: Bool = false, file: StaticString = #file, line: UInt = #line) -> FeedStore {
        let configuration = configuration ?? testSpecificConfiguration()
        let sut = RealmFeedStore {
            let realm = try Realm(configuration: configuration)
            return RealmStub(realm: realm, throwWriteError: setWriteError)
        }
        
        trackForMemoryLeaks(sut, file: file, line: line)
        
        return sut
	}
    
    private func testSpecificConfiguration() -> Realm.Configuration {
        return Realm.Configuration(inMemoryIdentifier: self.name, objectTypes: RealmFeedStore.getRequiredModelsType())
    }
    
    private func testSpecificInvalidConfiguration() -> Realm.Configuration {
        let invalidStoreURL = URL(string: "invalid://store-url")!
        return Realm.Configuration(fileURL: invalidStoreURL, objectTypes: RealmFeedStore.getRequiredModelsType())
    }
    
    private func setupRealmStrongReference() {
        strongRealmReference = try! Realm(configuration: testSpecificConfiguration())
    }
    
    private func undoRealmSideEffects() {
        strongRealmReference = nil
    }
    
    private class RealmStub: RealmAdapter {
        
        private let realm: Realm
        private let throwWriteError: Bool
        
        init(realm: Realm, throwWriteError: Bool) {
            self.realm = realm
            self.throwWriteError = throwWriteError
        }
        
        func objects<Element>(_ type: Element.Type) -> Results<Element> where Element : Object {
            return realm.objects(type)
        }
        
        func write<Result>(withoutNotifying tokens: [NotificationToken], _ block: (() throws -> Result)) throws -> Result {
            if throwWriteError {
                throw anyError()
            }
            return try realm.write(withoutNotifying: tokens, block)
        }
        
        func add(_ object: Object, update: Realm.UpdatePolicy) {
            realm.add(object, update: update)
        }
        
        private func anyError() -> NSError {
            return NSError(domain: "anyDomain", code: 0, userInfo: nil)
        }
        
        func delete<Element>(_ objects: Results<Element>) where Element : Object {
            realm.delete(objects)
        }
        
        func refresh() -> Bool {
            return realm.refresh()
        }
    }
}


extension RealmFeedStoreTests: FailableRetrieveFeedStoreSpecs {

    func test_retrieve_deliversFailureOnRetrievalError() {
        let sut = makeSUT(testSpecificInvalidConfiguration())

        assertThatRetrieveDeliversFailureOnRetrievalError(on: sut)
    }

    func test_retrieve_hasNoSideEffectsOnFailure() {
        let sut = makeSUT(testSpecificInvalidConfiguration())

        assertThatRetrieveHasNoSideEffectsOnFailure(on: sut)
    }

}

extension RealmFeedStoreTests: FailableInsertFeedStoreSpecs {

	func test_insert_deliversErrorOnInsertionError() {
		let sut = makeSUT(setWriteError: true)

		assertThatInsertDeliversErrorOnInsertionError(on: sut)
	}

	func test_insert_hasNoSideEffectsOnInsertionError() {
        let sut = makeSUT(setWriteError: true)

		assertThatInsertHasNoSideEffectsOnInsertionError(on: sut)
	}
}

extension RealmFeedStoreTests: FailableDeleteFeedStoreSpecs {

	func test_delete_deliversErrorOnDeletionError() {
		let sut = makeSUT(setWriteError: true)

		assertThatDeleteDeliversErrorOnDeletionError(on: sut)
	}

	func test_delete_hasNoSideEffectsOnDeletionError() {
        let sut = makeSUT(setWriteError: true)

		assertThatDeleteHasNoSideEffectsOnDeletionError(on: sut)
	}
}
