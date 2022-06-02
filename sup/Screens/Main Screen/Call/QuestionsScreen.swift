//
//  QuestionsScreen.swift
//  sup
//
//  Created by Justin Spraggins on 7/15/20.
//  Copyright © 2020 Episode 8, Inc. All rights reserved.
//

import SwiftUI

struct QuestionsScreen: View {
    @ObservedObject var state: AppState
    @State var questions = [Question]()
    @State var index = 0
    @State var questionAlert = false
    @State var newQuestions = true

    private func getQuestions() {
        Question.all { questions in
            self.questions = questions
        }
    }

    private func addQuestionListener() {
        Question.listener { question in
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                self.questions.append(question)
            }
        }
    }

    private func nextQuestion() {
        impact(style: .soft)
        SupUserDefaults.timesQuestionHintShown = SupUserDefaults.timesQuestionHintShown + 1
        if self.questions.count > index + 1 {
            index += 1
        } else {
            index = 0
        }
    }

    private func showQuestionsCard() {
        impact(style: .soft)
        self.state.browseQuestions.toggle()

//        if self.state.browseQuestions {
//            self.state.browseQuestions = false
//        } else {
//            self.state.showQuestionsCard = true
//            self.getQuestions()
//            self.newQuestions = false
//        }
    }

    private var showDot: Bool {
        SupUserDefaults.timesNewQuestionShown ==  0 && self.newQuestions
    }

    private var showQuestionHint: Bool {
        SupUserDefaults.timesQuestionHintShown == 0 && questions.count > index && self.state.browseQuestions
    }

    private func showHappyHourCard() {
        impact(style: .soft)
        self.state.showHappyHourCard = true
    }

    var body: some View {
        ZStack {
            VStack {
                Spacer()
                HStack {
                    if self.state.isConnect {
                        ZStack {
                            Button(action: { self.showQuestionsCard() }) {
                                ZStack {
                                    Circle()
                                        .foregroundColor(self.state.browseQuestions ? Color.white : Color.white.opacity(0.1))
                                        .frame(width: 54, height: 54)
                                    Image("question-icon")
                                        .renderingMode(.template)
                                        .foregroundColor(self.state.browseQuestions ? Color.black : Color.white)
                                }
                            }
                            .buttonStyle(ButtonBounceHeavy())
                            .alert(isPresented: self.$questionAlert) {
                                Alert(title: Text("HOW THIS WORKS"),
                                      message: Text("\n@2pm PST every day a new set of questions are released. \n\nStart a call with a guest and you'll be able to see these questions for you to ask your friend while recording a sup."),
                                      dismissButton: .default(Text("got it!")) {
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                            SupUserDefaults.timesQuestionAlertShown = SupUserDefaults.timesQuestionAlertShown + 1
                                            self.state.browseQuestions.toggle()
                                            self.getQuestions()
                                        }
                                    }
                                )
                            }

                            if showDot {
                                Circle()
                                    .frame(width: 14, height: 14)
                                    .foregroundColor(Color.redColor)
                                    .shadow(color: Color.black.opacity(0.4), radius: 5, x: 0, y: 0)
                                    .padding(.bottom, 20)
                                    .padding(.leading, 24)
                                    .transition(AnyTransition.scale.combined(with: .opacity))
                                    .animation(.easeInOut(duration: 0.3))
                                    .animation(.spring())
                            }
                        }
                        .onAppear() {
                            self.getQuestions()
                            self.newQuestions = false
                        }
                    }

                    Spacer()

//                    if !self.state.isConnect && !self.state.isConnectHappyHour {
//                        Button(action: { self.showHappyHourCard() }) {
//                            ZStack {
//                                Circle()
//                                    .foregroundColor(Color.white.opacity(0.0001))
//                                    .frame(width: 54, height: 54)
//                                Image("dice-icon")
//                                    .renderingMode(.template)
//                                    .foregroundColor(Color.white)
//                            }
//                        }
//                        .buttonStyle(ButtonBounceHeavy())
//                    }

                }
                .padding(.horizontal, 22)
                Spacer().frame(height: isIPhoneX ? 45 : 20)
            }

            if questions.count > index && self.state.browseQuestions {
                FeaturedQuestions(question: questions[index],
                                  action: { self.nextQuestion() })

                    .transition(AnyTransition.opacity.combined(with: .scale(scale: 0.5)))
            }

            if showQuestionHint {
                  VStack {
                      Image("hint-question")
                          .shadow(color: Color.black.opacity(0.4), radius: 20, x: 0, y: 0)
                    Spacer().frame(height: 210)
                  }
                  .transition(AnyTransition.opacity.combined(with: .scale(scale: 0.9)))
              }
        }
        .frame(width: screenWidth, height: screenHeight)
        .transition(.opacity)
        .animation(.easeInOut(duration: 0.3))
        .onAppear {
            self.getQuestions()
            self.addQuestionListener()
        }
    }
}
