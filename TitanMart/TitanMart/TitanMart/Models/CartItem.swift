//
//  CartItem.swift
//  TitanMart
//
//  Created by Elizsa Montoya on 10/22/25.
//

import Foundation

struct CartItem: Identifiable, Codable {
    let id: String
    var product: Product
    var quantity: Int
    var addedAt: Date

    var totalPrice: Double {
        product.price * Double(quantity)
    }

    init(id: String = UUID().uuidString,
         product: Product,
         quantity: Int = 1,
         addedAt: Date = Date()) {
        self.id = id
        self.product = product
        self.quantity = quantity
        self.addedAt = addedAt
    }
}
