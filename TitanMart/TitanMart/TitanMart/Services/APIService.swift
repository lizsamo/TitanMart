//
//  APIService.swift
//  TitanMart
//
//  Created by Elizsa Montoya on 10/22/25.
//

import Foundation
import UIKit

enum APIError: Error {
    case invalidURL
    case invalidResponse
    case networkError(Error)
    case decodingError(Error)
    case serverError(String)
    case unauthorized

    var localizedDescription: String {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .invalidResponse:
            return "Invalid response from server"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .decodingError(let error):
            return "Decoding error: \(error.localizedDescription)"
        case .serverError(let message):
            return "Server error: \(message)"
        case .unauthorized:
            return "Unauthorized access"
        }
    }
}

class APIService {
    static let shared = APIService()

    // AWS API Gateway endpoint
    private let baseURL = "https://sqcbfiukk0.execute-api.us-east-2.amazonaws.com/dev/api"

    private init() {}

    // Request Method
    func request<T: Decodable>(
        endpoint: String,
        method: String = "GET",
        body: Data? = nil,
        token: String? = nil
    ) async throws -> T {
        guard let url = URL(string: "\(baseURL)\(endpoint)") else {
            throw APIError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        if let token = token {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        if let body = body {
            request.httpBody = body
        }

        do {
            let (data, response) = try await URLSession.shared.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                throw APIError.invalidResponse
            }

            if httpResponse.statusCode == 401 {
                throw APIError.unauthorized
            }

            guard (200...299).contains(httpResponse.statusCode) else {
                if let errorMessage = try? JSONDecoder().decode([String: String].self, from: data),
                   let message = errorMessage["message"] {
                    throw APIError.serverError(message)
                }
                throw APIError.serverError("Status code: \(httpResponse.statusCode)")
            }

            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .custom { decoder in
                let container = try decoder.singleValueContainer()
                let dateString = try container.decode(String.self)

                let formatter = ISO8601DateFormatter()
                formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
                if let date = formatter.date(from: dateString) {
                    return date
                }

                // Fallback without fractional seconds
                formatter.formatOptions = [.withInternetDateTime]
                if let date = formatter.date(from: dateString) {
                    return date
                }

                throw DecodingError.dataCorruptedError(in: container, debugDescription: "Invalid date format: \(dateString)")
            }
            return try decoder.decode(T.self, from: data)

        } catch let error as APIError {
            throw error
        } catch let error as DecodingError {
            throw APIError.decodingError(error)
        } catch {
            throw APIError.networkError(error)
        }
    }

    // Authentication
    func register(username: String, password: String, csufEmail: String, fullName: String) async throws -> User {
        let body = [
            "username": username,
            "password": password,
            "csufEmail": csufEmail,
            "fullName": fullName
        ]
        let jsonData = try JSONEncoder().encode(body)
        return try await request(endpoint: "/auth/register", method: "POST", body: jsonData)
    }

    func login(username: String, password: String) async throws -> (user: User, token: String) {
        struct LoginResponse: Decodable {
            let user: User
            let token: String
        }

        let body = ["username": username, "password": password]
        let jsonData = try JSONEncoder().encode(body)
        let response: LoginResponse = try await request(endpoint: "/auth/login", method: "POST", body: jsonData)
        return (user: response.user, token: response.token)
    }

    func verifyEmail(code: String, csufEmail: String) async throws -> User {
        let body = ["code": code, "csufEmail": csufEmail]
        let jsonData = try JSONEncoder().encode(body)
        return try await request(endpoint: "/auth/verify-email", method: "POST", body: jsonData)
    }

    func resendVerificationCode(csufEmail: String) async throws -> String {
        struct ResendResponse: Decodable {
            let message: String
        }

        let body = ["csufEmail": csufEmail]
        let jsonData = try JSONEncoder().encode(body)
        let response: ResendResponse = try await request(endpoint: "/auth/resend-verification", method: "POST", body: jsonData)
        return response.message
    }

    func getUserProfile(csufEmail: String) async throws -> User {
        let encodedEmail = csufEmail.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? csufEmail
        return try await request(endpoint: "/auth/profile/\(encodedEmail)")
    }

    func forgotPassword(username: String) async throws -> String {
        struct ForgotPasswordResponse: Decodable {
            let message: String
            let csufEmail: String
        }

        let body = ["username": username]
        let jsonData = try JSONEncoder().encode(body)
        let response: ForgotPasswordResponse = try await request(endpoint: "/auth/forgot-password", method: "POST", body: jsonData)
        return response.message
    }

    func resetPassword(username: String, code: String, newPassword: String) async throws -> String {
        struct ResetPasswordResponse: Decodable {
            let message: String
        }

        let body = ["username": username, "code": code, "newPassword": newPassword]
        let jsonData = try JSONEncoder().encode(body)
        let response: ResetPasswordResponse = try await request(endpoint: "/auth/reset-password", method: "POST", body: jsonData)
        return response.message
    }

    // Products
    func fetchProducts(category: ProductCategory? = nil, searchQuery: String? = nil) async throws -> [Product] {
        var endpoint = "/products"
        var queryItems: [String] = []

        if let category = category {
            queryItems.append("category=\(category.rawValue)")
        }
        if let query = searchQuery, !query.isEmpty {
            queryItems.append("search=\(query)")
        }

        if !queryItems.isEmpty {
            endpoint += "?" + queryItems.joined(separator: "&")
        }

        return try await request(endpoint: endpoint)
    }

    func createProduct(_ product: Product, token: String) async throws -> Product {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let jsonData = try encoder.encode(product)
        return try await request(endpoint: "/products", method: "POST", body: jsonData, token: token)
    }

    // Orders
    func createOrder(_ order: Order, token: String) async throws -> Order {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let jsonData = try encoder.encode(order)
        return try await request(endpoint: "/orders", method: "POST", body: jsonData, token: token)
    }

    func fetchOrders(userId: String, token: String) async throws -> [Order] {
        return try await request(endpoint: "/orders/user/\(userId)", token: token)
    }

    // Reviews
    struct CanReviewResponse: Decodable {
        let canReview: Bool
        let reason: String?
    }

    func canReview(orderId: String, reviewedUserId: String, token: String) async throws -> CanReviewResponse {
        let encodedReviewedUserId = reviewedUserId.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? reviewedUserId
        return try await request(endpoint: "/reviews/can-review/\(orderId)/\(encodedReviewedUserId)", token: token)
    }

    func createReview(_ review: Review, token: String) async throws -> Review {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let jsonData = try encoder.encode(review)
        return try await request(endpoint: "/reviews", method: "POST", body: jsonData, token: token)
    }

    func fetchReviews(userId: String) async throws -> [Review] {
        let encodedUserId = userId.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? userId
        return try await request(endpoint: "/reviews/user/\(encodedUserId)")
    }

    func fetchOrderReviews(orderId: String, token: String) async throws -> [Review] {
        return try await request(endpoint: "/reviews/order/\(orderId)", token: token)
    }

    // Payment
    func createPaymentIntent(amount: Double, orderId: String, token: String) async throws -> String {
        let body = ["amount": amount, "orderId": orderId] as [String : Any]
        let jsonData = try JSONSerialization.data(withJSONObject: body)
        let response: [String: String] = try await request(endpoint: "/payment/create-intent", method: "POST", body: jsonData, token: token)
        guard let clientSecret = response["clientSecret"] else {
            throw APIError.serverError("No client secret returned")
        }
        return clientSecret
    }

    // Image Upload
    func uploadImages(_ images: [UIImage], token: String) async throws -> [String] {
        guard let url = URL(string: "\(baseURL)/upload/images") else {
            throw APIError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        // Create multipart form data
        let boundary = UUID().uuidString
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

        var body = Data()

        for (index, image) in images.enumerated() {
            // Resize and compress image to reduce payload size
            guard let resizedImage = image.resizeImage(maxDimension: 1200),
                  let imageData = resizedImage.jpegData(compressionQuality: 0.7) else {
                continue
            }

            body.append("--\(boundary)\r\n".data(using: .utf8)!)
            body.append("Content-Disposition: form-data; name=\"images\"; filename=\"image\(index).jpg\"\r\n".data(using: .utf8)!)
            body.append("Content-Type: image/jpeg\r\n\r\n".data(using: .utf8)!)
            body.append(imageData)
            body.append("\r\n".data(using: .utf8)!)
        }

        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        request.httpBody = body

        do {
            let (data, response) = try await URLSession.shared.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                throw APIError.invalidResponse
            }

            guard (200...299).contains(httpResponse.statusCode) else {
                if let errorMessage = try? JSONDecoder().decode([String: String].self, from: data),
                   let message = errorMessage["message"] {
                    throw APIError.serverError(message)
                }
                throw APIError.serverError("Status code: \(httpResponse.statusCode)")
            }

            struct UploadResponse: Decodable {
                let urls: [String]
            }

            let uploadResponse = try JSONDecoder().decode(UploadResponse.self, from: data)
            return uploadResponse.urls

        } catch let error as APIError {
            throw error
        } catch {
            throw APIError.networkError(error)
        }
    }
}

// UIImage Extension for Image Resizing
extension UIImage {
    func resizeImage(maxDimension: CGFloat) -> UIImage? {
        let size = self.size

        // Check if resizing is needed
        if size.width <= maxDimension && size.height <= maxDimension {
            return self
        }

        // Calculate new size maintaining aspect ratio
        var newSize: CGSize
        if size.width > size.height {
            let ratio = maxDimension / size.width
            newSize = CGSize(width: maxDimension, height: size.height * ratio)
        } else {
            let ratio = maxDimension / size.height
            newSize = CGSize(width: size.width * ratio, height: maxDimension)
        }

        // Resize the image
        UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
        defer { UIGraphicsEndImageContext() }

        self.draw(in: CGRect(origin: .zero, size: newSize))
        return UIGraphicsGetImageFromCurrentImageContext()
    }
}
