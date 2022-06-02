//
//  BackgroundColorView.swift
//  sayit
//
//  Created by Robert Malko on 12/15/19.
//  Copyright © 2019 Extra Visual. All rights reserved.
//

import SwiftUI

struct BackgroundColorView: View {
    let color: Color

    var body: some View {
        color.edgesIgnoringSafeArea(.all)
    }
}
