//
//  ProfileHeader.swift
//  sup
//
//  Created by Justin Spraggins on 5/22/20.
//  Copyright © 2020 Episode 8, Inc. All rights reserved.
//

import SwiftUI
import SDWebImageSwiftUI

struct ProfileHeader: View {
    @ObservedObject var state: AppState
    var username: String?
    var tapCoins: (() -> Void)? = nil
    var tapAction: (() -> Void)? = nil

    private func showPhotoLibrary() {
        impact(style: .soft)
        self.state.photosPermissions { allowed in
            if allowed {
                self.state.showPhotoLibrary = true
                self.state.hideNav = true
                self.state.hideProfile = true
                self.state.showMediaPlayerDrawer = false
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                        self.state.animatePhotoLibrary = true
                }
            } else {
                self.state.promptForPhotoPermissions()
            }
        }
    }

    var body: some View {
        HStack (spacing: 25) {
            state.coverPhoto
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 148, height: 148)
                .cornerRadius(28)

            Spacer()
            VStack (spacing: 4) {
                Button(action: { self.showPhotoLibrary() }) {
                    ZStack {
                        Circle()
                            .foregroundColor(Color.cellBackground)
                            .frame(width: 92, height: 92)
                        Image("profile-photo")
                            .renderingMode(.template)
                            .foregroundColor(Color.primaryTextColor)
                    }
                }
                .buttonStyle(ButtonBounce())

               Text("change cover")
                .modifier(TextModifier(size: 17, font: Font.textaAltBold, color: Color.secondaryTextColor))
            }
            .frame(height: 148)
            Spacer()
        }
        .frame(width: screenWidth - 38)
    }
    
    func coins() -> String {
        return formatCoins(value: self.state.currentUser?.coins.toString ?? "100")
    }

    func formatCoins(value: String) -> String {
        let num = Double(value)!
        let thousandNum = num/1000
        let millionNum = num/1000000
        let billionNum = num/1000000000
        if num >= 1000 && num < 1000000{
            if(floor(thousandNum) == thousandNum){
                return("\(Int(thousandNum))k")
            }
            return("\(self.roundToPlaces(value: thousandNum, places: 1))k")
        }
        if num > 1000000 && num < 1000000000{
            if(floor(millionNum) == millionNum){
                return("\(Int(thousandNum))k")
            }
            return ("\(self.roundToPlaces(value: millionNum, places: 1))M")
        }
            if num > 1000000000{
                if(floor(billionNum) == billionNum){
                    return("\(Int(thousandNum))k")
                }
                return ("\(self.roundToPlaces(value: billionNum, places: 1))B")
            }
        else{
            if(floor(num) == num){
                return ("\(Int(num))")
            }
            return ("\(num)")
        }
    }

    func roundToPlaces(value:Double, places:Int) -> Double {
        let divisor = pow(10.0, Double(places))
        return round(value * divisor) / divisor
    }
}

extension Int {
    
    var toString: String {
        String(self)
    }
}
