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

public struct ZoomScale {

    public var minimumZoomScale: CGFloat
    public var maximumZoomScale: CGFloat

    public static let `default` = ZoomScale(
        minimumZoomScale: 1.0,
        maximumZoomScale: 3.0
    )
}

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
            updateImageView()
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

    internal var zoomLevels: ZoomScale? {
        didSet {
            zoomScale = ZoomScale.default.minimumZoomScale
            minimumZoomScale = zoomLevels?.minimumZoomScale ?? ZoomScale.default.minimumZoomScale
            maximumZoomScale = zoomLevels?.maximumZoomScale ?? ZoomScale.default.maximumZoomScale
        }
    }

    private lazy var imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
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

    private lazy var doubleTapGestureRecognizer: UITapGestureRecognizer = { [unowned self] in
        let gesture = UITapGestureRecognizer(target: self, action: #selector(didDoubleTap(_:)))
        gesture.numberOfTapsRequired = 2
        gesture.numberOfTouchesRequired = 1
        return gesture
    }()

    init(index itemIndex: Int, position: CGFloat, frame: CGRect) {

        self.index = itemIndex
        self.position = position

        super.init(frame: frame)

        initializeViewComponents()
    }

    required init?(coder aDecoder: NSCoder) {

        fatalError("Do nto use `init?(coder:)`")
    }

    private func initializeViewComponents() {

        addSubview(imageView)
        imageView.frame = frame

        setupIndicatorView()

        configureScrollView()

        addGestureRecognizer(doubleTapGestureRecognizer)

        updateTransform()
    }

    private func configureScrollView() {

        isMultipleTouchEnabled = true
        showsHorizontalScrollIndicator = false
        showsVerticalScrollIndicator = false
        contentSize = imageView.frame.size
        canCancelContentTouches = false
        zoomLevels = ZoomScale.default
        delegate = self
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

    @objc private func didDoubleTap(_ recognizer: UITapGestureRecognizer) {

        let locationInImage = recognizer.location(in: imageView)

        let isImageCoveringScreen = imageView.frame.size.width > frame.size.width &&
            imageView.frame.size.height > frame.size.height
        let zoomTo = isImageCoveringScreen ? minimumZoomScale : maximumZoomScale

        let width = frame.size.width / zoomTo
        let height = frame.size.height / zoomTo

        let zoomRect = CGRect(
            x: locationInImage.x - width * 0.5,
            y: locationInImage.y - height * 0.5,
            width: width,
            height: height
        )

        zoom(to: zoomRect, animated: true)
    }
}

// MARK: - UIScrollViewDelegate

extension MediaContentView: UIScrollViewDelegate {

    func viewForZooming(in scrollView: UIScrollView) -> UIView? {

        return image != nil ? imageView : nil
    }

    func scrollViewDidZoom(_ scrollView: UIScrollView) {

        centerImageView()
    }

    func centerImageView() {

        var imageViewFrame = imageView.frame

        if imageViewFrame.size.width < frame.size.width {
            imageViewFrame.origin.x = (frame.size.width - imageViewFrame.size.width) / 2.0
        } else {
            imageViewFrame.origin.x = 0.0
        }

        if imageViewFrame.size.height < frame.size.height {
            imageViewFrame.origin.y = (frame.size.height - imageViewFrame.size.height) / 2.0
        } else {
            imageViewFrame.origin.y = 0.0
        }

        imageView.frame = imageViewFrame
    }

    private func updateImageView() {

        imageView.image = image

        if let contentImage = image {

            let imageViewSize = imageView.frame.size
            let imageSize = contentImage.size
            var targetImageSize = imageViewSize

            if imageSize.width / imageSize.height > imageViewSize.width / imageViewSize.height {
                targetImageSize.height = imageViewSize.width / imageSize.width * imageSize.height
            } else {
                targetImageSize.width = imageViewSize.height / imageSize.height * imageSize.width
            }

            imageView.frame = CGRect(origin: .zero, size: targetImageSize)
        }
        centerImageView()
    }
}
