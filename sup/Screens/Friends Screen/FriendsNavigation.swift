//
//  FriendsNavigation.swift
//  sup
//
//  Created by Justin Spraggins on 5/7/20.
//  Copyright © 2020 Episode 8, Inc. All rights reserved.
//

import SwiftUI

private var renders = 0

struct FriendsNavigation: View {
    @ObservedObject var state: AppState

    var body: some View {
        if debugViewRenders {
            renders += 1
            print("FriendsNavigation#body renders=\(renders)")
        }

        return ZStack {
            if self.state.showRecents {
                RecentScreen(state: state)
                    .opacity(self.state.showAddFriend ? 0 : 1)
                    .frame(width: screenWidth, height: screenHeight)
                    .edgesIgnoringSafeArea(.all)
            } else {
                FriendsScreen(state: state)
                    .opacity(self.state.showAddFriend ? 0 : 1)
                    .frame(width: screenWidth, height: screenHeight)
                    .edgesIgnoringSafeArea(.all)
            }

            VStack {
                Color.backgroundColor
                    .frame(width: screenWidth, height: isIPhoneX ? 145 : 95)
//                    .shadow(color: Color.backgroundColor.opacity(0.5), radius: 10, x: 0, y: 0)
                Spacer()
            }
            .frame(width: screenWidth, height: screenHeight)
            .edgesIgnoringSafeArea(.all)
            
            if self.state.showAddFriend {
                AddFriends(state: state)
            }
        }
    }
}
