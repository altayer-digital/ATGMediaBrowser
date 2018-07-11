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

    internal var index: Int {
        didSet {
            updateContents()
        }
    }
    internal var position: CGFloat {
        didSet {
            updateTransform()
        }
    }

    internal static var contentTransformer: ContentTransformer = DefaultContentTransformers.horizontalMoveInOut

    internal var image: UIImage? {
        didSet {
            imageView.image = image
        }
    }

    private lazy var imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.clipsToBounds = true
        return imageView
    }()

    init(index itemIndex: Int) {

        self.index = itemIndex
        self.position = CGFloat(itemIndex)

        super.init(frame: .zero)

        initialize()
    }

    required init?(coder aDecoder: NSCoder) {

        fatalError("Do nto use `init?(coder:)`")
    }

    private func initialize() {

        backgroundColor = [UIColor.purple, UIColor.green, UIColor.magenta][index + 1]

        addSubview(imageView)
        imageView.frame = frame
    }

    internal func updateTransform() {

        MediaContentView.contentTransformer(self, position)
    }

    private func updateContents() {

        // TODO: Update image/video contents here.
    }
}
