//
//  MessageComposeView.swift
//  sup
//
//  Created by Robert Malko on 4/25/20.
//  Copyright © 2020 Episode 8, Inc. All rights reserved.
//

import Foundation
import SwiftUI
import Combine
import MessageUI

struct MessageComposeView: UIViewControllerRepresentable {
    var body: String
    var number: String = ""
    let onPresent$: PassthroughSubject<Void, Never>

    @State private var _onPresent$: AnyCancellable?

    typealias UIViewControllerType = MessageComposeViewController

    func makeUIViewController(context: UIViewControllerRepresentableContext<MessageComposeView>) -> UIViewControllerType {
        let vc = UIViewControllerType(body: body, number: number)
        DispatchQueue.main.async {
            self._onPresent$ = self.onPresent$.sink(receiveValue: {
                vc.presentMessageCompose()
            })
        }
        return vc
    }

    func updateUIViewController(_ uiViewController: UIViewControllerType, context: UIViewControllerRepresentableContext<MessageComposeView>) {
        uiViewController.body = body
        uiViewController.number = number
    }
}

final class MessageComposeViewController : UIViewController, ObservableObject {
    var body: String
    var number: String = ""

    // MARK: - Init
    init(body: String, number: String) {
        self.body = body
        self.number = number
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    func presentMessageCompose() {
        guard MFMessageComposeViewController.canSendText() else {
            return
        }
        let vc = UIApplication.shared.keyWindow?.rootViewController
        let composeVC = MFMessageComposeViewController()
        composeVC.messageComposeDelegate = self
        composeVC.body = body
        composeVC.recipients = [number]
        vc?.present(composeVC, animated: true)
    }
}

extension MessageComposeViewController: MFMessageComposeViewControllerDelegate {
    func messageComposeViewController(_ controller: MFMessageComposeViewController, didFinishWith result: MessageComposeResult) {
        controller.dismiss(animated: true, completion: nil)
    }
}
