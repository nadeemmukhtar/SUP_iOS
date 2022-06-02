//
//  PlaygroundView.swift
//  sup
//
//  Created by Robert Malko on 5/16/20.
//  Copyright © 2020 Episode 8, Inc. All rights reserved.
//

// PlaygroundView is a file to be used when testing out views in isolation

import SwiftUI

struct PlaygroundView: View {
    @ObservedObject var state: AppState

    var body: some View {
        return ZStack {
            BackgroundColorView(color: Color.black)
            ZStack {
                Color.red
            }
            .frame(width: screenWidth, height: screenHeight)
        }
    }
}

struct PlaygroundView_Previews: PreviewProvider {
    static var previews: some View {
        let state = AppState()
        return PlaygroundView(state: state)
    }
}

private func viewWith(backgroundColor: UIColor) -> UIView {
    let view = UIView()
    view.backgroundColor = backgroundColor

    return view
}
