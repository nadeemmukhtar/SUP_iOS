//
//  StatusBarMask.swift
//  sup
//
//  Created by Justin Spraggins on 3/6/20.
//  Copyright © 2020 Episode 8, Inc. All rights reserved.
//

import SwiftUI

struct StatusBarMask: View {
    var body: some View {

        ZStack {
            LinearGradient(gradient: Gradient(colors: [ Color.black.opacity(1), Color.black.opacity(0) ]),
                           startPoint: .top,
                           endPoint: .bottom
            ).frame(width: screenWidth, height: isIPhoneX ? 64 : 30, alignment: .center)
            Spacer()
        }
        .frame(
            minWidth: 0,
            idealWidth: nil,
            maxWidth: .infinity,
            minHeight: 0,
            idealHeight: nil,
            maxHeight: .infinity,
            alignment: .top
        )
            .allowsHitTesting(false)
            .edgesIgnoringSafeArea(.top)
    }

}

struct StatusBarMask_Previews: PreviewProvider {
    static var previews: some View {
        StatusBarMask()
    }
}
