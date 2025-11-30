//
//  Product.swift
//  TitanMart
//
//  Created by Elizsa Montoya on 10/22/25.
//

import Foundation

enum ProductCategory: String, Codable, CaseIterable {
    case textbooks = "Books"
    case electronics = "Electronics"
    case furniture = "Furniture"
    case clothing = "Clothing"
    case supplies = "School Supplies"
    case tickets = "Event Tickets"
    case other = "Other"
}

enum ProductCondition: String, Codable, CaseIterable {
    case new = "New"
    case likeNew = "Like New"
    case good = "Good"
    case fair = "Fair"
    case poor = "Poor"
}

struct Product: Identifiable, Codable {
    let id: String
    var title: String
    var description: String
    var price: Double
    var category: ProductCategory
    var condition: ProductCondition
    var imageURLs: [String]
    var sellerId: String
    var sellerName: String
    var sellerRating: Double?
    var isAvailable: Bool
    var createdAt: Date
    var location: String

    init(id: String = UUID().uuidString,
         title: String,
         description: String,
         price: Double,
         category: ProductCategory,
         condition: ProductCondition,
         imageURLs: [String] = [],
         sellerId: String,
         sellerName: String,
         sellerRating: Double? = nil,
         isAvailable: Bool = true,
         createdAt: Date = Date(),
         location: String = "CSUF Campus") {
        self.id = id
        self.title = title
        self.description = description
        self.price = price
        self.category = category
        self.condition = condition
        self.imageURLs = imageURLs
        self.sellerId = sellerId
        self.sellerName = sellerName
        self.sellerRating = sellerRating
        self.isAvailable = isAvailable
        self.createdAt = createdAt
        self.location = location
    }
}
