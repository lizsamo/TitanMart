//
//  AuthService.swift
//  TitanMart
//
//  Created by Elizsa Montoya on 10/22/25.
//

import Foundation

class AuthService: ObservableObject {
    static let shared = AuthService()

    @Published var currentUser: User?
    @Published var isAuthenticated = false

    private var authToken: String?

    private init() {
        loadStoredAuth()
    }

    // MARK: - Authentication Methods
    func register(username: String, password: String, csufEmail: String, fullName: String) async throws {
        // Validate CSUF email
        guard csufEmail.lowercased().hasSuffix("@csu.fullerton.edu") else {
            throw APIError.serverError("Must use a valid CSUF email address (@csu.fullerton.edu)")
        }

        let user = try await APIService.shared.register(
            username: username,
            password: password,
            csufEmail: csufEmail,
            fullName: fullName
        )

        await MainActor.run {
            self.currentUser = user
            // Don't mark as authenticated - user needs to verify email first
            self.isAuthenticated = false
        }
    }

    func login(username: String, password: String) async throws {
        let (user, token) = try await APIService.shared.login(username: username, password: password)

        await MainActor.run {
            self.currentUser = user
            self.authToken = token

            // Only mark as authenticated if email is verified
            if user.isEmailVerified {
                self.isAuthenticated = true
                self.saveAuth(user: user, token: token)
            } else {
                // User needs to verify email first
                self.isAuthenticated = false
            }
        }
    }

    func logout() {
        currentUser = nil
        authToken = nil
        isAuthenticated = false
        clearStoredAuth()
    }

    func verifyEmail(code: String) async throws {
        guard let csufEmail = currentUser?.csufEmail else {
            throw APIError.unauthorized
        }

        let user = try await APIService.shared.verifyEmail(code: code, csufEmail: csufEmail)

        await MainActor.run {
            self.currentUser = user
            // Mark as authenticated after successful verification
            self.isAuthenticated = true
            if let token = self.authToken {
                self.saveAuth(user: user, token: token)
            }
        }
    }

    func resendVerificationCode(csufEmail: String) async throws {
        _ = try await APIService.shared.resendVerificationCode(csufEmail: csufEmail)
    }

    func refreshUserProfile() async throws {
        guard let csufEmail = currentUser?.csufEmail else {
            throw APIError.unauthorized
        }

        let user = try await APIService.shared.getUserProfile(csufEmail: csufEmail)

        await MainActor.run {
            self.currentUser = user
            if let token = self.authToken {
                self.saveAuth(user: user, token: token)
            }
        }
    }

    func getToken() -> String? {
        return authToken
    }

    // MARK: - Persistence
    private func saveAuth(user: User, token: String) {
        let encoder = JSONEncoder()
        if let userData = try? encoder.encode(user) {
            UserDefaults.standard.set(userData, forKey: "currentUser")
            UserDefaults.standard.set(token, forKey: "authToken")
        }
    }

    private func loadStoredAuth() {
        if let userData = UserDefaults.standard.data(forKey: "currentUser"),
           let token = UserDefaults.standard.string(forKey: "authToken") {
            let decoder = JSONDecoder()
            if let user = try? decoder.decode(User.self, from: userData) {
                self.currentUser = user
                self.authToken = token
                self.isAuthenticated = true
            }
        }
    }

    private func clearStoredAuth() {
        UserDefaults.standard.removeObject(forKey: "currentUser")
        UserDefaults.standard.removeObject(forKey: "authToken")
    }
}
