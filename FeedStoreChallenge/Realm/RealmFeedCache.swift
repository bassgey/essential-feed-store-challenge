//
//  RealmFeedCache.swift
//  FeedStoreChallenge
//
//  Created by Fabio Vendramin on 15/04/2020.
//

import Foundation
import RealmSwift


public class RealmFeedCache: Object {
    @objc dynamic var timestamp = Date()
    let feed = List<RealmFeedImage>()
}
