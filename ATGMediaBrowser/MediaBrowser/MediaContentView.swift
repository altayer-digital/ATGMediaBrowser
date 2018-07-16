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

typealias ContentTransformer = (MediaContentView, CGPoint) -> Void

internal class MediaContentView: UIScrollView {

    static let horizontalMovement: ContentTransformer = { contentView, position in

        let widthIncludingGap = contentView.frame.size.width + MediaContentView.interItemSpacing
        contentView.transform = CGAffineTransform(translationX: widthIncludingGap * position.x, y: 0.0)
    }

    static let verticalMovement: ContentTransformer = { contentView, position in

        let heightIncludingGap = contentView.frame.size.height + MediaContentView.interItemSpacing
        contentView.transform = CGAffineTransform(translationX: 0.0, y: heightIncludingGap * position.y)
    }

    internal static var interItemSpacing: CGFloat = 0.0

    internal var index: Int
    internal var position: CGPoint {
        didSet {
            updateTransform()
        }
    }

    internal static var transformer: ContentTransformer = horizontalMovement

    init(index itemIndex: Int) {

        self.index = itemIndex

        self.position = CGPoint(
            x: itemIndex - 1,
            y: itemIndex - 1
        )

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

        MediaContentView.transformer(self, position)
    }
}
