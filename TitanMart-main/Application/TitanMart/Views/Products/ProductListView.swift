//
//  ProductListView.swift
//  TitanMart
//
//  Created by Elizsa Montoya on 10/22/25.
//

import SwiftUI

struct ProductListView: View {
    @StateObject private var viewModel = ProductViewModel()
    @State private var showingFilters = false

    let columns = [
        GridItem(.flexible(), spacing: Spacing.md),
        GridItem(.flexible(), spacing: Spacing.md)
    ]

    // Filter to show only available products in browse view
    private var availableProducts: [Product] {
        viewModel.products.filter { $0.isAvailable }
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: Spacing.lg) {
                // Hero Header
                VStack(spacing: Spacing.sm) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("TitanMart")
                                .font(.appTitle)
                                .foregroundColor(.titanBlue)
                            Text("CSUF Student Marketplace")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        Image(systemName: "cart.fill")
                            .font(.title2)
                            .foregroundColor(.titanOrange)
                    }
                    .padding(.horizontal)
                    .padding(.top, Spacing.sm)
                }
                
                // Modern Search Bar
                HStack(spacing: Spacing.sm) {
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.titanBlue)
                        TextField("Search products...", text: $viewModel.searchQuery)
                            .textFieldStyle(PlainTextFieldStyle())
                        if !viewModel.searchQuery.isEmpty {
                            Button(action: { viewModel.searchQuery = "" }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.gray)
                            }
                        }
                    }
                    .padding(Spacing.md)
                    .background(Color(.systemGray6))
                    .cornerRadius(CornerRadius.medium)
                    
                    Button(action: { showingFilters = true }) {
                        Image(systemName: "slider.horizontal.3")
                            .font(.title3)
                            .foregroundColor(.white)
                            .frame(width: 44, height: 44)
                            .background(
                                LinearGradient(
                                    colors: [Color.titanBlue, Color.titanBlue.opacity(0.8)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .cornerRadius(CornerRadius.medium)
                    }
                }
                .padding(.horizontal)
                
                // Category Filter
                if let category = viewModel.selectedCategory {
                    HStack {
                        Text("Category: \(category.rawValue)")
                            .font(.subheadline)
                        Button(action: { viewModel.selectedCategory = nil }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.gray)
                        }
                    }
                    .padding(.horizontal)
                }
                
                // Products Grid
                if viewModel.isLoading {
                    ProgressView()
                        .padding()
                } else if availableProducts.isEmpty {
                    VStack(spacing: 10) {
                        Image(systemName: "cart.badge.questionmark")
                            .font(.system(size: 60))
                            .foregroundColor(.gray)
                        Text("No products available")
                            .font(.headline)
                            .foregroundColor(.gray)
                    }
                    .padding(.top, 50)
                } else {
                    LazyVGrid(columns: columns, spacing: 15) {
                        ForEach(availableProducts) { product in
                            NavigationLink(destination: ProductDetailView(product: product)) {
                                ProductCardView(product: product)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    .padding(.horizontal)
                }
            }
            .padding(.vertical)
        }
        .sheet(isPresented: $showingFilters) {
            CategoryFilterView(selectedCategory: $viewModel.selectedCategory)
        }
        .task {
            await viewModel.fetchProducts()
        }
        .refreshable {
            await viewModel.fetchProducts()
        }
        .onChange(of: viewModel.searchQuery) {
            Task {
                try? await Task.sleep(nanoseconds: 500_000_000)
                await viewModel.fetchProducts()
            }
        }
        .onChange(of: viewModel.selectedCategory) {
            Task {
                await viewModel.fetchProducts()
            }
        }
    }
}

struct ProductCardView: View {
    let product: Product

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Image placeholder with gradient
            ZStack(alignment: .topTrailing) {
                LinearGradient(
                    colors: [Color.titanBlue.opacity(0.3), Color.titanOrange.opacity(0.2)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .frame(height: 160)
                .overlay(
                    VStack(spacing: 8) {
                        Image(systemName: categoryIcon(for: product.category))
                            .font(.system(size: 50))
                            .foregroundColor(.white.opacity(0.9))
                        Text(product.category.rawValue)
                            .font(.caption2)
                            .foregroundColor(.white.opacity(0.8))
                    }
                )

                // Condition Badge
                Text(product.condition.rawValue)
                    .font(.caption2)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(conditionColor(for: product.condition))
                    .cornerRadius(6)
                    .padding(8)
            }

            VStack(alignment: .leading, spacing: 8) {
                Text(product.title)
                    .font(.cardTitle)
                    .lineLimit(2)
                    .foregroundColor(.primary)
                    .frame(height: 44, alignment: .top)

                HStack(alignment: .center, spacing: 4) {
                    Text("$\(product.price, specifier: "%.0f")")
                        .font(.priceText)
                        .foregroundColor(.titanOrange)

                    Spacer()

                    HStack(spacing: 3) {
                        Image(systemName: "star.fill")
                            .font(.caption2)
                        Text(String(format: "%.1f", product.sellerRating ?? 0.0))
                            .font(.caption)
                            .fontWeight(.medium)
                    }
                    .foregroundColor(.orange)
                }
            }
            .padding(Spacing.md)
        }
        .background(Color.cardBackground)
        .cornerRadius(CornerRadius.medium)
        .cardShadow()
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

struct CategoryFilterView: View {
    @Environment(\.dismiss) var dismiss
    @Binding var selectedCategory: ProductCategory?

    var body: some View {
        NavigationView {
            List {
                Button(action: {
                    selectedCategory = nil
                    dismiss()
                }) {
                    HStack {
                        Text("All Categories")
                        Spacer()
                        if selectedCategory == nil {
                            Image(systemName: "checkmark")
                                .foregroundColor(.blue)
                        }
                    }
                }

                ForEach(ProductCategory.allCases, id: \.self) { category in
                    Button(action: {
                        selectedCategory = category
                        dismiss()
                    }) {
                        HStack {
                            Text(category.rawValue)
                            Spacer()
                            if selectedCategory == category {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.blue)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Filter by Category")
            .navigationBarItems(trailing: Button("Done") {
                dismiss()
            })
        }
    }
}

#Preview {
    ProductListView()
}
