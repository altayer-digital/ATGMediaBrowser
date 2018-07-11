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

    private enum Constants {

        static let indicatorViewSize: CGFloat = 60.0
    }

    internal static var interItemSpacing: CGFloat = 0.0

    internal var index: Int
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

    internal var isLoading: Bool = false {
        didSet {
            indicatorContainer.isHidden = !isLoading
            if isLoading {
                indicator.startAnimating()
            } else {
                indicator.stopAnimating()
            }
        }
    }

    private lazy var imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.clipsToBounds = true
        return imageView
    }()

    private lazy var indicator: UIActivityIndicatorView = {
        let indicatorView = UIActivityIndicatorView()
        indicatorView.activityIndicatorViewStyle = .whiteLarge
        indicatorView.hidesWhenStopped = true
        return indicatorView
    }()

    private lazy var indicatorContainer: UIView = {
        let container = UIView()
        container.backgroundColor = .darkGray
        container.layer.cornerRadius = Constants.indicatorViewSize * 0.5
        container.layer.masksToBounds = true
        return container
    }()

    init(index itemIndex: Int) {

        self.index = itemIndex
        self.position = CGFloat(itemIndex)

        super.init(frame: .zero)

        initializeViewComponents()
    }

    required init?(coder aDecoder: NSCoder) {

        fatalError("Do nto use `init?(coder:)`")
    }

    private func initializeViewComponents() {

        backgroundColor = [UIColor.purple, UIColor.green, UIColor.magenta][index + 1]

        addSubview(imageView)
        imageView.frame = frame

        setupIndicatorView()
    }

    private func setupIndicatorView() {

        addSubview(indicatorContainer)
        indicatorContainer.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            indicatorContainer.widthAnchor.constraint(equalToConstant: Constants.indicatorViewSize),
            indicatorContainer.heightAnchor.constraint(equalToConstant: Constants.indicatorViewSize),
            indicatorContainer.centerXAnchor.constraint(equalTo: centerXAnchor),
            indicatorContainer.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])

        indicatorContainer.addSubview(indicator)
        indicator.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            indicator.leadingAnchor.constraint(equalTo: indicatorContainer.leadingAnchor),
            indicator.trailingAnchor.constraint(equalTo: indicatorContainer.trailingAnchor),
            indicator.topAnchor.constraint(equalTo: indicatorContainer.topAnchor),
            indicator.bottomAnchor.constraint(equalTo: indicatorContainer.bottomAnchor)
        ])

        indicatorContainer.setNeedsLayout()
        indicatorContainer.layoutIfNeeded()

        indicatorContainer.isHidden = true
    }

    internal func updateTransform() {

        MediaContentView.contentTransformer(self, position)
    }
}
