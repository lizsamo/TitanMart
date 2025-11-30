//
//  ProductViewModel.swift
//  TitanMart
//
//  Created by Elizsa Montoya on 10/22/25.
//

import Foundation

@MainActor
class ProductViewModel: ObservableObject {
    @Published var products: [Product] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var searchQuery = ""
    @Published var selectedCategory: ProductCategory?

    func fetchProducts() async {
        isLoading = true
        errorMessage = nil

        do {
            products = try await APIService.shared.fetchProducts(
                category: selectedCategory,
                searchQuery: searchQuery.isEmpty ? nil : searchQuery
            )
        } catch {
            errorMessage = error.localizedDescription
            // Clear products on error instead of showing mock data
            products = []
            print("❌ Error fetching products: \(error)")
        }

        isLoading = false
    }

    func createProduct(title: String, description: String, price: Double,
                      category: ProductCategory, condition: ProductCondition,
                      imageURLs: [String]) async throws {
        guard let user = AuthService.shared.currentUser,
              let token = AuthService.shared.getToken() else {
            throw APIError.unauthorized
        }

        let product = Product(
            title: title,
            description: description,
            price: price,
            category: category,
            condition: condition,
            imageURLs: imageURLs,
            sellerId: user.id,
            sellerName: user.displayName,
            sellerRating: user.rating.isNaN ? nil : user.rating
        )

        let createdProduct = try await APIService.shared.createProduct(product, token: token)
        products.insert(createdProduct, at: 0)
    }
}
