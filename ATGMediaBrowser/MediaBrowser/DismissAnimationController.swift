//
//  DismissAnimationController.swift
//  ATGMediaBrowser
//
//  Created by Suraj Thomas K on 7/19/18.
//  Copyright © 2018 Al Tayer Group LLC. All rights reserved.
//
//  Save to the extent permitted by law, you may not use, copy, modify,
//  distribute or create derivative works of this material or any part
//  of it without the prior written consent of Al Tayer Group LLC.
//  Any reproduction of this material must contain this notice.
//

internal class DismissAnimationController: NSObject {

    private enum Constants {

        static let minimumVelocity: CGFloat = 15.0
        static let minimumTranslation: CGFloat = 0.25
        static let transitionDuration = 0.3
        static let updateFrameRate: CGFloat = 60.0
    }

    internal var image: UIImage?
    internal let gestureDirection: MediaBrowserViewController.GestureDirection
    internal weak var viewController: MediaBrowserViewController?
    internal var interactionInProgress = false

    private lazy var imageView = UIImageView()
    private var backgroundView: UIView?

    private var timer: Timer?
    private var distanceToMove: CGFloat = 0.0
    private var relativePosition: CGFloat = 0.0 {
        didSet {
            updateTransition()
        }
    }

    init(
        image: UIImage? = nil,
        gestureDirection: MediaBrowserViewController.GestureDirection,
        viewController: MediaBrowserViewController
        ) {

        self.image = image
        self.gestureDirection = gestureDirection
        self.viewController = viewController
    }

    internal func handleInteractiveTransition(_ recognizer: UIPanGestureRecognizer) {

        let translation = recognizer.translation(in: recognizer.view)

        var progress: CGFloat = 0.0
        if gestureDirection == .horizontal {
            progress = translation.y / UIScreen.main.bounds.size.height
        } else {
            progress = translation.x / UIScreen.main.bounds.size.width
        }

        switch recognizer.state {
        case .began:
            beginTransition()
            fallthrough
        case .changed:
            relativePosition = progress
        case .ended, .cancelled, .failed:
            var toMove: CGFloat = 0.0

            if fabs(progress) > Constants.minimumTranslation {
                toMove = (progress / fabs(progress))
            } else {
                toMove = -progress
            }

            distanceToMove = toMove

            if timer == nil {
                timer = Timer.scheduledTimer(
                    timeInterval: 1.0/Double(Constants.updateFrameRate),
                    target: self,
                    selector: #selector(update(_:)),
                    userInfo: nil,
                    repeats: true
                )
            }
        default:
            break
        }
    }

    @objc private func update(_ timeInterval: TimeInterval) {

        let distance = distanceToMove / (Constants.updateFrameRate * 0.15)
        distanceToMove -= distance
        relativePosition += distance

        let translation = CGPoint(
            x: distance * (UIScreen.main.bounds.size.width),
            y: distance * (UIScreen.main.bounds.size.height)
        )
        let directionalTranslation = (gestureDirection == .horizontal) ? translation.y : translation.x
        if fabs(directionalTranslation) < 1.0 {

            relativePosition += distanceToMove
            interactionInProgress = false

            finishTransition()
        }
    }

    private func beginTransition() {

        createTransitionViews()

        viewController?.mediaContainerView.isHidden = true
        viewController?.hideControls = true
        viewController?.visualEffectContainer.isHidden = true
    }

    private func finishTransition() {

        distanceToMove = 0.0
        timer?.invalidate()
        timer = nil

        imageView.removeFromSuperview()

        backgroundView?.removeFromSuperview()
        backgroundView = nil

        if relativePosition != 0.0 {
            viewController?.dismiss(animated: false, completion: nil)
        } else {
            viewController?.mediaContainerView.isHidden = false
            viewController?.hideControls = false
            viewController?.visualEffectContainer.isHidden = false
        }
    }

    private func createTransitionViews() {

        if let viewController = viewController,
            let bg = viewController.visualEffectContainer.snapshotView(afterScreenUpdates: true) {
            backgroundView = bg
            viewController.view.addSubview(bg)
            NSLayoutConstraint.activate([
                bg.leadingAnchor.constraint(equalTo: viewController.view.leadingAnchor),
                bg.trailingAnchor.constraint(equalTo: viewController.view.trailingAnchor),
                bg.topAnchor.constraint(equalTo: viewController.view.topAnchor),
                bg.bottomAnchor.constraint(equalTo: viewController.view.bottomAnchor)
                ])
        }

        imageView.image = image
        imageView.frame = imageViewFrame(
            for: image?.size ?? .zero,
            in: viewController?.view.bounds ?? .zero
        )
        viewController?.view.addSubview(imageView)
        imageView.transform = CGAffineTransform.identity
    }

    private func updateTransition() {

        var transform = CGAffineTransform.identity
        if gestureDirection == .horizontal {
            transform = transform.translatedBy(
                x: 0.0,
                y: relativePosition * UIScreen.main.bounds.size.height
            )
        } else {
            transform = transform.translatedBy(
                x: relativePosition * UIScreen.main.bounds.size.width,
                y: 0.0
            )
        }
        imageView.transform = transform

        let alpha = (relativePosition < 0.0) ? relativePosition + 1.0 : 1.0 - relativePosition
        backgroundView?.alpha = alpha
    }


    private func imageViewFrame(for imageSize: CGSize, in frame: CGRect) -> CGRect {

        guard imageSize != .zero else {
            return frame
        }

        var targetImageSize = frame.size

        if imageSize.width / imageSize.height > frame.size.width / frame.size.height {
            targetImageSize.height = frame.size.width / imageSize.width * imageSize.height
        } else {
            targetImageSize.width = frame.size.height / imageSize.height * imageSize.width
        }

        let x = (frame.size.width - targetImageSize.width) / 2.0
        let y = (frame.size.height - targetImageSize.height) / 2.0

        return CGRect(origin: CGPoint(x: x, y: y), size: targetImageSize)
    }
}
