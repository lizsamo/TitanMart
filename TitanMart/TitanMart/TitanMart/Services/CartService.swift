//
//  CartService.swift
//  TitanMart
//
//  Created by Elizsa Montoya on 10/22/25.
//

import Foundation

class CartService: ObservableObject {
    static let shared = CartService()

    @Published var items: [CartItem] = []

    var totalPrice: Double {
        items.reduce(0) { $0 + $1.totalPrice }
    }

    var itemCount: Int {
        items.reduce(0) { $0 + $1.quantity }
    }

    private init() {
        loadCart()
    }

    // MARK: - Cart Operations
    func addToCart(_ product: Product, quantity: Int = 1) {
        if let index = items.firstIndex(where: { $0.product.id == product.id }) {
            items[index].quantity += quantity
        } else {
            let cartItem = CartItem(product: product, quantity: quantity)
            items.append(cartItem)
        }
        saveCart()
    }

    func removeFromCart(_ item: CartItem) {
        items.removeAll { $0.id == item.id }
        saveCart()
    }

    func updateQuantity(for item: CartItem, quantity: Int) {
        if let index = items.firstIndex(where: { $0.id == item.id }) {
            if quantity > 0 {
                items[index].quantity = quantity
            } else {
                items.remove(at: index)
            }
            saveCart()
        }
    }

    func clearCart() {
        items.removeAll()
        saveCart()
    }

    // MARK: - Persistence
    private func saveCart() {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        if let data = try? encoder.encode(items) {
            UserDefaults.standard.set(data, forKey: "cartItems")
        }
    }

    private func loadCart() {
        if let data = UserDefaults.standard.data(forKey: "cartItems") {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            if let items = try? decoder.decode([CartItem].self, from: data) {
                self.items = items
            }
        }
    }
}
