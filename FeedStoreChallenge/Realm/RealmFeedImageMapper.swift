//
//  RealmFeedImageMapper.swift
//  FeedStoreChallenge
//
//  Created by Fabio Vendramin on 15/04/2020.
//

import Foundation
import RealmSwift


internal class RealmFeedImageMapper {
    
    enum Convert: Error {
        case idmapping
        case urlmapping
    }
    
    internal static func toModels(_ realmFeedImages: List<RealmFeedImage>) throws -> [LocalFeedImage] {
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
