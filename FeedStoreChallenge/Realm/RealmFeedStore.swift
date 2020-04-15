//
//  RealmFeedStore.swift
//  FeedStoreChallenge
//
//  Created by Fabio Vendramin on 15/04/2020.
//

import Foundation
import RealmSwift


public protocol EssentialRealm {
    func objects<Element: Object>(_ type: Element.Type) -> Results<Element>
    func write<Result>(withoutNotifying tokens: [NotificationToken], _ block: (() throws -> Result)) throws -> Result
    func add(_ object: Object, update: Realm.UpdatePolicy)
    func delete<Element: Object>(_ objects: Results<Element>)
    func refresh() -> Bool
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
    public static func getRequiredModelsType() -> [Object.Type] {
        return [RealmFeedCache.self, RealmFeedImage.self]
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
