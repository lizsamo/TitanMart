//
//  OrderViewModel.swift
//  TitanMart
//
//  Created by Elizsa Montoya on 10/22/25.
//

import Foundation

@MainActor
class OrderViewModel: ObservableObject {
    @Published var orders: [Order] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    func fetchOrders() async {
        guard let user = AuthService.shared.currentUser,
              let token = AuthService.shared.getToken() else {
            return
        }

        isLoading = true
        errorMessage = nil

        do {
            orders = try await APIService.shared.fetchOrders(userId: user.id, token: token)
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    func createOrder(items: [CartItem]) async throws -> Order {
        guard let user = AuthService.shared.currentUser,
              let token = AuthService.shared.getToken() else {
            throw APIError.unauthorized
        }

        // For simplicity, assuming single seller per order
        // In production, you'd want to split orders by seller
        let firstItem = items.first!
        let totalAmount = items.reduce(0) { $0 + $1.totalPrice }

        let order = Order(
            items: items,
            buyerId: user.id,
            buyerName: user.displayName,
            sellerId: firstItem.product.sellerId,
            sellerName: firstItem.product.sellerName,
            totalAmount: totalAmount
        )

        let createdOrder = try await APIService.shared.createOrder(order, token: token)
        orders.insert(createdOrder, at: 0)
        return createdOrder
    }
}
