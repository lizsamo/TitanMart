//
//  SignupView.swift
//  TitanMart
//
//  Created by Elizsa Montoya on 10/22/25.
//

import SwiftUI

struct SignupView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var authService = AuthService.shared

    @State private var fullName = ""
    @State private var username = ""
    @State private var csufEmail = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var isLoading = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    Text("Create Account")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .padding(.bottom, 20)

                    VStack(spacing: 15) {
                        TextField("Full Name", text: $fullName)
                            .textFieldStyle(RoundedBorderTextFieldStyle())

                        TextField("Username", text: $username)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .textInputAutocapitalization(.never)

                        VStack(alignment: .leading, spacing: 5) {
                            TextField("CSUF Email", text: $csufEmail)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .textInputAutocapitalization(.never)
                                .keyboardType(.emailAddress)

                            Text("Must end with @csu.fullerton.edu")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }

                        SecureField("Password", text: $password)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .textContentType(.oneTimeCode)
                            .autocorrectionDisabled()
                            .textInputAutocapitalization(.never)

                        SecureField("Confirm Password", text: $confirmPassword)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .textContentType(.oneTimeCode)
                            .autocorrectionDisabled()
                            .textInputAutocapitalization(.never)

                        if let error = errorMessage {
                            Text(error)
                                .font(.caption)
                                .foregroundColor(.red)
                                .multilineTextAlignment(.center)
                        }

                        Button(action: signup) {
                            if isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            } else {
                                Text("Sign Up")
                                    .fontWeight(.semibold)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                        .disabled(isLoading || !isFormValid)
                    }
                    .padding(.horizontal)
                }
                .padding()
            }
            .navigationBarItems(trailing: Button("Cancel") {
                dismiss()
            })
        }
    }

    private var isFormValid: Bool {
        !fullName.isEmpty &&
        !username.isEmpty &&
        !csufEmail.isEmpty &&
        csufEmail.lowercased().hasSuffix("@csu.fullerton.edu") &&
        !password.isEmpty &&
        password == confirmPassword &&
        password.count >= 6
    }

    private func signup() {
        errorMessage = nil
        isLoading = true

        Task {
            do {
                try await authService.register(
                    username: username,
                    password: password,
                    csufEmail: csufEmail,
                    fullName: fullName
                )
                dismiss()
            } catch let apiError as APIError {
                errorMessage = apiError.localizedDescription
            } catch {
                errorMessage = error.localizedDescription
            }
            isLoading = false
        }
    }
}

#Preview {
    SignupView()
}
