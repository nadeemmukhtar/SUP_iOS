//
//  SignInWithApple.swift
//  sup
//
//  Created by Robert Malko on 2/11/20.
//  Copyright © 2020 Episode 8, Inc. All rights reserved.
//

import SwiftUI
import AuthenticationServices

final class SignInWithApple: UIViewRepresentable {
  func makeUIView(context: Context) -> ASAuthorizationAppleIDButton {
    return ASAuthorizationAppleIDButton()
  }

  func updateUIView(_ uiView: ASAuthorizationAppleIDButton, context: Context) {}
}
