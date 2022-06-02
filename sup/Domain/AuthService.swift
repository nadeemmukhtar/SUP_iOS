//
//  AuthService.swift
//  sup
//
//  Created by Robert Malko on 2/10/20.
//  Copyright © 2020 Episode 8, Inc. All rights reserved.
//

import AuthenticationServices
import CryptoKit
import FirebaseFunctions
import Firebase
import PaperTrailLumberjack

fileprivate let happyGoodTime = "4pwp4]XRB+{dj//.bB[ra&Wr"
fileprivate let hadByAll = "<;5B?N8NCsPRzu}~W$_%:$eu"

// Adapted from https://auth0.com/docs/api-auth/tutorials/nonce#generate-a-cryptographically-random-nonce
private func randomNonceString(length: Int = 32) -> String {
    precondition(length > 0)
    let charset: Array<Character> =
        Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
    var result = ""
    var remainingLength = length

    while remainingLength > 0 {
        let randoms: [UInt8] = (0 ..< 16).map { _ in
            var random: UInt8 = 0
            let errorCode = SecRandomCopyBytes(kSecRandomDefault, 1, &random)
            if errorCode != errSecSuccess {
                fatalError("Unable to generate nonce. SecRandomCopyBytes failed with OSStatus \(errorCode)")
            }
            return random
        }

        randoms.forEach { random in
            if remainingLength == 0 {
                return
            }

            if random < charset.count {
                result.append(charset[Int(random)])
                remainingLength -= 1
            }
        }
    }

    return result
}

// Unhashed nonce.
fileprivate var currentNonce: String?

struct AuthService {
    static func createCustomToken(id: String, callback: @escaping (Bool, String?) -> Void) {
        let functions = Functions.functions()
        let _id = "\(happyGoodTime)_\(id)_\(hadByAll)"
        let hash = sha256(_id)

        functions.httpsCallable("createCustomToken").call(["id": id, "hash": hash]) { (result, error) in
            if let error = error as NSError? {
                if error.domain == FunctionsErrorDomain {
                    let message = error.localizedDescription
                    print("error message=\(message)")
                } else {
                    print("error", error)
                }
                callback(true, nil)
            }
            guard let customToken = result?.data as? String else {
                return callback(true, nil)
            }
            callback(false, customToken)
        }
    }

    static func loginWithSnap(state: AppState, callback: @escaping (Bool, User?) -> Void) {
        state.getSnapchatInfo {
            if let snapId = state.snapchatExternalId {
                let sanitizedId = snapId.replacingOccurrences(of: "/", with: "_")
                AuthService.createCustomToken(id: sanitizedId) { hasError, customToken in
                    guard let customToken = customToken else {
                        return callback(true, nil)
                    }
                    AuthService.signInWithCustomToken(token: customToken) { hasError, user in
                        if hasError {
                            return callback(true, nil)
                        }
                        DispatchQueue.global(qos: .background).async {
                            if let name = state.snapchatDisplayName {
                                User.update(userID: state.currentUser?.uid, data: [
                                    "displayName": name
                                ])
                                let currentUser = state.currentUser
                                currentUser?.displayName = name
                                user?.displayName = name
                                let selectedUser = user ?? currentUser

                                DispatchQueue.main.async {
                                    state.currentUser = selectedUser
                                    callback(false, selectedUser)
                                }
                            } else {
                                callback(false, user)
                            }
                        }
                        state.uploadImage()
                    }
                }
            } else {
                callback(true, nil)
            }
        }
    }

    static func logout(callback: () -> Void) {
        do {
            try Auth.auth().signOut()
            callback()
        } catch {}
    }

    static func signInWithCustomToken(token: String, callback: @escaping (Bool, User?) -> Void) {
        Auth.auth().signIn(withCustomToken: token) { (authResult, error) in
            if let user = authResult?.user {
                User.get(user: user) { currentUser in
                    callback(false, currentUser)
                }
            } else if let error = error {
                Logger.log("Error signing in with custom token: %{public}@", log: .debug, type: .error, error.localizedDescription)
                callback(true, nil)
            } else {
                callback(true, nil)
            }
        }
    }

    @available(iOS 13, *)
    static func startSignInWithAppleFlow(delegate: ASAuthorizationControllerDelegate) {
        let nonce = randomNonceString()
        currentNonce = nonce
        let appleIDProvider = ASAuthorizationAppleIDProvider()
        let request = appleIDProvider.createRequest()
        request.requestedScopes = [.fullName, .email]
        request.nonce = sha256(nonce)

        let authorizationController = ASAuthorizationController(authorizationRequests: [request])
        authorizationController.delegate = delegate
        authorizationController.presentationContextProvider = delegate as? ASAuthorizationControllerPresentationContextProviding
        authorizationController.performRequests()
    }

    @available(iOS 13, *)
    private static func sha256(_ input: String) -> String {
        let inputData = Data(input.utf8)
        let hashedData = SHA256.hash(data: inputData)
        let hashString = hashedData.compactMap {
            return String(format: "%02x", $0)
        }.joined()

        return hashString
    }
}

class AuthServiceDelegate: NSObject {
    private let signInSucceeded: (Bool, User?) -> Void

    init(onSignedIn: @escaping (Bool, User?) -> Void) {
      self.signInSucceeded = onSignedIn
    }
}

@available(iOS 13.0, *)
extension AuthServiceDelegate: ASAuthorizationControllerDelegate {
    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        if let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential {
            guard let nonce = currentNonce else {
                DDLogError("Sign in with Apple errored: no nonce")
                return self.signInSucceeded(false, nil)
            }
            guard let appleIDToken = appleIDCredential.identityToken else {
                Logger.log("Unable to fetch identity token", log: .debug, type: .error)
                DDLogError("Sign in with Apple errored: unable to fetch identity token")
                return self.signInSucceeded(false, nil)
            }
            guard let idTokenString = String(data: appleIDToken, encoding: .utf8) else {
                Logger.log("Unable to serialize token string from data: %{private}@", log: .debug, type: .error, appleIDToken.debugDescription)
                DDLogError("Sign in with Apple errored: unable to serialize token error=\(appleIDToken.debugDescription)")
                return self.signInSucceeded(false, nil)
            }
            // Initialize a Firebase credential.
            let credential = OAuthProvider.credential(
                withProviderID: "apple.com",
                idToken: idTokenString,
                rawNonce: nonce
            )
            // Sign in with Firebase.
            Auth.auth().signIn(with: credential) { (authResult, error) in
                if let user = authResult?.user {
                    User.get(user: user) { currentUser in
                        self.signInSucceeded(true, currentUser)
                    }
                } else if let error = error {
                    // Error. If error.code == .MissingOrInvalidNonce, make sure
                    // you're sending the SHA256-hashed nonce as a hex string with
                    // your request to Apple.
                    Logger.log("Error signing in: %{public}@", log: .debug, type: .error, error.localizedDescription)
                    DDLogError("Sign in with Apple errored: error=\(error.localizedDescription)")
                    return self.signInSucceeded(false, nil)
                }
            }
        } else {
            DDLogError("Sign in with Apple errored: no credential")
            self.signInSucceeded(false, nil)
        }
    }

    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        DDLogError("Sign in with Apple errored: error=\(error.localizedDescription)")
        Logger.log("Sign in with Apple errored: %{public}@", log: .debug, type: .error, error.localizedDescription)
        self.signInSucceeded(false, nil)
    }
}
