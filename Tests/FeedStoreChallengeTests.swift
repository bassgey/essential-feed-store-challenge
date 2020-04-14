//
//  Copyright © 2019 Essential Developer. All rights reserved.
//

import XCTest
import FeedStoreChallenge
import RealmSwift

class RealmFeedImage: Object {
    @objc dynamic var id: String = UUID().uuidString
    @objc dynamic var feedDescription: String?
    @objc dynamic var location: String?
    @objc dynamic var url: String = ""
    
    override static func primaryKey() -> String? {
        return "id"
    }
}

class RealmFeedCache: Object {
    @objc dynamic var timestamp = Date()
    let feed = List<RealmFeedImage>()
}

class RealmFeedImageMapper {
    
    enum Convert: Error {
        case idmapping
        case urlmapping
    }
    
    static func toModels(_ realmFeedImages: List<RealmFeedImage>) throws -> [LocalFeedImage] {
        return try realmFeedImages.map { realmFeedImage in
            
            guard let idFeedImage = UUID(uuidString: realmFeedImage.id) else {
                throw Convert.idmapping
            }
            
            guard let urlFeedImage = URL(string: realmFeedImage.url) else {
                throw Convert.urlmapping
            }

            return LocalFeedImage(
                id: idFeedImage,
                description: realmFeedImage.feedDescription,
                location: realmFeedImage.location,
                url: urlFeedImage)
        }
    }
}

class RealmFeedStore: FeedStore {
    
    let config: Realm.Configuration
    
    public init(configuration: Realm.Configuration) {
        self.config = configuration
    }
    
    func deleteCachedFeed(completion: @escaping DeletionCompletion) {
        completion(nil)
    }
    
    func insert(_ feed: [LocalFeedImage], timestamp: Date, completion: @escaping InsertionCompletion) {
        do {
            let realm = try Realm(configuration: config)
            let realmCache = RealmFeedStore.mapRealm(feed, timestamp: timestamp)
            
            try realm.write {
                RealmFeedStore.emptyCache(realm)
                realm.add(realmCache)
            }
            
            completion(nil)
        } catch {
            completion(error)
        }
    }
    
    private static func mapRealm(_ feed: [LocalFeedImage], timestamp: Date) -> RealmFeedCache {
        return RealmFeedCache(value: ["timestamp": timestamp, "feed": feed.toRealmModel()])
    }
    
    private static func emptyCache(_ realm: Realm) {
        let cache = realm.objects(RealmFeedCache.self)
        realm.delete(cache)
    }
    
    func retrieve(completion: @escaping RetrievalCompletion) {
        do {
            let realm = try Realm(configuration: config)
            
            let realmCacheItems = realm.objects(RealmFeedCache.self)
            if let realmCache = realmCacheItems.first {
                completion(RealmFeedStore.mapModels(realmCache))
            } else {
                completion(.empty)
            }
            
        } catch {
            completion(.failure(error))
        }
    }
    
    private static func mapModels(_ realmCache: RealmFeedCache) -> RetrieveCachedFeedResult {
        do {
            let localFeed = try RealmFeedImageMapper.toModels(realmCache.feed)
            return .found(feed: localFeed, timestamp: realmCache.timestamp)
        } catch {
            return .failure(error)
        }
    }
}

extension Array where Element == LocalFeedImage {
    func toRealmModel() -> [RealmFeedImage] {
        self.map { RealmFeedImage(value: [$0.id.uuidString, $0.description, $0.location, $0.url.absoluteString]) }
    }
}

class FeedStoreChallengeTests: XCTestCase, FeedStoreSpecs {
	
//
//   We recommend you to implement one test at a time.
//   Uncomment the test implementations one by one.
// 	 Follow the process: Make the test pass, commit, and move to the next one.
//

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
//		let sut = makeSUT()
//
//		assertThatDeleteEmptiesPreviouslyInsertedCache(on: sut)
	}

	func test_storeSideEffects_runSerially() {
//		let sut = makeSUT()
//
//		assertThatSideEffectsRunSerially(on: sut)
	}
	
	// - MARK: Helpers
	
	private func makeSUT() -> FeedStore {
		return RealmFeedStore(configuration: testSpecificConfiguration())
	}
    
    private func testSpecificConfiguration() -> Realm.Configuration {
        return Realm.Configuration(inMemoryIdentifier: self.name, objectTypes: [RealmFeedImage.self, RealmFeedCache.self])
    }
	
}

//
// Uncomment the following tests if your implementation has failable operations.
// Otherwise, delete the commented out code!
//

//extension FeedStoreChallengeTests: FailableRetrieveFeedStoreSpecs {
//
//	func test_retrieve_deliversFailureOnRetrievalError() {
////		let sut = makeSUT()
////
////		assertThatRetrieveDeliversFailureOnRetrievalError(on: sut)
//	}
//
//	func test_retrieve_hasNoSideEffectsOnFailure() {
////		let sut = makeSUT()
////
////		assertThatRetrieveHasNoSideEffectsOnFailure(on: sut)
//	}
//
//}

//extension FeedStoreChallengeTests: FailableInsertFeedStoreSpecs {
//
//	func test_insert_deliversErrorOnInsertionError() {
////		let sut = makeSUT()
////
////		assertThatInsertDeliversErrorOnInsertionError(on: sut)
//	}
//
//	func test_insert_hasNoSideEffectsOnInsertionError() {
////		let sut = makeSUT()
////
////		assertThatInsertHasNoSideEffectsOnInsertionError(on: sut)
//	}
//
//}

//extension FeedStoreChallengeTests: FailableDeleteFeedStoreSpecs {
//
//	func test_delete_deliversErrorOnDeletionError() {
////		let sut = makeSUT()
////
////		assertThatDeleteDeliversErrorOnDeletionError(on: sut)
//	}
//
//	func test_delete_hasNoSideEffectsOnDeletionError() {
////		let sut = makeSUT()
////
////		assertThatDeleteHasNoSideEffectsOnDeletionError(on: sut)
//	}
//
//}
