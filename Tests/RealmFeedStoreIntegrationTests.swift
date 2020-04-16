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
        let realmConfiguration = testSpecificPersistentStoreRealmConfiguration()
        let sut = RealmFeedStore { try Realm(configuration: realmConfiguration) }
        
        let exp = expectation(description: "Wait to retrieve from realm db")
        sut.retrieve { result in
            switch result {
                
            case .failure(_), .found(_, _):
                XCTFail("Empty cache expected, got \(result) instead.")
            default:
                break
            }
            
            exp.fulfill()
        }
        
        wait(for: [exp], timeout: 1.0)
    }
    
    func test_retrieve_deliversFoundValuesOnNonEmptyCache() {
        let realmConfiguration = testSpecificPersistentStoreRealmConfiguration()
        let sut = RealmFeedStore { try Realm(configuration: realmConfiguration) }
        let feed = uniqueImageFeed()
        let timestamp = Date()
        
        sut.insert(feed, timestamp: timestamp) { _ in }
        
        let exp = expectation(description: "Wait to retrieve from realm db")
        sut.retrieve { result in
            switch result {

            case let .found(retrievedFeed, retrievedTimestamp):
                XCTAssertEqual(feed, retrievedFeed)
                XCTAssertEqual(timestamp, retrievedTimestamp)

            case .failure(_), .empty:
                XCTFail("Non empty cache expected, got \(result) instead.")
            }
            
            exp.fulfill()
        }
        
        wait(for: [exp], timeout: 1.0)
    }
    
    // MARK: - Helpers
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
