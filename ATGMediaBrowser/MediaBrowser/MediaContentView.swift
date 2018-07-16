//
//  MediaContentView.swift
//  Nisnass
//
//  Created by Suraj Thomas K on 7/10/18.
//  Copyright © 2018 Al Tayer Group LLC. All rights reserved.
//
//  Save to the extent permitted by law, you may not use, copy, modify,
//  distribute or create derivative works of this material or any part
//  of it without the prior written consent of Al Tayer Group LLC.
//  Any reproduction of this material must contain this notice.
//

internal class MediaContentView: UIScrollView {

    internal static var interItemSpacing: CGFloat = 0.0

    internal var index: Int
    internal var position: CGFloat {
        didSet {
            updateTransform()
        }
    }

    init(index itemIndex: Int) {

        self.index = itemIndex
        self.position = CGFloat(itemIndex - 1)

        super.init(frame: .zero)

        initialize()
    }

    required init?(coder aDecoder: NSCoder) {

        fatalError("Do nto use `init?(coder:)`")
    }

    private func initialize() {

        backgroundColor = [UIColor.purple, UIColor.green, UIColor.magenta][index]
    }

    internal func updateTransform() {

        let widthIncludingGap = frame.size.width + MediaContentView.interItemSpacing
        transform = CGAffineTransform.identity.translatedBy(x: position * widthIncludingGap, y: 0.0)
    }
}
