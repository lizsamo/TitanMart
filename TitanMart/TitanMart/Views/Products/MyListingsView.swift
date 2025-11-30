//
//  MyListingsView.swift
//  TitanMart
//
//  View to display seller's product listings with order information
//

import SwiftUI

struct MyListingsView: View {
    @StateObject private var productViewModel = ProductViewModel()
    @StateObject private var orderViewModel = OrderViewModel()
    @StateObject private var authService = AuthService.shared
    @State private var isLoading = true
    @State private var myProducts: [Product] = []
    @State private var selectedOrderForReview: Order?

    var body: some View {
        Group {
            if isLoading {
                ProgressView()
            } else if myProducts.isEmpty {
                VStack(spacing: 15) {
                    Image(systemName: "tray")
                        .font(.largeTitle)
                        .foregroundColor(.gray)
                    Text("No listings yet")
                        .font(.headline)
                        .foregroundColor(.gray)
                    Text("Start selling by listing an item!")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
            } else {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(myProducts) { product in
                            ProductListingCard(
                                product: product,
                                order: findOrderForProduct(product),
                                onReviewTapped: { order in
                                    selectedOrderForReview = order
                                }
                            )
                            .environmentObject(orderViewModel)
                        }
                    }
                    .padding()
                }
            }
        }
        .navigationTitle("My Listings")
        .task {
            await loadMyListings()
        }
        .refreshable {
            await loadMyListings()
        }
        .sheet(item: $selectedOrderForReview) { order in
            ListingReviewSheetView(order: order)
        }
    }

    private func loadMyListings() async {
        guard let currentUser = authService.currentUser else {
            return
        }

        isLoading = true

        // Fetch products and orders in parallel
        async let productsTask = productViewModel.fetchProducts()
        async let ordersTask = orderViewModel.fetchOrders()

        await productsTask
        await ordersTask

        // Filter products by current user's sellerId
        myProducts = productViewModel.products.filter { product in
            product.sellerId == currentUser.id
        }

        // Sort by creation date, newest first
        myProducts.sort { $0.createdAt > $1.createdAt }

        isLoading = false
    }

    private func findOrderForProduct(_ product: Product) -> Order? {
        // Find any order that contains this product
        return orderViewModel.orders.first { order in
            order.items.contains { item in
                item.product.id == product.id
            }
        }
    }
}

struct ProductListingCard: View {
    let product: Product
    let order: Order?
    let onReviewTapped: (Order) -> Void

    @EnvironmentObject var viewModel: OrderViewModel
    @State private var canReview = false
    @State private var reviewReason: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Product Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(product.title)
                        .font(.headline)

                    if let order = order {
                        Text(order.createdAt.formatted(date: .abbreviated, time: .shortened))
                            .font(.caption)
                            .foregroundColor(.gray)
                    } else {
                        Text("Listed on \(product.createdAt.formatted(date: .abbreviated, time: .omitted))")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }

                Spacer()

                if let order = order {
                    StatusBadge(status: order.status)
                } else {
                    Text(product.isAvailable ? "Available" : "Unavailable")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(product.isAvailable ? Color.green : Color.gray)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
            }

            // Product Image and Details
            HStack(spacing: 10) {
                if let imageURL = product.imageURLs.first,
                   let url = URL(string: imageURL) {
                    AsyncImage(url: url) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } placeholder: {
                        Color.gray.opacity(0.3)
                    }
                    .frame(width: 50, height: 50)
                    .cornerRadius(8)
                }

                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 4) {
                        Text(product.condition.rawValue)
                            .font(.caption)
                            .foregroundColor(.gray)

                        if let order = order {
                            Text("•")
                                .font(.caption)
                                .foregroundColor(.gray)

                            Text("Sold")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }

                    Text(product.category.rawValue)
                        .font(.caption)
                        .foregroundColor(.gray)
                }

                Spacer()

                Text("$\(product.price, specifier: "%.2f")")
                    .font(.subheadline)
                    .fontWeight(.semibold)
            }

            // Order Information (if sold)
            if let order = order {
                Divider()

                HStack {
                    if let buyerName = order.buyerName {
                        Text("Buyer: \(buyerName)")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }

                    Spacer()

                    if let orderTotal = order.items.first(where: { $0.product.id == product.id })?.totalPrice {
                        Text("Total: $\(orderTotal, specifier: "%.2f")")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                    }
                }

                // Review Button (only for completed orders)
                if order.status == .completed {
                    Button(action: {
                        onReviewTapped(order)
                    }) {
                        HStack {
                            Image(systemName: "star.fill")
                            Text("Leave Review for Buyer")
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                    }
                    .buttonStyle(.plain)
                    .task {
                        await checkReviewEligibility(for: order)
                    }
                    .disabled(!canReview)
                    .opacity(canReview ? 1.0 : 0.5)
                }

                if let reason = reviewReason, !canReview {
                    Text(reason)
                        .font(.caption)
                        .foregroundColor(.orange)
                }
            }
        }
        .padding()
        .background(Color(UIColor.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }

    private func checkReviewEligibility(for order: Order) async {
        guard let otherPartyId = viewModel.getOtherPartyUserId(for: order) else {
            return
        }

        let result = await viewModel.canReview(orderId: order.id, reviewedUserId: otherPartyId)
        await MainActor.run {
            canReview = result.canReview
            reviewReason = result.reason
        }
    }
}

struct ListingReviewSheetView: View {
    let order: Order

    @Environment(\.dismiss) private var dismiss
    @State private var reviewedUser: User?
    @State private var isLoading = true
    @State private var errorMessage: String?

    var body: some View {
        Group {
            if isLoading {
                ProgressView("Loading...")
            } else if let error = errorMessage {
                VStack(spacing: 15) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.largeTitle)
                        .foregroundColor(.orange)
                    Text(error)
                        .foregroundColor(.gray)
                    Button("Close") {
                        dismiss()
                    }
                    .buttonStyle(.bordered)
                }
                .padding()
            } else if let user = reviewedUser {
                LeaveReviewView(order: order, reviewedUser: user)
            }
        }
        .task {
            await loadReviewedUser()
        }
    }

    private func loadReviewedUser() async {
        let buyerId = order.buyerId

        do {
            let user = try await APIService.shared.getUserProfile(csufEmail: buyerId)
            await MainActor.run {
                reviewedUser = user
                isLoading = false
            }
        } catch {
            await MainActor.run {
                errorMessage = "Failed to load buyer profile"
                isLoading = false
            }
        }
    }
}

#Preview {
    NavigationStack {
        MyListingsView()
    }
}
