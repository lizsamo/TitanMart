//
//  SellItemView.swift
//  TitanMart
//
//  Created by Elizsa Montoya on 10/24/25.
//

import SwiftUI
import PhotosUI

struct SellItemView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var authService = AuthService.shared

    // Form fields
    @State private var title = ""
    @State private var description = ""
    @State private var priceText = ""
    @State private var selectedCategory: ProductCategory = .other
    @State private var selectedCondition: ProductCondition = .good
    @State private var location = "CSUF Campus"

    // Image picker
    @State private var selectedImages: [UIImage] = []
    @State private var showingImagePicker = false

    // UI state
    @State private var isSubmitting = false
    @State private var errorMessage: String?
    @State private var showingSuccess = false

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: Spacing.lg) {
                    // Header
                    VStack(spacing: Spacing.sm) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 50))
                            .foregroundColor(.titanOrange)

                        Text("List Your Item")
                            .font(.appTitle)
                            .foregroundColor(.titanBlue)

                        Text("Sell to fellow CSUF students")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.top)

                    // Photo Section
                    VStack(alignment: .leading, spacing: Spacing.md) {
                        Label("Photos", systemImage: "photo")
                            .font(.sectionTitle)
                            .foregroundColor(.titanBlue)

                        if selectedImages.isEmpty {
                            Button(action: { showingImagePicker = true }) {
                                VStack(spacing: Spacing.sm) {
                                    Image(systemName: "camera.fill")
                                        .font(.largeTitle)
                                        .foregroundColor(.gray)
                                    Text("Add Photos")
                                        .font(.bodyText)
                                        .foregroundColor(.secondary)
                                }
                                .frame(maxWidth: .infinity)
                                .frame(height: 150)
                                .background(Color(.systemGray6))
                                .cornerRadius(CornerRadius.medium)
                            }
                        } else {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: Spacing.sm) {
                                    ForEach(Array(selectedImages.enumerated()), id: \.offset) { index, image in
                                        ZStack(alignment: .topTrailing) {
                                            Image(uiImage: image)
                                                .resizable()
                                                .scaledToFill()
                                                .frame(width: 100, height: 100)
                                                .cornerRadius(CornerRadius.small)
                                                .clipped()

                                            Button(action: { selectedImages.remove(at: index) }) {
                                                Image(systemName: "xmark.circle.fill")
                                                    .foregroundColor(.white)
                                                    .background(Circle().fill(Color.black.opacity(0.6)))
                                            }
                                            .padding(4)
                                        }
                                    }

                                    Button(action: { showingImagePicker = true }) {
                                        VStack {
                                            Image(systemName: "plus")
                                                .font(.title2)
                                        }
                                        .frame(width: 100, height: 100)
                                        .background(Color(.systemGray6))
                                        .cornerRadius(CornerRadius.small)
                                    }
                                }
                            }
                        }

                        Text("Add up to 5 photos (optional)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(Spacing.lg)
                    .background(Color.cardBackground)
                    .cardStyle()

                    // Item Details Section
                    VStack(alignment: .leading, spacing: Spacing.md) {
                        Label("Item Details", systemImage: "info.circle")
                            .font(.sectionTitle)
                            .foregroundColor(.titanBlue)

                        VStack(alignment: .leading, spacing: Spacing.xs) {
                            Text("Title")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(.secondary)
                            TextField("e.g., iPhone 13 Pro", text: $title)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                        }

                        VStack(alignment: .leading, spacing: Spacing.xs) {
                            Text("Description")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(.secondary)
                            TextEditor(text: $description)
                                .frame(height: 100)
                                .padding(4)
                                .background(Color(.systemGray6))
                                .cornerRadius(CornerRadius.small)
                        }

                        VStack(alignment: .leading, spacing: Spacing.xs) {
                            Text("Price")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(.secondary)
                            HStack {
                                Text("$")
                                    .foregroundColor(.secondary)
                                TextField("0.00", text: $priceText)
                                    .keyboardType(.decimalPad)
                            }
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(CornerRadius.small)
                        }

                        VStack(alignment: .leading, spacing: Spacing.xs) {
                            Text("Category")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(.secondary)
                            Picker("Category", selection: $selectedCategory) {
                                ForEach(ProductCategory.allCases, id: \.self) { category in
                                    Text(category.rawValue).tag(category)
                                }
                            }
                            .pickerStyle(.menu)
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(CornerRadius.small)
                        }

                        VStack(alignment: .leading, spacing: Spacing.xs) {
                            Text("Condition")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(.secondary)
                            Picker("Condition", selection: $selectedCondition) {
                                ForEach(ProductCondition.allCases, id: \.self) { condition in
                                    Text(condition.rawValue).tag(condition)
                                }
                            }
                            .pickerStyle(.segmented)
                        }

                        VStack(alignment: .leading, spacing: Spacing.xs) {
                            Text("Pickup Location")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(.secondary)
                            TextField("e.g., Pollak Library", text: $location)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                        }
                    }
                    .padding(Spacing.lg)
                    .background(Color.cardBackground)
                    .cardStyle()

                    if let error = errorMessage {
                        Text(error)
                            .font(.caption)
                            .foregroundColor(.red)
                            .multilineTextAlignment(.center)
                            .padding()
                    }

                    // Submit Button
                    Button(action: submitListing) {
                        if isSubmitting {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        } else {
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                Text("List Item")
                            }
                        }
                    }
                    .buttonStyle(PrimaryButtonStyle())
                    .disabled(isSubmitting || !isFormValid)
                    .padding(.bottom, Spacing.lg)
                }
                .padding()
            }
            .navigationTitle("Sell Item")
            .navigationBarItems(trailing: Button("Cancel") {
                dismiss()
            })
            .sheet(isPresented: $showingImagePicker) {
                ImagePicker(images: $selectedImages, maxSelection: 5)
            }
            .alert("Success!", isPresented: $showingSuccess) {
                Button("View My Listings") {
                    dismiss()
                }
                Button("List Another Item") {
                    // Reset form
                    title = ""
                    description = ""
                    priceText = ""
                    selectedCategory = .other
                    selectedCondition = .good
                    location = "CSUF Campus"
                    selectedImages = []
                    showingSuccess = false
                }
            } message: {
                Text("Your item has been listed successfully!")
            }
        }
    }

    private var isFormValid: Bool {
        !title.isEmpty &&
        !description.isEmpty &&
        !priceText.isEmpty &&
        Double(priceText) != nil &&
        !location.isEmpty
    }

    private func submitListing() {
        guard let user = authService.currentUser,
              let token = authService.getToken(),
              let price = Double(priceText) else {
            errorMessage = "Invalid form data"
            return
        }

        errorMessage = nil
        isSubmitting = true

        Task {
            do {
                // Step 1: Upload images to S3 if any
                var imageURLs: [String] = []
                if !selectedImages.isEmpty {
                    imageURLs = try await APIService.shared.uploadImages(selectedImages, token: token)
                }

                // Step 2: Create product with image URLs
                let product = Product(
                    title: title,
                    description: description,
                    price: price,
                    category: selectedCategory,
                    condition: selectedCondition,
                    imageURLs: imageURLs,
                    sellerId: user.id,
                    sellerName: user.displayName,
                    sellerRating: user.rating.isNaN ? nil : user.rating,
                    location: location
                )

                _ = try await APIService.shared.createProduct(product, token: token)
                showingSuccess = true
            } catch let apiError as APIError {
                errorMessage = apiError.localizedDescription
            } catch {
                errorMessage = error.localizedDescription
            }
            isSubmitting = false
        }
    }
}

// MARK: - Image Picker
struct ImagePicker: UIViewControllerRepresentable {
    @Binding var images: [UIImage]
    let maxSelection: Int
    @Environment(\.dismiss) var dismiss

    func makeUIViewController(context: Context) -> PHPickerViewController {
        var config = PHPickerConfiguration()
        config.filter = .images
        config.selectionLimit = maxSelection

        let picker = PHPickerViewController(configuration: config)
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, PHPickerViewControllerDelegate {
        let parent: ImagePicker

        init(_ parent: ImagePicker) {
            self.parent = parent
        }

        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            parent.dismiss()

            for result in results {
                if result.itemProvider.canLoadObject(ofClass: UIImage.self) {
                    result.itemProvider.loadObject(ofClass: UIImage.self) { image, error in
                        if let image = image as? UIImage {
                            DispatchQueue.main.async {
                                self.parent.images.append(image)
                            }
                        }
                    }
                }
            }
        }
    }
}

#Preview {
    SellItemView()
}
