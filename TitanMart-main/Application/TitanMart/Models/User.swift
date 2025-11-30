//
//  User.swift
//  TitanMart
//
//  Created by Elizsa Montoya on 10/22/25.
//

import Foundation

struct User: Identifiable, Codable {
    var id: String { csufEmail } // csufEmail is the unique identifier
    var csufEmail: String
    var username: String
    var fullName: String
    var isEmailVerified: Bool
    var profileImageURL: String?
    var rating: Double
    var totalRatings: Int
    var createdAt: Date

    var displayName: String {
        fullName.isEmpty ? username : fullName
    }

    enum CodingKeys: String, CodingKey {
        case csufEmail
        case username
        case fullName
        case isEmailVerified
        case profileImageURL
        case rating
        case totalRatings
        case createdAt
    }

    init(csufEmail: String,
         username: String,
         fullName: String = "",
         isEmailVerified: Bool = false,
         profileImageURL: String? = nil,
         rating: Double = 0.0,
         totalRatings: Int = 0,
         createdAt: Date = Date()) {
        self.csufEmail = csufEmail
        self.username = username
        self.fullName = fullName
        self.isEmailVerified = isEmailVerified
        self.profileImageURL = profileImageURL
        self.rating = rating
        self.totalRatings = totalRatings
        self.createdAt = createdAt
    }
}
