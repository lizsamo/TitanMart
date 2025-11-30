//
//  LeaveReviewView.swift
//  TitanMart
//
//  User rating and review submission view
//

import SwiftUI

struct LeaveReviewView: View {
    let order: Order
    let reviewedUser: User
    @Environment(\.dismiss) private var dismiss
    @StateObject private var authService = AuthService.shared

    @State private var rating: Int = 5
    @State private var comment: String = ""
    @State private var isSubmitting = false
    @State private var errorMessage: String?
    @State private var showSuccess = false

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 25) {
                    // User Info
                    VStack(spacing: 10) {
                        Text("Review \(reviewedUser.displayName)")
                            .font(.title2)
                            .fontWeight(.bold)

                        Text("Order #\(order.id.prefix(8))")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    .padding(.top)

                    // Star Rating
                    VStack(spacing: 10) {
                        Text("How was your experience?")
                            .font(.headline)

                        HStack(spacing: 15) {
                            ForEach(1...5, id: \.self) { star in
                                Button(action: {
                                    rating = star
                                }) {
                                    Image(systemName: star <= rating ? "star.fill" : "star")
                                        .font(.system(size: 35))
                                        .foregroundColor(star <= rating ? .yellow : .gray)
                                }
                            }
                        }

                        Text(ratingText)
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                    .padding(.vertical)

                    // Comment Section
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Comments (Optional)")
                            .font(.headline)

                        TextEditor(text: $comment)
                            .frame(height: 120)
                            .padding(8)
                            .background(Color(UIColor.systemGray6))
                            .cornerRadius(10)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                            )

                        Text("\(comment.count)/500 characters")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }

                    // Error Message
                    if let error = errorMessage {
                        Text(error)
                            .font(.caption)
                            .foregroundColor(.red)
                            .multilineTextAlignment(.center)
                    }

                    // Submit Button
                    Button(action: submitReview) {
                        if isSubmitting {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        } else {
                            Text("Submit Review")
                                .fontWeight(.semibold)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                    .disabled(isSubmitting)

                    Spacer()
                }
                .padding()
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .alert("Review Submitted!", isPresented: $showSuccess) {
                Button("OK") {
                    dismiss()
                }
            } message: {
                Text("Thank you for your feedback!")
            }
        }
    }

    private var ratingText: String {
        switch rating {
        case 1: return "Poor"
        case 2: return "Fair"
        case 3: return "Good"
        case 4: return "Very Good"
        case 5: return "Excellent"
        default: return ""
        }
    }

    private func submitReview() {
        guard let currentUser = authService.currentUser,
              let token = authService.getToken() else {
            errorMessage = "You must be logged in to submit a review"
            return
        }

        // Validate comment length
        if comment.count > 500 {
            errorMessage = "Comment cannot exceed 500 characters"
            return
        }

        errorMessage = nil
        isSubmitting = true

        Task {
            do {
                let review = Review(
                    rating: rating,
                    comment: comment,
                    reviewerId: currentUser.csufEmail,
                    reviewerName: currentUser.displayName,
                    reviewedUserId: reviewedUser.csufEmail,
                    orderId: order.id
                )

                _ = try await APIService.shared.createReview(review, token: token)

                await MainActor.run {
                    isSubmitting = false
                    showSuccess = true
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    isSubmitting = false
                }
            }
        }
    }
}

#Preview {
    LeaveReviewView(
        order: Order(
            id: "test123",
            items: [],
            buyerId: "buyer@csu.fullerton.edu",
            totalAmount: 50.0,
            status: .completed
        ),
        reviewedUser: User(
            csufEmail: "seller@csu.fullerton.edu",
            username: "seller",
            fullName: "John Seller"
        )
    )
}
