//
//  Label.swift
//  sup
//
//  Created by Appcrates_Dev on 6/2/20.
//  Copyright © 2020 Episode 8, Inc. All rights reserved.
//

import SwiftUI
import Atributika

struct Label: UIViewRepresentable {
    
    let text: String
    
    func makeUIView(context: UIViewRepresentableContext<Self>) -> AttributedLabel {
        let tweetLabel = AttributedLabel()
        
        tweetLabel.numberOfLines = 0

        let all = Style.font(UIFont(name: Font.textaBold, size: 19)!)
            .foregroundColor(UIColor(named: "secondaryTextColor")!, .normal)
        let link = Style.font(UIFont(name: Font.textaAltBlack, size: 19)!)
            .foregroundColor(UIColor(named: "primaryTextColor")!, .highlighted)

        tweetLabel.attributedText = text
            .style(tags: link)
            .styleMentions(link)
            .styleAll(all)

        tweetLabel.onClick = { label, detection in
                    switch detection.type {
                    case .hashtag(let tag):
                        if let url = URL(string: "https://twitter.com/hashtag/\(tag)") {
                            UIApplication.shared.open(url, options: [:], completionHandler: nil)
                        }
                    case .mention(let name):
                        if let url = URL(string: "https://twitter.com/\(name)") {
                            UIApplication.shared.open(url, options: [:], completionHandler: nil)
                        }
                    case .link(let url):
                        UIApplication.shared.open(url, options: [:], completionHandler: nil)
                    case .tag(let tag):
                        if tag.name == "a", let href = tag.attributes["href"], let url = URL(string: href) {
                           UIApplication.shared.open(url, options: [:], completionHandler: nil)
                        }
                    default:
                        break
                    }
                }

        return tweetLabel
    }
    
    func updateUIView(_ label: AttributedLabel, context: UIViewRepresentableContext<Self>) {
        
    }
}

struct ALabel: UIViewRepresentable {
    
    let text: String
    let myLabel = UILabel()
    
    func makeUIView(context: UIViewRepresentableContext<Self>) -> UILabel {
        
        
        myLabel.text = "By signing up you agree to our Terms & Conditions and Privacy Policy"
        let text = (myLabel.text)!
        let underlineAttriString = NSMutableAttributedString(string: text)
        let range1 = (text as NSString).range(of: "Terms & Conditions")
        underlineAttriString.addAttribute(NSAttributedString.Key.underlineStyle, value: NSUnderlineStyle.single.rawValue, range: range1)
        let range2 = (text as NSString).range(of: "Privacy Policy")
        underlineAttriString.addAttribute(NSAttributedString.Key.underlineStyle, value: NSUnderlineStyle.single.rawValue, range: range2)
        myLabel.attributedText = underlineAttriString

        return myLabel
    }
    
    func updateUIView(_ label: UILabel, context: UIViewRepresentableContext<Self>) {
        
    }
    
    func tapLabel(gesture: UITapGestureRecognizer) {
        let text = (myLabel.text)!
        let termsRange = (text as NSString).range(of: "Terms & Conditions")
        let privacyRange = (text as NSString).range(of: "Privacy Policy")

        if gesture.didTapAttributedTextInLabel(label: myLabel, inRange: termsRange) {
            print("Tapped terms")
        } else if gesture.didTapAttributedTextInLabel(label: myLabel, inRange: privacyRange) {
            print("Tapped privacy")
        } else {
            print("Tapped none")
        }
    }
}

extension UITapGestureRecognizer {

    func didTapAttributedTextInLabel(label: UILabel, inRange targetRange: NSRange) -> Bool {
        // Create instances of NSLayoutManager, NSTextContainer and NSTextStorage
        let layoutManager = NSLayoutManager()
        let textContainer = NSTextContainer(size: CGSize.zero)
        let textStorage = NSTextStorage(attributedString: label.attributedText!)

        // Configure layoutManager and textStorage
        layoutManager.addTextContainer(textContainer)
        textStorage.addLayoutManager(layoutManager)

        // Configure textContainer
        textContainer.lineFragmentPadding = 0.0
        textContainer.lineBreakMode = label.lineBreakMode
        textContainer.maximumNumberOfLines = label.numberOfLines
        let labelSize = label.bounds.size
        textContainer.size = labelSize

        // Find the tapped character location and compare it to the specified range
        let locationOfTouchInLabel = self.location(in: label)
        let textBoundingBox = layoutManager.usedRect(for: textContainer)
        let textContainerOffset = CGPoint(x: (labelSize.width - textBoundingBox.size.width) * 0.5 - textBoundingBox.origin.x, y: (labelSize.height - textBoundingBox.size.height) * 0.5 - textBoundingBox.origin.y)
        let locationOfTouchInTextContainer = CGPoint(x: locationOfTouchInLabel.x - textContainerOffset.x, y: locationOfTouchInLabel.y - textContainerOffset.y)
        let indexOfCharacter = layoutManager.characterIndex(for: locationOfTouchInTextContainer, in: textContainer, fractionOfDistanceBetweenInsertionPoints: nil)

        return NSLocationInRange(indexOfCharacter, targetRange)
    }

}
