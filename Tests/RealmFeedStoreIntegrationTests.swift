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

class RealmFeedStoreIntegrationTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        
        setupEmptyStoreState()
    }
    
    func test_retrieve_deliversEmptyOnEmptyCache() {
        let sut = makeSUT()
        
        expect(sut, toRetrieve: .empty)
    }
    
    func test_retrieve_deliversFoundValuesOnNonEmptyCache() {
        let sut = makeSUT()
        let feed = uniqueImageFeed()
        let timestamp = Date()
        
        sut.insert(feed, timestamp: timestamp) { _ in }

        expect(sut, toRetrieve: .found(feed: feed, timestamp: timestamp))
    }
    
    func test_insert_overridesPreviouslyInsertedCacheValues() {
        let sut = makeSUT()
        let firstFeed = uniqueImageFeed()
        let firstTimestamp = Date()
        let latestFeed = uniqueImageFeed()
        let latestTimestamp = Date()

        sut.insert(firstFeed, timestamp: firstTimestamp) { _ in }
        sut.insert(latestFeed, timestamp: latestTimestamp) { _ in }

        expect(sut, toRetrieve: .found(feed: latestFeed, timestamp: latestTimestamp))
    }
    
    func test_delete_deliversNoErrorOnEmptyCache() {
        let sut = makeSUT()
        
        let deletionError = deleteCache(sut)
        
        XCTAssertNil(deletionError)
    }
    
    func test_delete_deliversNoErrorOnNonEmptyCache() {
        let sut = makeSUT()
        let feed = uniqueImageFeed()
        let timestamp = Date()
        
        sut.insert(feed, timestamp: timestamp) { _ in }

        let deletionError = deleteCache(sut)
        
        XCTAssertNil(deletionError)
    }
    
    func test_delete_emptiesPreviouslyInsertedCache() {
        let sut = makeSUT()
        let feed = uniqueImageFeed()
        let timestamp = Date()
        
        sut.insert(feed, timestamp: timestamp) { _ in }
        deleteCache(sut)
        
        expect(sut, toRetrieve: .empty)
    }
    
    // MARK: - Helpers
    private func makeSUT(file: StaticString = #file, line: UInt = #line) -> FeedStore {
        let realmConfiguration = testSpecificPersistentStoreRealmConfiguration()
        let sut = RealmFeedStore { try Realm(configuration: realmConfiguration) }
        
        trackForMemoryLeaks(sut, file: file, line: line)
        
        return sut
    }
    
    private func expect(_ sut: FeedStore, toRetrieve expectedResult: RetrieveCachedFeedResult, file: StaticString = #file, line: UInt = #line) {
        let exp = expectation(description: "Wait to retrieve from realm db")
        
        sut.retrieve { retrievedResult in
            switch (expectedResult, retrievedResult) {
                case (.empty, .empty),
                     (.failure, .failure):
                    break
                    
                case let (.found(expectedFeed, expectedTimestamp), .found(retrievedFeed, retrievedTimestamp)):
                    XCTAssertEqual(retrievedFeed, expectedFeed, file: file, line: line)
                    XCTAssertEqual(retrievedTimestamp, expectedTimestamp, file: file, line: line)
                    
                default:
                    XCTFail("Expected to retrieve \(expectedResult), got \(retrievedResult) instead", file: file, line: line)
            }
            
            exp.fulfill()
        }
        
        wait(for: [exp], timeout: 1.0)
    }
    
    @discardableResult
    private func deleteCache(_ sut: FeedStore) -> Error? {
        let exp = expectation(description: "Waiting to delete cache from realm db")
        var receivedError: Error?
        sut.deleteCachedFeed { deletionError in
            receivedError = deletionError
            exp.fulfill()
        }
        
        wait(for: [exp], timeout: 1.0)
        return receivedError
    }
    
    private func uniqueImageFeed() -> [LocalFeedImage] {
        return [uniqueImage(), uniqueImage()]
    }
    
    private func uniqueImage() -> LocalFeedImage {
        return LocalFeedImage(id: UUID(), description: "any", location: "any", url: anyURL())
    }
    
    private func anyURL() -> URL {
        return URL(string: "http://any-url.com")!
    }

    private func cachesDirectory() -> URL {
        return FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
    }
    
    private func testSpecificPersistentStoreURL() -> URL {
        return cachesDirectory().appendingPathComponent("\(type(of: self))")
    }
    
    private func testSpecificPersistentStoreRealmConfiguration() -> Realm.Configuration {
        return Realm.Configuration(fileURL: testSpecificPersistentStoreURL(), objectTypes: RealmFeedStore.getRequiredModelsType())
    }
    
    private func setupEmptyStoreState() {
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
