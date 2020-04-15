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

public final class RealmFeedStore: FeedStore {
    
    private let config: Realm.Configuration
    private let queue = DispatchQueue(label: "\(RealmFeedStore.self)", qos: .userInitiated, attributes: .concurrent)
    
    public init(configuration: Realm.Configuration) {
        self.config = configuration
    }
    
    private static func emptyCache(_ realm: Realm) {
        let cache = realm.objects(RealmFeedCache.self)
        realm.delete(cache)
    }
}

extension RealmFeedStore {
    public func deleteCachedFeed(completion: @escaping DeletionCompletion) {
        let config = self.config
        queue.async(flags: .barrier) {
            autoreleasepool {
                do {
                    let realm = try Realm(configuration: config)
                    
                    try realm.write {
                        RealmFeedStore.emptyCache(realm)
                    }
                    
                    completion(nil)
                } catch {
                    completion(error)
                }
            }
        }
    }
}

extension RealmFeedStore {
    public func insert(_ feed: [LocalFeedImage], timestamp: Date, completion: @escaping InsertionCompletion) {
        let config = self.config
        queue.async(flags: .barrier) {
            autoreleasepool {
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
        }
    }
    
    private static func mapRealm(_ feed: [LocalFeedImage], timestamp: Date) -> RealmFeedCache {
        return RealmFeedCache(value: ["timestamp": timestamp, "feed": feed.toRealmModel()])
    }
}

extension RealmFeedStore {
    public func retrieve(completion: @escaping RetrievalCompletion) {
        let config = self.config
        queue.async {
            guard let realm = try? Realm(configuration: config) else {
                return completion(.empty)
            }
            realm.refresh()
            
            let realmCacheItems = realm.objects(RealmFeedCache.self)
            if let realmCache = realmCacheItems.first {
                completion(RealmFeedStore.map(realmCache))
            } else {
                completion(.empty)
            }
        }
    }
    
    private static func map(_ realmCache: RealmFeedCache) -> RetrieveCachedFeedResult {
        do {
            let localFeed = try RealmFeedImageMapper.toModels(realmCache.feed)
            return .found(feed: localFeed, timestamp: realmCache.timestamp)
        } catch {
            return .failure(error)
        }
    }
}

private extension Array where Element == LocalFeedImage {
    func toRealmModel() -> [RealmFeedImage] {
        self.map { RealmFeedImage(value: [$0.id.uuidString, $0.description, $0.location, $0.url.absoluteString]) }
    }
}

class FeedStoreChallengeTests: XCTestCase, FeedStoreSpecs {
  
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
	
    private func makeSUT(configuration: Realm.Configuration? = nil, file: StaticString = #file, line: UInt = #line) -> FeedStore {
		let sut = RealmFeedStore(configuration: configuration ?? testSpecificConfiguration())
        
        trackForMemoryLeaks(sut, file: file, line: line)
        
        return sut
	}
    
    private func testSpecificConfiguration() -> Realm.Configuration {
        return Realm.Configuration(inMemoryIdentifier: self.name, objectTypes: [RealmFeedImage.self, RealmFeedCache.self])
    }
    
    private func testSpecificInvalidConfiguration() -> Realm.Configuration {
        let invalidStoreURL = URL(string: "invalid://store-url")!
        return Realm.Configuration(fileURL: invalidStoreURL, objectTypes: [RealmFeedImage.self, RealmFeedCache.self])
    }
    
    private func setupRealmStrongReference() {
        strongRealmReference = try! Realm(configuration: testSpecificConfiguration())
    }
    
    private func undoRealmSideEffects() {
        strongRealmReference = nil
    }
}


//
//  This failable tests are partially complete because they are not testing
//  the read/write errors, but the error is throwed during the db opening/creation
//  operation.
//
//  We still keep the tests because they allowed us to fix the side effects of
//  error management during the retrieve phase.
//
extension FeedStoreChallengeTests: FailableInsertFeedStoreSpecs {

	func test_insert_deliversErrorOnInsertionError() {
		let sut = makeSUT(configuration: testSpecificInvalidConfiguration())

		assertThatInsertDeliversErrorOnInsertionError(on: sut)
	}

	func test_insert_hasNoSideEffectsOnInsertionError() {
        let sut = makeSUT(configuration: testSpecificInvalidConfiguration())

		assertThatInsertHasNoSideEffectsOnInsertionError(on: sut)
	}
}

extension FeedStoreChallengeTests: FailableDeleteFeedStoreSpecs {

	func test_delete_deliversErrorOnDeletionError() {
		let sut = makeSUT(configuration: testSpecificInvalidConfiguration())

		assertThatDeleteDeliversErrorOnDeletionError(on: sut)
	}

	func test_delete_hasNoSideEffectsOnDeletionError() {
        let sut = makeSUT(configuration: testSpecificInvalidConfiguration())

		assertThatDeleteHasNoSideEffectsOnDeletionError(on: sut)
	}
}
