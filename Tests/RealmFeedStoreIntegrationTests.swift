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
        let cacheDirectory = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
        let realmURL = cacheDirectory.appendingPathComponent("\(type(of: self))")
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
    
    func test_retrieve_deliversEmptyOnEmptyCache() {
        let cacheDirectory = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
        let realmDBURL = cacheDirectory.appendingPathComponent("\(type(of: self))")
        let realmConfiguration = Realm.Configuration(fileURL: realmDBURL, objectTypes: RealmFeedStore.getRequiredModelsType())
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
}
