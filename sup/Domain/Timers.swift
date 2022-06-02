//
//  Timers.swift
//  sup
//
//  Created by Robert Malko on 6/1/20.
//  Copyright © 2020 Episode 8, Inc. All rights reserved.
//

import Foundation

struct Timers {
    static func startCountdown(state: AppState, callback: (() -> Void)? = nil) {
        state.count3 = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            state.count3 = false
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                state.count2 = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                    state.count2 = false
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                        state.count1 = true
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                            state.count1 = false
                            callback?()
                        }
                    }
                }
            }
        }
    }
}
