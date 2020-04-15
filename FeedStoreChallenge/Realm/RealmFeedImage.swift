//
//  RealmFeedImage.swift
//  FeedStoreChallenge
//
//  Created by Fabio Vendramin on 15/04/2020.
//

import Foundation
import RealmSwift


public class RealmFeedImage: Object {
    @objc dynamic var id: String = UUID().uuidString
    @objc dynamic var feedDescription: String?
    @objc dynamic var location: String?
    @objc dynamic var url: String = ""
}
