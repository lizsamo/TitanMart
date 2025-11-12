//
//  Review.swift
//  TitanMart
//
//  Created by Elizsa Montoya on 10/22/25.
//

import Foundation

struct Review: Identifiable, Codable {
    let id: String
    var rating: Int // 1-5 stars
    var comment: String
    var reviewerId: String
    var reviewerName: String
    var reviewedUserId: String
    var productId: String?
    var createdAt: Date

    init(id: String = UUID().uuidString,
         rating: Int,
         comment: String,
         reviewerId: String,
         reviewerName: String,
         reviewedUserId: String,
         productId: String? = nil,
         createdAt: Date = Date()) {
        self.id = id
        self.rating = max(1, min(5, rating)) // Ensure rating is between 1-5
        self.comment = comment
        self.reviewerId = reviewerId
        self.reviewerName = reviewerName
        self.reviewedUserId = reviewedUserId
        self.productId = productId
        self.createdAt = createdAt
    }
}
