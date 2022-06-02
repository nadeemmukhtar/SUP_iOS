//
//  Style.swift
//  sup
//
//  Created by Justin Spraggins on 12/16/19.
//  Copyright © 2019 Episode 8, Inc. All rights reserved.
//
import SwiftUI
import SDWebImageSwiftUI

extension Color {
    static let yellowBaseColor = Color("yellowBaseColor")
    static let yellowAccentColor = Color("yellowAccentColor")
    static let yellowDarkColor = Color("yellowDarkColor")

    static let redColor = Color("redColor")
    static let redBorder = Color("redBorder")
    static let redDark = Color("redDark")

    static let greenAccentColor = Color("greenAccentColor")
    static let greenBaseColor = Color("greenBaseColor")
    static let greenDarkColor = Color("greenDarkColor")

    static let purpleBaseColor = Color("purpleBaseColor")
    static let purpleAccentColor = Color("purpleAccentColor")
    static let purpleDarkColor = Color("purpleDarkColor")

    static let aquaBaseColor = Color("aquaBaseColor")
    static let aquaAccentColor = Color("aquaAccentColor")
    static let aquaDarkColor = Color("aquaDarkColor")

    static let blueInviteColor = Color("blueInviteColor")
    static let blueBaseColor = Color("blueBaseColor")
    static let blueDarkColor = Color("blueDarkColor")
    static let blueAccentColor = Color("blueAccentColor")

    static let snapchatYellow = Color("snapchatYellow")
    static let snapchatDarkColor = Color("snapchatDarkColor")
    static let snapchatBaseColor = Color("snapchatBaseColor")
    static let settingsBackground = Color("settingsBackground")

    static let greyButton = Color("greyButton")
    static let whiteBorder = Color("whiteBorder")

    static let mediaPlayerColor = Color("mediaPlayerColor")
    static let mediaPlayerText = Color("mediaPlayerText")
    static let cellSecondaryColor = Color("cellSecondaryColor")

    static let alertCardGrey = Color("alertCardGrey")
    static let feedBackground = Color("feedBackground")
    static let micBackground = Color("micBackground")
    static let lightBackground = Color("lightBackground")
    static let backgroundColor = Color("backgroundColor")
    static let cellBackground = Color("cellBackground")
    static let cardBackground = Color("cardBackground")
    static let cardCellBackground = Color("cardCellBackground")
    static let playingColor = Color("playingColor")
    static let shadowColor = Color("shadowColor")

    static let primaryTextColor = Color("primaryTextColor")
    static let secondaryTextColor = Color("secondaryTextColor")
    static let greyBorder = Color("greyBorder")

}

extension Font {
    static let textaAltBlack = "TextaAlt-Black"
    static let textaAltBold = "TextaAlt-Bold"
    static let textaAltHeavy = "TextaAlt-Heavy"
    static let textaHeavy = "Texta-Heavy"
    static let textaBold = "Texta-Bold"
    static let ttNormsBold = "TTNorms-ExtraBold"
}

func haptic(type: UINotificationFeedbackGenerator.FeedbackType) {
    UINotificationFeedbackGenerator().notificationOccurred(type)
}

func impact(style: UIImpactFeedbackGenerator.FeedbackStyle) {
    UIImpactFeedbackGenerator(style: style).impactOccurred()
}

struct ButtonBounce: ButtonStyle {
    func makeBody(configuration: Self.Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.9 : 1.0)
    }
}

struct ButtonBounceLight: ButtonStyle {
    func makeBody(configuration: Self.Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.99 : 1.0)
    }
}

struct ButtonBounceNone: ButtonStyle {
    func makeBody(configuration: Self.Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 1.0 : 1.0)
    }
}

struct ButtonBounceHeavy: ButtonStyle {
    func makeBody(configuration: Self.Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.8 : 1.0)
    }
}

struct ImageButton: View {
    var image: String
    var width: CGFloat = 40
    var height: CGFloat = 40
    var corner: CGFloat = 12
    var background = Color.clear
    var blur: Bool = false
    var action: () -> Void

    var body: some View {
        Button(action: {
            impact(style: .soft)
            self.action()
        }) {
            ZStack {
                if self.blur {
                    ZStack {
                        BackgroundBlurView(style: .systemThinMaterial)
                            .frame(width: width, height: height, alignment: .center)
                            .clipShape(Circle())
                        Rectangle()
                            .foregroundColor(background)
                            .frame(width: width, height: height, alignment: .center)
                            .clipShape(RoundedRectangle(cornerRadius: corner, style: .continuous))
                    }

                } else {
                    Rectangle()
                        .foregroundColor(background)
                        .frame(width: width, height: height, alignment: .center)
                        .clipShape(RoundedRectangle(cornerRadius: corner, style: .continuous))
                }

                Image(image)
                    .renderingMode(.original)
                    .animation(nil)
            }
        }
        .buttonStyle(ButtonBounce())
    }
}

struct SocialShareButton: View {
    var image: String
    var color = Color.cellBackground
    var action: () -> Void

    var body: some View {
        Button(action: {
            impact(style: .soft)
            self.action()
        }) {
            ZStack {
                Circle()
                    .foregroundColor(color)
                    .frame(width: 64, height: 64)
                Image(image)
                    .renderingMode(.original)
            }
        }
        .buttonStyle(ButtonBounce())
    }
}

struct CallShareButton: View {
    var image: String
    var color = Color.clear
    var blur: Bool = false
    var action: () -> Void

    var body: some View {
        Button(action: {
            impact(style: .soft)
            self.action()
        }) {
            ZStack {
                if self.blur {
                    BackgroundBlurView(style: .systemUltraThinMaterialDark)
                        .frame(width: 56, height: 56, alignment: .center)
                        .clipShape(Circle())
                } else {
                    Circle()
                        .foregroundColor(color)
                        .frame(width: 56, height: 56)
                }
                Image(image)
                    .renderingMode(.original)
                    .frame(width: 56, height: 56)
            }
        }
        .buttonStyle(ButtonBounce())
    }
}

struct GreyTextButton: View {
    var text: String
    var action: () -> Void

    var body: some View {
        Button(action: {
            impact(style: .soft)
            self.action()
        }) {
            ZStack {
                Capsule()
                    .foregroundColor(Color.greyButton)
                    .frame(width: 142, height: 46)
                Text(text)
                    .modifier(TextModifier(size: 20, color: Color.black))
            }
        }
        .buttonStyle(ButtonBounce())
    }
}

struct TintImageButton: View {
    var image: String
    var width: CGFloat = 40
    var height: CGFloat = 40
    var corner: CGFloat = 20
    var background = Color.cellBackground.opacity(0.8)
    var tint = Color.primaryTextColor
    var blur: Bool = false
    var action: () -> Void

    var body: some View {
        Button(action: {
            impact(style: .soft)
            self.action()
        }) {
            ZStack {
                if self.blur {
                    ZStack {
                        BackgroundBlurView(style: .systemMaterialDark)
                            .frame(width: width, height: height, alignment: .center)
                            .clipShape(RoundedRectangle(cornerRadius: corner, style: .continuous))
                        Rectangle()
                            .foregroundColor(background)
                            .frame(width: width, height: height, alignment: .center)
                            .clipShape(RoundedRectangle(cornerRadius: corner, style: .continuous))
                    }

                } else {
                    Rectangle()
                        .foregroundColor(background)
                        .frame(width: width, height: height, alignment: .center)
                        .clipShape(RoundedRectangle(cornerRadius: corner, style: .continuous))
                }

                Image(image)
                    .renderingMode(.template)
                    .foregroundColor(tint)
                    .animation(nil)
            }
        }
        .buttonStyle(ButtonBounce())
    }
}

struct MediaPlayerButton: View {
    var image: String
    var width: CGFloat = 48
    var height: CGFloat = 48
    var corner: CGFloat = 0
    var action: () -> Void

    var body: some View {
        Button(action: {
            impact(style: .soft)
            self.action()
        }) {
            ZStack {
                Spacer().frame(width: width, height: height)
                Color.black.opacity(0.00001)
                    .frame(width: width, height: height)
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                Image(image)
                    .renderingMode(.template)
                    .foregroundColor(Color.white.opacity(0.1))
                    .animation(nil)
                Image(image)
                    .renderingMode(.template)
                    .foregroundColor(.white)
                    .animation(nil)
                    .blendMode(.overlay)
            }
        }
        .buttonStyle(ButtonBounce())
    }
}

struct AvatarButton: View {
    var image: Image
    var avatarWebImage: WebImage?
    var size: CGFloat = 50
    var action: () -> Void

    var body: some View {
        Button(action: {
            impact(style: .soft)
            self.action()
        }) {
            ZStack {
                if avatarWebImage != nil {
                    avatarWebImage!
                        .renderingMode(.original)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .background(Color.backgroundColor)
                        .frame(width: size, height: size)
                        .clipShape(Circle())
                } else {
                    image
                        .renderingMode(.original)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .background(Color.backgroundColor)
                        .frame(width: size, height: size)
                        .clipShape(Circle())
                }
            }
        }
        .buttonStyle(ButtonBounce())
    }
}

struct ShareCardButton: View {
    var image: String
    var width: CGFloat = 70
    var height: CGFloat = 70
    var corner: CGFloat = 35
    var tint = Color.white
    var action: () -> Void

    var body: some View {
        Button(action: {
            impact(style: .soft)
            self.action()
        }) {
            ZStack {
                Color.black.opacity(0.3)
                    .frame(width: width, height: height, alignment: .center)
                    .clipShape(Circle())
                Image(image)
                    .renderingMode(.template)
                    .foregroundColor(tint)
            }
        }
        .buttonStyle(ButtonBounceLight())
    }
}

struct TextButton: View {
    var title: String
    var color = Color.cellBackground
    var textColor = Color.primaryTextColor
    var textSize: CGFloat = 20
    var width: CGFloat = 168
    var height: CGFloat = 54
    var action: () -> Void

    var body: some View {
        Button(action: {
            impact(style: .soft)
            self.action()
        }) {
            ZStack {
                self.color
                    .frame(width: width, height: height)
                    .clipShape(RoundedRectangle(cornerRadius: height * 0.42, style: .continuous))

                Text(self.title)
                    .modifier(TextModifier(size: textSize, color: textColor))
            }
        }
        .buttonStyle(ButtonBounceLight())
    }
}

struct TextImageButton: View {
    var title: String
    var image: String = ""
    var color = Color.cellBackground
    var textColor = Color.primaryTextColor
    var textSize: CGFloat = 20
    var blur: Bool = false
    var tint: Bool = true
    var width: CGFloat = screenWidth - 30
    var action: () -> Void

    var body: some View {
        Button(action: {
            impact(style: .soft)
            self.action()
        }) {

            ZStack {
                if self.blur {
                    BackgroundBlurView(style: .systemThinMaterialDark)
                        .frame(width: width, height: 66, alignment: .center)
                        .clipShape(RoundedRectangle(cornerRadius: 33, style: .continuous))
                } else {
                    self.color
                        .frame(width: width, height: 66)
                        .clipShape(RoundedRectangle(cornerRadius: 32, style: .continuous))
                }
                HStack(spacing: 18) {
                    Text(self.title)
                        .font(Font.custom(Font.textaAltHeavy, size: textSize))
                        .foregroundColor(self.textColor)
                    Spacer()
                    Image(self.image)
                        .renderingMode(tint ? .template : .original)
                        .foregroundColor(self.textColor)
                        .frame(width: 34, height: 34)
                }
                .padding(.trailing, 20)
                .padding(.leading, 25)
                .frame(width: width, height: 66, alignment: .center)
            }
        }
        .frame(width: width, height: 66)
        .buttonStyle(ButtonBounceLight())
    }
}

struct YellowTextButton: View {
    var title: String
    var textSize: CGFloat = 21
    var width: CGFloat = 168
    var height: CGFloat = 58
    var action: () -> Void

    var body: some View {
        Button(action: {
            impact(style: .soft)
            self.action()
        }) {
            Text(self.title)
                .modifier(TextModifier(size: textSize, color: Color.backgroundColor))
                .frame(width: 168)
                .background(
                    RoundedRectangle(cornerRadius: 25)
                        .foregroundColor(Color.yellowAccentColor)
                        .frame(width: width, height: 58)
                        .shadow(color: Color.black.opacity(0.1), radius: 20, x: 0, y: 0)
            )
        }
        .buttonStyle(ButtonBounceLight())
    }
}

struct WhiteImageButton: View {
    var title: String
    var image: String = ""
    var width: CGFloat = 180
    var padding: CGFloat = 1
    var action: () -> Void

    var body: some View {
        Button(action: {
            impact(style: .soft)
            self.action()
        }) {
            ZStack {
                Capsule()
                    .foregroundColor(Color.white)
                    .frame(width: width, height: 54)

                HStack (spacing: 12) {
                    Image(self.image)
                        .padding(.bottom, padding)
                    Text(self.title)
                        .modifier(TextModifier(size: 22, color: Color.black))
                        .padding(.bottom, 2)
                        .frame(width: 60)
                }
            }
        }
        .buttonStyle(ButtonBounceLight())
    }
}

struct DarkImageButton: View {
    var title: String
    var image: String = ""
    var width: CGFloat = 158
    var padding: CGFloat = 2
    var action: () -> Void

    var body: some View {
        Button(action: {
            impact(style: .soft)
            self.action()
        }) {
            ZStack {
                RoundedRectangle(cornerRadius: 25)
                    .foregroundColor(Color.blueAccentColor)
                    .frame(width: width, height: 58)

                HStack (spacing: 12) {
                    Text(self.title)
                        .modifier(TextModifier(size: 22, color: Color.primaryTextColor))
                        .padding(.bottom, 2)
                    Image(self.image)
                    .padding(.bottom, padding)
                }
            }
        }
        .buttonStyle(ButtonBounceLight())
    }
}

struct PurpleButton: View {
    var title: String
    var image: String = ""
    var width: CGFloat = screenWidth - 30
    var action: () -> Void

    var body: some View {
        Button(action: {
            impact(style: .soft)
            self.action()
        }) {
            ZStack {
                RoundedRectangle(cornerRadius: 29)
                    .foregroundColor(Color.purpleAccentColor)
                    .frame(width: width, height: 66)
                    .shadow(color: Color.purpleAccentColor.opacity(0.2), radius: 10, x: 0, y: 1)
                HStack(spacing: 18) {
                    Spacer()
                    Text(self.title)
                        .modifier(TextModifier(size: 22, font: Font.textaAltBlack, color: Color.white))
                    Spacer()
                    Image(self.image)
                        .renderingMode(.template)
                        .foregroundColor(Color.white)
                        .frame(width: 34, height: 34)
                }
                .padding(.trailing, 20)
                .frame(width: width, height: 66, alignment: .center)
            }
        }
        .frame(width: width, height: 66)
        .buttonStyle(ButtonBounceLight())
    }
}

struct CardHeader: ViewModifier {
    var text: String
    var textColor = Color.primaryTextColor
    var size: CGFloat = screenHeight - 60
    var onClose: (() -> Void)? = nil

    func body(content: Content) -> some View {
        ZStack() {
            content
            VStack {
                HStack {
                    Spacer().frame(width: 40)
                    Spacer()
                    Text(text)
                        .font(Font.custom(Font.textaAltBlack, size: 22))
                        .foregroundColor(textColor)
                        .frame(height: 80)
                        .animation(nil)
                    Spacer()
                    Button(action: {
                        impact(style: .soft)
                        self.onClose?()
                    }) {
                        Image("nav-close")
                            .renderingMode(.template)
                            .foregroundColor(Color.primaryTextColor)
                            .frame(width: 40, height: 40)
                    }
                    .buttonStyle(ButtonBounce())
                }
                .padding(.horizontal, 20)

                Spacer()
            }
            .frame(width: screenWidth, height: size)
            .onTapGesture { self.onClose?() }
        }
    }
}

struct CardBackground: ViewModifier {
    var size: CGFloat = screenHeight - 60
    var background = Color.cellBackground

    func body(content: Content) -> some View {
        content
            .background(background)
            .frame(width: screenWidth, height: size)
            .clipShape(RoundedRectangle(cornerRadius: 38, style: .continuous))
    }
}

struct TextModifier: ViewModifier {
    var size: CGFloat = 18
    var font: String = Font.textaAltHeavy
    var color: Color = Color.primaryTextColor

    func body(content: Content) -> some View {
        content
            .font(Font.custom(font, size: size))
            .foregroundColor(color)
    }
}

struct ImageModifier: ViewModifier {
    var size: CGFloat
    var color: Color = Color.cellBackground
    var corner: CGFloat = 0

    func body(content: Content) -> some View {
        content
            .frame(width: size, height: size)
            .background(color)
            .clipShape(RoundedRectangle(cornerRadius: corner, style: .continuous))
    }
}

struct DoneButton: View {
    var text: String = "done"
    var backgroundColor: Color = Color.cellBackground
    var action: (() -> Void)? = nil

    var body: some View {
        TextButton(title: text,
                   color: backgroundColor,
                   textColor: Color.white.opacity(0.8),
                   width: 100,
                   height: 40,
                   action: {
                    self.action?()

        })
            .padding(.top, 20)
            .padding(.bottom, 65)
    }
}

struct ListButton: View {
    var text: String
    var backgroundColor: Color
    var textColor: Color
    var action: () -> Void

    init(text: String, backgroundColor: Color = Color.cardCellBackground, textColor: Color = Color.primaryTextColor, action: @escaping () -> Void) {
        self.text = text
        self.backgroundColor = backgroundColor
        self.textColor = textColor
        self.action = action
    }

    var body: some View {
        Button(action: {
            impact(style: .medium)
            self.action()
        }) {
            HStack {
                Text(self.text)
                    .modifier(TextModifier(size: 20, color: textColor))
                    .padding(.bottom, 2)
                Spacer()
            }
            .padding(.leading, 20)
            .frame(width: screenWidth - 30, height: 80)
            .background(backgroundColor.clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous)))
        }
        .buttonStyle(ButtonBounceLight())
    }
}

struct CornerRadiusStyle: ViewModifier {
    var radius: CGFloat
    var corners: UIRectCorner

    struct CornerRadiusShape: Shape {

        var radius = CGFloat.infinity
        var corners = UIRectCorner.allCorners

        func path(in rect: CGRect) -> Path {
            let path = UIBezierPath(roundedRect: rect, byRoundingCorners: corners, cornerRadii: CGSize(width: radius, height: radius))
            return Path(path.cgPath)
        }
    }

    func body(content: Content) -> some View {
        content
            .clipShape(CornerRadiusShape(radius: radius, corners: corners))
    }
}

extension View {
    func cornerRadius(radius: CGFloat, corners: UIRectCorner) -> some View {
        ModifiedContent(content: self, modifier: CornerRadiusStyle(radius: radius, corners: corners))
    }
}
