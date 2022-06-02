//
//  CardNavigation.swift
//  sup
//
//  Created by Justin Spraggins on 7/8/20.
//  Copyright © 2020 Episode 8, Inc. All rights reserved.
//

import SwiftUI

struct CardNavigation: View {
    @ObservedObject var state: AppState

    private func closeCallEndedCard() {
        impact(style: .soft)
        self.state.showCallEnded = false
    }

    private func closeCoinsCard() {
        impact(style: .soft)
        self.state.showCoinsCard = false
    }

    private func closeFollowingCard() {
        impact(style: .soft)
        self.state.showFollowingCard = false
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            self.state.showMediaPlayerDrawer = true
        }
    }

    private func closeHappyHourCard() {
        impact(style: .soft)
        self.state.showHappyHourCard = false
    }

    private func closeInviteGuests() {
        impact(style: .soft)
        self.state.showInviteGuest = false
    }

    private func closeRateCard() {
        impact(style: .soft)
        self.state.showRateCard = false
    }


    private func closeSettingsCard() {
        impact(style: .soft)
        self.state.showSettingsCard = false
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            self.state.showMediaPlayerDrawer = true
            self.state.audioPlayer.stopPlayback()
        }
    }

    private func showQuestions() {
        self.closeQuestionsCard()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            self.state.browseQuestions.toggle()
        }
    }

    private func closeQuestionsCard() {
        impact(style: .soft)
        self.state.showQuestionsCard = false
    }

    private func refreshBitmoji() {
        self.state.getSnapchatInfo {
            DispatchQueue.global(qos: .background).async {
                if let name = self.state.snapchatDisplayName {
                    User.update(userID: self.state.currentUser?.uid, data: [
                        "displayName": name
                    ])
                    let currentUser = self.state.currentUser
                    currentUser?.displayName = name

                    DispatchQueue.main.async {
                        self.state.currentUser = currentUser
                        self.closeSettingsCard()
                    }
                }
            }
            self.state.uploadImage()
        }
    }

    private func closeShareCard() {
        impact(style: .soft)
        self.state.showShareCard = false
    }

    private func showUserProfile() {
        impact(style: .soft)
        if self.state.showFollowingCard {
            self.state.showFollowingCard = false
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3){
                self.state.showUserProfile = true
            }
        } else {
            self.state.audioPlayer.pausePlayback()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1){
                self.closeShareCard()
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3){
                    self.state.showUserProfile = true
                }
            }
        }
    }

    private func closeUserProfile() {
        impact(style: .soft)
        self.state.showUserProfile = false
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3){
            self.state.showMediaPlayerDrawer = true
        }
    }

    private var showCard: Bool {
        self.state.showCallEnded ||
        self.state.showCoinsCard ||
        self.state.showFollowingCard ||
        self.state.showHappyHourCard ||
        self.state.showInviteGuest ||
        self.state.showPublishSocials ||
        self.state.showQuestionsCard ||
        self.state.showRateCard ||
        self.state.showSettingsCard ||
        self.state.showShareCard ||
        self.state.showSnapchatCard ||
        self.state.showUserProfile
    }

    private func closeCard() {
        if self.state.showCallEnded {
            self.closeCallEndedCard()
        } else if self.state.showCoinsCard {
            self.closeCoinsCard()
        } else if self.state.showFollowingCard {
            self.closeFollowingCard()
        } else if self.state.showHappyHourCard {
            self.closeHappyHourCard()
        } else if self.state.showInviteGuest {
            self.closeInviteGuests()
        } else if self.state.showPublishSocials {
            //
        } else if self.state.showQuestionsCard {
            self.closeQuestionsCard()
        } else if self.state.showRateCard {
            self.closeRateCard()
        } else if self.state.showSettingsCard {
            self.closeSettingsCard()
        } else if self.state.showShareCard {
            self.closeShareCard()
        } else if self.state.showUserProfile {
            self.closeUserProfile()
        }
    }

    var body: some View {
        ZStack {
            BackgroundColorView(color: Color.black)
                .opacity(showCard ? 0.3 : 0)
                .animation(.easeInOut(duration: 0.3))
                .onTapGesture { self.closeCard() }

            Group {
                if self.state.showCallEnded && self.state.hostname != nil {
                    CallEndedCard(
                        state: state,
                        hostname: self.state.hostname!,
                        hostAvatar: self.state.hostAvatar,
                        guestAvatars: self.state.guestAvatars,
                        onClose: { self.closeCallEndedCard() }
                    )
                }

                if self.state.showCoinsCard {
                    CoinsCard(state: state,
                              onClose: { self.closeCoinsCard() })
                }

                if self.state.showFollowingCard {
                    FollowingCard(state: state,
                                  friends: state.friends,
                                  onClose: { self.closeFollowingCard() },
                                  showUserProfile: { self.showUserProfile() })
                }

                if self.state.showHappyHourCard {
                    HappyHourCard(state: state,
                                  onClose: { self.closeHappyHourCard() })
                }

                if self.state.happyHourHost {
                    HappyHourHostCard()
                }

                if self.state.showInviteGuest {
                    InviteGuestCard(state: state,
                                onClose: { self.closeInviteGuests() })
                }
            }


            if self.state.showPublishSocials && state.publishedSup != nil {
                PublishSocialCard(state: state, publishedSup: state.publishedSup!)
                    .environmentObject(self.state.audioPlayer)
            }

            if self.state.showQuestionsCard {
                QuestionCategoryCard(onClose: { self.closeQuestionsCard() },
                                     onSelect: { self.showQuestions() })
            }

            Group {
                if self.state.showRateCard {
                    RateUsCard(state: state,
                               onClose: { self.closeRateCard() })
                }

                if self.state.showSettingsCard {
                    SettingsCard(
                        state: state,
                        refreshBitmoji: { self.refreshBitmoji() },
                        onClose: { self.closeSettingsCard() },
                        onComplete: { self.closeSettingsCard()}
                    )
                }

                if self.state.showShareCard && self.state.selectedSup != nil {
                    ShareCard(
                        state: self.state,
                        sup: state.selectedSup!,
                        image: (state.selectedSup?.avatarUrl)!,
                        username: (state.selectedSup?.username)!,
                        onClose: { self.closeShareCard() },
                        showUserProfile: { self.showUserProfile() })
                }

                if self.state.showSnapchatCard {
                    SnapchatCard()
                }

                if self.state.showUserProfile {
                    UserProfileCard(
                        state: state,
                        onClose: { self.closeUserProfile() }
                    )
                        .environmentObject(state.audioPlayer)
                }
            }
        }
    }
}
