//
//  PassthroughView.swift
//  sayit
//
//  Created by Robert Malko on 12/15/19.
//  Copyright © 2019 Extra Visual. All rights reserved.
//

import UIKit

final class PassthroughView: UIView {
    var childView: UIView?

    init(childView: UIView) {
        self.childView = childView
        super.init(frame: childView.frame)
        if let subview = self.childView {
            self.addSubview(subview)
        }
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    // see http://khanlou.com/2018/09/hacking-hit-tests/
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        guard isUserInteractionEnabled else { return nil }
        guard !isHidden else { return nil }
        guard alpha >= 0.01 else { return nil }
        guard self.point(inside: point, with: event) else { return nil }
        guard let view = super.hitTest(point, with: event) else { return nil }

        if view.frame.size == UIScreen.main.bounds.size {
            return nil
        }

        return view
    }
}
