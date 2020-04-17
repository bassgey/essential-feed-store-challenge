//
//  RealmFeedStoreIntegrationTests.swift
//  Tests
//
//  Created by Fabio Vendramin on 16/04/2020.
//

import XCTest
import FeedStoreChallenge
import RealmSwift


class RealmFeedStoreIntegrationTests: XCTestCase, FeedStoreSpecs {
    
    override func setUp() {
        super.setUp()
        
        setupEmptyStoreState()
    }
    
    override func tearDown() {
        super.tearDown()
        
        undoStoreSideEffects()
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
    
    // MARK: - Helpers
    private func makeSUT(file: StaticString = #file, line: UInt = #line) -> FeedStore {
        let realmConfiguration = testSpecificPersistentStoreRealmConfiguration()
        let sut = RealmFeedStore { try Realm(configuration: realmConfiguration) }
        
        trackForMemoryLeaks(sut, file: file, line: line)
        
        return sut
    }
    
    private func cachesDirectory() -> URL {
        return FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
    }
    
    private func testSpecificPersistentStoreURL() -> URL {
        return cachesDirectory().appendingPathComponent("\(type(of: self)).realm")
    }
    
    private func testSpecificPersistentStoreRealmConfiguration() -> Realm.Configuration {
        return Realm.Configuration(fileURL: testSpecificPersistentStoreURL(), objectTypes: RealmFeedStore.getRequiredModelsType())
    }
    
    private func setupEmptyStoreState() {
        removeStoreDB()
    }
    
    private func undoStoreSideEffects() {
        removeStoreDB()
    }
    
    private func removeStoreDB() {
        let realmURL = testSpecificPersistentStoreURL()
        let realmURLs = [
            realmURL,
            realmURL.appendingPathExtension("lock"),
            realmURL.appendingPathExtension("note"),
            realmURL.appendingPathExtension("management")
        ]
        
        for URL in realmURLs {
            try? FileManager.default.removeItem(at: URL)
        }
    }
}

extension RealmFeedStoreIntegrationTests {
    
    func test_retrieveWithSUTInstancesInDifferentQueues_deliversFoundValuesOnNonEmptyCache() {
        let retrieveSUT = makeSUT()
        let queue = DispatchQueue(label: "Insertion \(self.name)", qos: .background, attributes: .concurrent)
        let feed = self.uniqueImageFeed()
        let timestamp = Date()

        insert(cache: (feed: feed, timestamp: timestamp), on: queue)
        
        expect(retrieveSUT, toRetrieve: .found(feed: feed, timestamp: timestamp))
    }
    
    func test_deleteWithSUTInstancesInDifferentQueues_emptiesPreviouslyInsertedCacheChekingAllSteps() {
        let retrieveSUT = makeSUT()
        
        let feed = self.uniqueImageFeed()
        let timestamp = Date()
        let queue = DispatchQueue(label: "Operations \(self.name)", qos: .userInitiated, attributes: .concurrent)
        
        insert(cache: (feed: feed, timestamp: timestamp), on: queue)
        
        expect(retrieveSUT, toRetrieve: .found(feed: feed, timestamp: timestamp))
        
        delete(on: queue)
        
        expect(retrieveSUT, toRetrieve: .empty)
    }

    // MARK: - Helpers
    private func insert(cache: (feed: [LocalFeedImage], timestamp: Date), on queue: DispatchQueue) {
        
        var sut: FeedStore?
        let exp = expectation(description: "Wait insertion to realm db")
        
        queue.async { [weak self] in
            guard let self = self else { return }
            
            let realmConfiguration = self.testSpecificPersistentStoreRealmConfiguration()
            sut = RealmFeedStore { try Realm(configuration: realmConfiguration) }
            
            sut?.insert(cache.feed, timestamp: cache.timestamp) { _ in
                exp.fulfill()
            }
        }
        
        wait(for: [exp], timeout: 2.0)
    }
    
    private func delete(on queue: DispatchQueue) {
        var sut: FeedStore?
        let exp = expectation(description: "Wait deletion to realm db")
        
        queue.async { [weak self] in
            guard let self = self else { return }
            
            let realmConfiguration = self.testSpecificPersistentStoreRealmConfiguration()
            sut = RealmFeedStore { try Realm(configuration: realmConfiguration) }
            
            sut?.deleteCachedFeed { _ in
                exp.fulfill()
            }
        }
        
        wait(for: [exp], timeout: 2.0)
    }
}
