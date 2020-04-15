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
    
    public typealias RealmInitializer = () throws -> EssentialRealm
    
    private let realmInitializer: RealmInitializer
    private let queue = DispatchQueue(label: "\(RealmFeedStore.self)", qos: .userInitiated, attributes: .concurrent)
    
    public init(initializer: @escaping RealmInitializer) {
        self.realmInitializer = initializer
    }
    
    private static func emptyCache(_ realm: EssentialRealm) {
        let cache = realm.objects(RealmFeedCache.self)
        realm.delete(cache)
    }
}

extension RealmFeedStore {
    public func deleteCachedFeed(completion: @escaping DeletionCompletion) {
        queue.async(flags: .barrier) { [weak self] in
            guard let self = self else { return }
            
            do {
                let realm = try self.realmInitializer()
                
                try realm.write(withoutNotifying: []) {
                    RealmFeedStore.emptyCache(realm)
                }
                
                completion(nil)
            } catch {
                completion(error)
            }
        }
    }
}

extension RealmFeedStore {
    public func insert(_ feed: [LocalFeedImage], timestamp: Date, completion: @escaping InsertionCompletion) {
        queue.async(flags: .barrier) { [weak self] in
            guard let self = self else { return }
            
            do {
                let realm = try self.realmInitializer()
                
                let realmCache = RealmFeedStore.mapRealm(feed, timestamp: timestamp)
                try realm.write(withoutNotifying: []) {
                    RealmFeedStore.emptyCache(realm)
                    realm.add(realmCache, update: .error)
                }
                
                completion(nil)
            } catch {
                completion(error)
            }
        }
    }
    
    private static func mapRealm(_ feed: [LocalFeedImage], timestamp: Date) -> RealmFeedCache {
        return RealmFeedCache(value: ["timestamp": timestamp, "feed": feed.toRealmModel()])
    }
}

extension RealmFeedStore {
    public func retrieve(completion: @escaping RetrievalCompletion) {
        queue.async { [weak self] in
            guard let self = self else { return }
            
            do {
                let realm = try self.realmInitializer()
                let _ = realm.refresh()
                
                let realmCacheItems = realm.objects(RealmFeedCache.self)
                if let realmCache = realmCacheItems.first {
                    completion(RealmFeedStore.map(realmCache))
                } else {
                    completion(.empty)
                }
            } catch {
                completion(.failure(error))
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

public protocol EssentialRealm {
    func objects<Element: Object>(_ type: Element.Type) -> Results<Element>
    func write<Result>(withoutNotifying tokens: [NotificationToken], _ block: (() throws -> Result)) throws -> Result
    func add(_ object: Object, update: Realm.UpdatePolicy)
    func delete<Element: Object>(_ objects: Results<Element>)
    func refresh() -> Bool
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
    
    private class RealmStub: EssentialRealm {
        
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
		let sut = makeSUT(setWriteError: true)

		assertThatInsertDeliversErrorOnInsertionError(on: sut)
	}

	func test_insert_hasNoSideEffectsOnInsertionError() {
        let sut = makeSUT(setWriteError: true)

		assertThatInsertHasNoSideEffectsOnInsertionError(on: sut)
	}
}

extension FeedStoreChallengeTests: FailableDeleteFeedStoreSpecs {

	func test_delete_deliversErrorOnDeletionError() {
		let sut = makeSUT(setWriteError: true)

		assertThatDeleteDeliversErrorOnDeletionError(on: sut)
	}

	func test_delete_hasNoSideEffectsOnDeletionError() {
        let sut = makeSUT(setWriteError: true)

		assertThatDeleteHasNoSideEffectsOnDeletionError(on: sut)
	}
}
