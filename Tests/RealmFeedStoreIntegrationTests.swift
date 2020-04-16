//
//  RealmFeedStoreIntegrationTests.swift
//  Tests
//
//  Created by Fabio Vendramin on 16/04/2020.
//

import XCTest
import FeedStoreChallenge
import RealmSwift

extension Realm: RealmAdapter {}

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
        let feed = self.uniqueImageFeed()
        let timestamp = Date()
        
        var insertionSUT: FeedStore?
        let insertionQueue = DispatchQueue(label: "Insertion \(self.name)", qos: .background, attributes: .concurrent)
        let exp = expectation(description: "Wait insertion to realm db")
        insertionQueue.async { [weak self] in
            guard let self = self else { return }
            
            let realmConfiguration = self.testSpecificPersistentStoreRealmConfiguration()
            insertionSUT = RealmFeedStore { try Realm(configuration: realmConfiguration) }
            insertionSUT?.insert(feed, timestamp: timestamp) { _ in
                exp.fulfill()
            }
        }
        
        wait(for: [exp], timeout: 2.0)
        insertionSUT = nil
        
        let retrieveSUT = makeSUT()
        expect(retrieveSUT, toRetrieve: .found(feed: feed, timestamp: timestamp))
    }
    
    func test_deleteWithSUTInstancesInDifferentQueues_emptiesPreviouslyInsertedCache() {
        let retrieveSUT = makeSUT()
        var sut: FeedStore?
        
        let feed = self.uniqueImageFeed()
        let timestamp = Date()
        let opQueue = DispatchQueue(label: "Operations \(self.name)", qos: .userInitiated, attributes: .concurrent)
                
        let exp1 = expectation(description: "Wait operations to realm db")
        opQueue.async { [weak self] in
            guard let self = self else { return }
            
            let realmConfiguration = self.testSpecificPersistentStoreRealmConfiguration()
            sut = RealmFeedStore { try Realm(configuration: realmConfiguration) }
            
            sut?.insert(feed, timestamp: timestamp) { _ in }
            sut?.deleteCachedFeed { _ in }
            
            exp1.fulfill()
        }
        
        wait(for: [exp1], timeout: 2.0)
        sut = nil

        expect(retrieveSUT, toRetrieve: .empty)
    }
}
