//
//  MyListingsView.swift
//  TitanMart
//
//  Created by Elizsa Montoya on 10/24/25.
//

import SwiftUI

struct MyListingsView: View {
    @StateObject private var productViewModel = ProductViewModel()
    @StateObject private var authService = AuthService.shared
    @State private var isLoading = true
    @State private var myProducts: [Product] = []
    @State private var debugInfo = ""

    var body: some View {
        List {
            if isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, alignment: .center)
            } else if myProducts.isEmpty {
                VStack(spacing: 10) {
                    Image(systemName: "tray")
                        .font(.system(size: 50))
                        .foregroundColor(.gray)
                    Text("No listings yet")
                        .foregroundColor(.secondary)
                    Text("Start selling by listing an item!")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    if !debugInfo.isEmpty {
                        Text(debugInfo)
                            .font(.caption2)
                            .foregroundColor(.red)
                            .padding()
                    }
                }
                .frame(maxWidth: .infinity, alignment: .center)
                .padding()
            } else {
                ForEach(myProducts) { product in
                    NavigationLink(destination: ProductDetailView(product: product)) {
                        MyListingRowView(product: product)
                    }
                }
            }

            if let error = productViewModel.errorMessage {
                Text("Error: \(error)")
                    .foregroundColor(.red)
                    .font(.caption)
            }
        }
        .navigationTitle("My Listings")
        .task {
            await loadMyListings()
        }
        .refreshable {
            await loadMyListings()
        }
    }

    private func loadMyListings() async {
        guard let currentUser = authService.currentUser else {
            debugInfo = "No user logged in"
            return
        }

        isLoading = true
        await productViewModel.fetchProducts()

        let allProductsCount = productViewModel.products.count

        // Filter products by current user's sellerId
        myProducts = productViewModel.products.filter { product in
            product.sellerId == currentUser.id
        }

        debugInfo = "User ID: \(currentUser.id.prefix(8))...\nTotal products: \(allProductsCount)\nYour products: \(myProducts.count)"

        print("DEBUG - Current User ID: \(currentUser.id)")
        print("DEBUG - Total Products Fetched: \(allProductsCount)")
        print("DEBUG - My Products Count: \(myProducts.count)")
        productViewModel.products.forEach { product in
            print("  Product: \(product.title) - Seller ID: \(product.sellerId)")
        }

        isLoading = false
    }
}

struct MyListingRowView: View {
    let product: Product

    var body: some View {
        HStack(spacing: 12) {
            // Product Image
            if let firstImageURL = product.imageURLs.first,
               let url = URL(string: firstImageURL) {
                AsyncImage(url: url, transaction: Transaction(animation: .default)) { phase in
                    switch phase {
                    case .empty:
                        ProgressView()
                            .frame(width: 80, height: 80)
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                            .frame(width: 80, height: 80)
                            .cornerRadius(8)
                            .clipped()
                    case .failure(let error):
                        Image(systemName: "photo")
                            .font(.largeTitle)
                            .foregroundColor(.gray)
                            .frame(width: 80, height: 80)
                            .background(Color(.systemGray6))
                            .cornerRadius(8)
                            .onAppear {
                                print("❌ Image failed to load for \(product.title)")
                                print("   URL: \(firstImageURL)")
                                print("   Error: \(error)")
                            }
                    @unknown default:
                        EmptyView()
                    }
                }
                .onAppear {
                    print("🖼️ Loading image for \(product.title): \(firstImageURL)")
                }
            } else {
                Image(systemName: "photo")
                    .font(.largeTitle)
                    .foregroundColor(.gray)
                    .frame(width: 80, height: 80)
                    .onAppear {
                        print("⚠️ No image URL for \(product.title), imageURLs: \(product.imageURLs)")
                    }
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
            }

            // Product Info
            VStack(alignment: .leading, spacing: 4) {
                Text(product.title)
                    .font(.headline)
                    .lineLimit(2)

                Text("$\(product.price, specifier: "%.2f")")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.titanOrange)

                HStack {
                    Text(product.condition.rawValue)
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Text("•")
                        .foregroundColor(.secondary)

                    Text(product.isAvailable ? "Available" : "Sold")
                        .font(.caption)
                        .foregroundColor(product.isAvailable ? .success : .secondary)
                }
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 8)
    }
}

#Preview {
    NavigationView {
        MyListingsView()
    }
}
