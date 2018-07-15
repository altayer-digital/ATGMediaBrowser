//
//  MediaBrowserViewController.swift
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

public protocol MediaBrowserViewControllerDataSource: class {

    typealias CompletionBlock = (Int, UIImage?, ZoomScale?, Error?) -> Void

    func numberOfItems(in mediaBrowser: MediaBrowserViewController) -> Int
    func mediaBrowser(_ mediaBrowser: MediaBrowserViewController, imageAt index: Int, completion: @escaping CompletionBlock)

    func mediaBrowser(_ mediaBrowser: MediaBrowserViewController, updateCloseButton button: UIButton)
}

extension MediaBrowserViewControllerDataSource {

    func mediaBrowser(_ mediaBrowser: MediaBrowserViewController, updateCloseButton button: UIButton) {}
}

public protocol MediaBrowserViewControllerDelegate: class {

    func mediaBrowser(_ mediaBrowser: MediaBrowserViewController, didChangeFocusTo index: Int)
}

extension MediaBrowserViewControllerDelegate {

    func mediaBrowser(_ mediaBrowser: MediaBrowserViewController, didChangeFocusTo index: Int) {}
}

public class MediaBrowserViewController: UIViewController {

    public var gestureDirection: GestureDirection = .horizontal
    public var gapBetweenMediaViews: CGFloat = Constants.gapBetweenContents {
        didSet {
            MediaContentView.interItemSpacing = gapBetweenMediaViews
            contentViews.forEach({ $0.updateTransform() })
        }
    }

    public var browserStyle: BrowserStyle = .linear
    public weak var dataSource: MediaBrowserViewControllerDataSource?
    public weak var delegate: MediaBrowserViewControllerDelegate?

    private(set) var index: Int = 0

    private enum Constants {

        static let gapBetweenContents: CGFloat = 50.0
        static let minimumVelocity: CGFloat = 15.0
        static let minimumTranslation: CGFloat = 0.1
        static let animationDuration = 0.3
        static let updateFrameRate: CGFloat = 60.0
        static let bounceFactor: CGFloat = 0.1

        enum Close {

            static let top: CGFloat = 8.0
            static let trailing: CGFloat = -8.0
            static let height: CGFloat = 30.0
            static let minWidth: CGFloat = 30.0
            static let contentInsets = UIEdgeInsets(top: 0.0, left: 8.0, bottom: 0.0, right: 8.0)
            static let borderWidth: CGFloat = 2.0
            static let borderColor: UIColor = .white
            static let title = "Close"
        }
    }

    public enum GestureDirection {

        case horizontal
        case vertical
    }

    public enum BrowserStyle {

        case linear
        case carousel
    }

    private var contentViews: [MediaContentView] = []

    private var previousTranslation: CGPoint = .zero

    private var timer: Timer?
    private var distanceToMove: CGFloat = 0.0

    lazy private var panGestureRecognizer: UIPanGestureRecognizer = { [unowned self] in
        let gesture = UIPanGestureRecognizer()
        gesture.minimumNumberOfTouches = 1
        gesture.maximumNumberOfTouches = 1
        gesture.delegate = self
        gesture.addTarget(self, action: #selector(panGestureEvent(_:)))
        return gesture
    }()

    lazy private var closeButton: UIButton = { [unowned self] in

        let button = UIButton()
        button.setTitle(Constants.Close.title, for: .normal)
        button.contentEdgeInsets = Constants.Close.contentInsets
        button.addTarget(self, action: #selector(didTapOnClose(_:)), for: .touchUpInside)
        button.layer.cornerRadius = Constants.Close.height * 0.5
        button.layer.borderColor = Constants.Close.borderColor.cgColor
        button.layer.borderWidth = Constants.Close.borderWidth
        return button
    }()

    private var numMediaItems: Int {
        return dataSource?.numberOfItems(in: self) ?? 1
    }

    // MARK: - Initializers
    public init(
        index: Int,
        dataSource: MediaBrowserViewControllerDataSource,
        delegate: MediaBrowserViewControllerDelegate? = nil
        ) {

        self.index = index
        self.dataSource = dataSource
        self.delegate = delegate

        super.init(nibName: nil, bundle: nil)
    }

    public required init?(coder aDecoder: NSCoder) {

        super.init(coder: aDecoder)
    }

    override public func viewDidLoad() {

        super.viewDidLoad()

        view.backgroundColor = .black

        populateContentViews()

        addCloseButton()

        view.addGestureRecognizer(panGestureRecognizer)
    }

    override public func viewDidAppear(_ animated: Bool) {

        super.viewDidAppear(animated)

        contentViews.forEach({ $0.updateTransform() })
    }

    private func populateContentViews() {

        MediaContentView.interItemSpacing = gapBetweenMediaViews
        MediaContentView.contentTransformer = DefaultContentTransformers.horizontalMoveInOut

        contentViews.forEach({ $0.removeFromSuperview() })
        contentViews.removeAll()

        for i in -1...1 {
            let mediaView = MediaContentView(
                index: i + index,
                position: CGFloat(i),
                frame: view.frame
            )
            view.addSubview(mediaView)
            mediaView.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                mediaView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                mediaView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
                mediaView.topAnchor.constraint(equalTo: view.topAnchor),
                mediaView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
            ])

            contentViews.append(mediaView)

            updateContents(of: mediaView)
        }
    }

    private func addCloseButton() {

        view.addSubview(closeButton)
        dataSource?.mediaBrowser(self, updateCloseButton: closeButton)

        if closeButton.constraints.isEmpty {
            closeButton.translatesAutoresizingMaskIntoConstraints = false
            var topAnchor = view.topAnchor
            if #available(iOS 11.0, *) {
                topAnchor = view.safeAreaLayoutGuide.topAnchor
            }

            NSLayoutConstraint.activate([
                closeButton.topAnchor.constraint(equalTo: topAnchor, constant: Constants.Close.top),
                closeButton.trailingAnchor.constraint(
                    equalTo: view.trailingAnchor,
                    constant: Constants.Close.trailing
                ),
                closeButton.widthAnchor.constraint(greaterThanOrEqualToConstant: Constants.Close.minWidth),
                closeButton.heightAnchor.constraint(equalToConstant: Constants.Close.height)
            ])
        }
    }

    @objc private func didTapOnClose(_ sender: UIButton) {

        dismiss(animated: true, completion: nil)
    }
}

// MARK: - Pan Gesture Recognizer

extension MediaBrowserViewController {

    @objc private func panGestureEvent(_ recognizer: UIPanGestureRecognizer) {

        let translation = recognizer.translation(in: view)

        switch recognizer.state {
        case .began:
            previousTranslation = translation
            distanceToMove = 0.0
            timer?.invalidate()
            timer = nil
        case .changed:
            moveViews(by: CGPoint(x: translation.x - previousTranslation.x, y: translation.y - previousTranslation.y))
        case .ended, .failed, .cancelled:
            let velocity = recognizer.velocity(in: view)

            var viewsCopy = contentViews
            let previousView = viewsCopy.removeFirst()
            let middleView = viewsCopy.removeFirst()
            let nextView = viewsCopy.removeFirst()

            var toMove: CGFloat = 0.0
            let directionalVelocity = gestureDirection == .horizontal ? velocity.x : velocity.y

            if fabs(directionalVelocity) < Constants.minimumVelocity &&
                fabs(middleView.position) < Constants.minimumTranslation {
                toMove = -middleView.position
            } else if directionalVelocity < 0.0 {
                if middleView.position >= 0.0 {
                    toMove = -middleView.position
                } else {
                    toMove = -nextView.position
                }
            } else {
                if middleView.position <= 0.0 {
                    toMove = -middleView.position
                } else {
                    toMove = -previousView.position
                }
            }

            if browserStyle == .linear {
                if (middleView.index == 0 && ((middleView.position + toMove) > 0.0)) ||
                    (middleView.index == (numMediaItems - 1) && (middleView.position + toMove) < 0.0) {

                    toMove = -middleView.position
                }
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

        previousTranslation = translation
    }
}

// MARK: - Updating View Positions

extension MediaBrowserViewController {

    @objc private func update(_ timeInterval: TimeInterval) {

        guard distanceToMove != 0.0 else {

            timer?.invalidate()
            timer = nil
            return
        }

        let distance = distanceToMove / (Constants.updateFrameRate * 0.1)
        distanceToMove -= distance
        moveViewsNormalized(by: CGPoint(x: distance, y: distance))

        let translation = CGPoint(
            x: distance * (view.frame.size.width + gapBetweenMediaViews),
            y: distance * (view.frame.size.height + gapBetweenMediaViews)
        )
        let directionalTranslation = (gestureDirection == .horizontal) ? translation.x : translation.y
        if fabs(directionalTranslation) < 0.1 {

            moveViewsNormalized(by: CGPoint(x: distanceToMove, y: distanceToMove))
            distanceToMove = 0.0
            timer?.invalidate()
            timer = nil
        }
    }

    private func moveViews(by translation: CGPoint) {

        let viewSizeIncludingGap = CGSize(
            width: view.frame.size.width + gapBetweenMediaViews,
            height: view.frame.size.height + gapBetweenMediaViews
        )

        let normalizedTranslation = calculateNormalizedTranslation(
            translation: translation,
            viewSize: viewSizeIncludingGap
        )

        moveViewsNormalized(by: normalizedTranslation)
    }

    private func moveViewsNormalized(by normalizedTranslation: CGPoint) {

        let isGestureHorizontal = (gestureDirection == .horizontal)

        contentViews.forEach({
            $0.position += isGestureHorizontal ? normalizedTranslation.x : normalizedTranslation.y
        })

        var viewsCopy = contentViews
        let previousView = viewsCopy.removeFirst()
        let middleView = viewsCopy.removeFirst()
        let nextView = viewsCopy.removeFirst()

        let viewSizeIncludingGap = CGSize(
            width: view.frame.size.width + gapBetweenMediaViews,
            height: view.frame.size.height + gapBetweenMediaViews
        )

        let viewSize = isGestureHorizontal ? viewSizeIncludingGap.width : viewSizeIncludingGap.height
        let normalizedGap = gapBetweenMediaViews/viewSize
        let normalizedCenter = (middleView.frame.size.width / viewSize) * 0.5
        let viewCount = contentViews.count

        if middleView.position < -(normalizedGap + normalizedCenter) {

            index += 1
            // Previous item is taken and placed on right/down most side
            previousView.position += CGFloat(viewCount)
            previousView.index += viewCount
            updateContents(of: previousView)

            contentViews.removeFirst()
            contentViews.append(previousView)

            delegate?.mediaBrowser(self, didChangeFocusTo: index)

        } else if middleView.position > (1 + normalizedGap - normalizedCenter) {

            index -= 1
            // Next item is taken and placed on left/top most side
            nextView.position -= CGFloat(viewCount)
            nextView.index -= viewCount
            updateContents(of: nextView)

            contentViews.removeLast()
            contentViews.insert(nextView, at: 0)

            delegate?.mediaBrowser(self, didChangeFocusTo: index)
        }
    }

    private func calculateNormalizedTranslation(translation: CGPoint, viewSize: CGSize) -> CGPoint {

        let middleView = contentViews[1]

        var normalizedTranslation = CGPoint(
            x: (translation.x)/viewSize.width,
            y: (translation.y)/viewSize.height
        )

        if browserStyle != .carousel {
            let isGestureHorizontal = (gestureDirection == .horizontal)
            let directionalTranslation = isGestureHorizontal ? normalizedTranslation.x : normalizedTranslation.y
            if (middleView.index == 0 && ((middleView.position + directionalTranslation) > 0.0)) ||
                (middleView.index == (numMediaItems - 1) && (middleView.position + directionalTranslation) < 0.0) {
                if isGestureHorizontal {
                    normalizedTranslation.x *= Constants.bounceFactor
                } else {
                    normalizedTranslation.y *= Constants.bounceFactor
                }
            }
        }
        return normalizedTranslation
    }

    private func updateContents(of contentView: MediaContentView) {

        contentView.image = nil
        let convertedIndex = abs(contentView.index) % numMediaItems
        contentView.isLoading = true
        dataSource?.mediaBrowser(self, imageAt: convertedIndex, completion: { (index, image, zoom, _) in

            if convertedIndex == index && image != nil {
                contentView.image = image
                contentView.zoomLevels = zoom
            }
            contentView.isLoading = false
        })
    }
}

// MARK: - UIGestureRecognizerDelegate

extension MediaBrowserViewController: UIGestureRecognizerDelegate {

    public func gestureRecognizer(
        _ gestureRecognizer: UIGestureRecognizer,
        shouldBeRequiredToFailBy otherGestureRecognizer: UIGestureRecognizer
        ) -> Bool {

        if let scrollView = otherGestureRecognizer.view as? MediaContentView {
            return scrollView.zoomScale == 1.0
        }
        return false
    }
}
