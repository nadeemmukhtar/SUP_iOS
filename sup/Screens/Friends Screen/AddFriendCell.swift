//
//  AddFriendCell.swift
//  sup
//
//  Created by Justin Spraggins on 5/17/20.
//  Copyright © 2020 Episode 8, Inc. All rights reserved.
//

import SwiftUI

struct AddFriendCell: View {
    @ObservedObject var state: AppState

    private func showAddFriend() {
        SupAnalytics.addFriend()
        impact(style: .soft)
        self.state.showMediaPlayerDrawer = false
        self.state.showAddFriend = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            self.state.animateAddFriend = true
        }
    }
    
    var body: some View {
        Button(action: { self.showAddFriend() }){
            HStack  {
                Text("follow friends")
                    .modifier(TextModifier(size: 21, color: .white))
                    .padding(.top, 1)
            }
            .frame(width: 190, height: 56)
            .background(
                RoundedRectangle(cornerRadius: 25)
                    .foregroundColor(Color.greyButton)
            )
        }
    .buttonStyle(ButtonBounce())
    }
}
