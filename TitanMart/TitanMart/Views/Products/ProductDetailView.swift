//
//  ProductDetailView.swift
//  TitanMart
//
//  Created by Elizsa Montoya on 10/22/25.
//

import SwiftUI

struct ProductDetailView: View {
    let product: Product
    @StateObject private var cartService = CartService.shared
    @State private var showingAddedToCart = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                // Hero Product Image with Gradient
                ZStack(alignment: .bottom) {
                    LinearGradient(
                        colors: [Color.titanBlue.opacity(0.4), Color.titanOrange.opacity(0.3)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    .frame(height: 350)
                    .overlay(
                        VStack(spacing: 12) {
                            Image(systemName: categoryIcon(for: product.category))
                                .font(.system(size: 100))
                                .foregroundColor(.white)
                            Text(product.category.rawValue)
                                .font(.headline)
                                .foregroundColor(.white.opacity(0.9))
                        }
                    )

                    // Condition Badge
                    HStack {
                        Text(product.condition.rawValue)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(conditionColor(for: product.condition))
                            .cornerRadius(20)
                        Spacer()
                    }
                    .padding()
                }

                VStack(alignment: .leading, spacing: Spacing.lg) {
                    // Title and Price
                    VStack(alignment: .leading, spacing: Spacing.sm) {
                        Text(product.title)
                            .font(.appTitle)
                            .foregroundColor(.primary)

                        HStack(alignment: .firstTextBaseline, spacing: 4) {
                            Text("$\(product.price, specifier: "%.0f")")
                                .font(.system(size: 36, weight: .bold, design: .rounded))
                                .foregroundColor(.titanOrange)
                            Text("USD")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.top, Spacing.lg)

                    // Condition and Category
                    HStack {
                        VStack(alignment: .leading) {
                            Text("Condition")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text(product.condition.rawValue)
                                .font(.subheadline)
                                .fontWeight(.semibold)
                        }

                        Spacer()

                        VStack(alignment: .trailing) {
                            Text("Category")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text(product.category.rawValue)
                                .font(.subheadline)
                                .fontWeight(.semibold)
                        }
                    }

                    Divider()

                    // Description
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Description")
                            .font(.headline)
                        Text(product.description)
                            .font(.body)
                            .foregroundColor(.secondary)
                    }

                    Divider()

                    // Seller Info
                    HStack {
                        VStack(alignment: .leading) {
                            Text("Seller")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text(product.sellerName)
                                .font(.subheadline)
                                .fontWeight(.semibold)
                        }

                        Spacer()

                        HStack(spacing: 4) {
                            Image(systemName: "star.fill")
                                .foregroundColor(.orange)
                            Text(String(format: "%.1f", product.sellerRating ?? 0.0))
                                .font(.subheadline)
                                .fontWeight(.semibold)
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(10)

                    // Location
                    HStack {
                        Image(systemName: "location.fill")
                            .foregroundColor(.blue)
                        Text(product.location)
                            .font(.subheadline)
                    }

                    // Add to Cart Button
                    Button(action: addToCart) {
                        HStack(spacing: Spacing.sm) {
                            Image(systemName: "cart.badge.plus")
                                .font(.title3)
                            Text("Add to Cart")
                                .font(.headline)
                        }
                    }
                    .buttonStyle(PrimaryButtonStyle())
                    .disabled(!product.isAvailable)

                    if !product.isAvailable {
                        Text("This item is no longer available")
                            .font(.caption)
                            .foregroundColor(.red)
                            .multilineTextAlignment(.center)
                            .frame(maxWidth: .infinity)
                    }
                }
                .padding(.horizontal)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .alert("Added to Cart", isPresented: $showingAddedToCart) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("\(product.title) has been added to your cart.")
        }
    }

    private func addToCart() {
        cartService.addToCart(product)
        showingAddedToCart = true
    }

    private func categoryIcon(for category: ProductCategory) -> String {
        switch category {
        case .textbooks: return "book.fill"
        case .electronics: return "laptopcomputer"
        case .furniture: return "chair.fill"
        case .clothing: return "tshirt.fill"
        case .supplies: return "pencil.and.list.clipboard"
        case .tickets: return "ticket.fill"
        case .other: return "square.grid.2x2.fill"
        }
    }

    private func conditionColor(for condition: ProductCondition) -> Color {
        switch condition {
        case .new: return Color.green
        case .likeNew: return Color.blue
        case .good: return Color.orange
        case .fair: return Color.orange.opacity(0.7)
        case .poor: return Color.red
        }
    }
}

#Preview {
    NavigationView {
        ProductDetailView(product: Product(
            title: "Sample Product",
            description: "This is a sample product for preview",
            price: 45.00,
            category: .textbooks,
            condition: .likeNew,
            imageURLs: [],
            sellerId: "preview-seller",
            sellerName: "Preview User",
            sellerRating: 4.8
        ))
    }
}
