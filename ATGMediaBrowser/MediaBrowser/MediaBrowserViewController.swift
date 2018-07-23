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

// MARK: - MediaBrowserViewControllerDataSource protocol
/// Protocol to supply media browser contents.
public protocol MediaBrowserViewControllerDataSource: class {

    /**
     Completion block for passing requested media image with details.
     - parameter index: Index of the requested media.
     - parameter image: Image to be passed back to media browser.
     - parameter zoomScale: Zoom scale to be applied to the image including min and max levels.
     - parameter error: Error received while fetching the media image.

     - note:
        Remember to pass the index received in the datasource method back.
        This index is used to set the image to the correct image view.
     */
    typealias CompletionBlock = (_ index: Int, _ image: UIImage?, _ zoomScale: ZoomScale?, _ error: Error?) -> Void

    /**
     Method to supply number of items to be shown in media browser.
     - parameter mediaBrowser: Reference to media browser object.
     - returns: An integer with number of items to be shown in media browser.
     */
    func numberOfItems(in mediaBrowser: MediaBrowserViewController) -> Int

    /**
     Method to supply image for specific index.
     - parameter mediaBrowser: Reference to media browser object.
     - parameter index: Index of the requested media.
     - parameter completion: Completion block to be executed on fetching the media image.
     */
    func mediaBrowser(_ mediaBrowser: MediaBrowserViewController, imageAt index: Int, completion: @escaping CompletionBlock)

    /**
     This **optional method** callback is provided to update the styling of close button.
     - parameter mediaBrowser: Reference to media browser object.
     - parameter button: Reference to close button

     - note:
        You can modify the styling of the supplied button, and even add constraints to position
     the button relative to it's superview. Remember that if no constraints are applied on the button,
     default constraints will be applied on, and will be shown on top-right side of the view.

        On top of that you can add target to this button to handle the closebutton event manually. By
     default touch-up-inside event is used to close the media browser.
     */
    func mediaBrowser(_ mediaBrowser: MediaBrowserViewController, updateCloseButton button: UIButton)

    /**
     This method is used to get the target frame into which the browser will perform the dismiss transition.
     - parameter mediaBrowser: Reference to media browser object.

     - note:
        If this method is not implemented, the media browser will perform slide up/down transition on dismissal.
    */
    func targetFrameForDismissal(_ mediaBrowser: MediaBrowserViewController) -> CGRect?
}

extension MediaBrowserViewControllerDataSource {

    func mediaBrowser(_ mediaBrowser: MediaBrowserViewController, updateCloseButton button: UIButton) {}
    func targetFrameForDismissal(_ mediaBrowser: MediaBrowserViewController) -> CGRect? { return nil }
}

// MARK: - MediaBrowserViewControllerDelegate protocol

public protocol MediaBrowserViewControllerDelegate: class {

    /**
     Method invoked on scrolling to next/previous media items.
     - parameter mediaBrowser: Reference to media browser object.
     - parameter index: Index of the newly focussed media item.
     - note:
        This method will not be called on first load, and will be called only on swiping left and right.
     */
    func mediaBrowser(_ mediaBrowser: MediaBrowserViewController, didChangeFocusTo index: Int)
}

extension MediaBrowserViewControllerDelegate {

    func mediaBrowser(_ mediaBrowser: MediaBrowserViewController, didChangeFocusTo index: Int) {}
}

public class MediaBrowserViewController: UIViewController {

    // MARK: - Exposed Enumerations

    /**
     Enum to hold supported gesture directions.

     ```
     case horizontal
     case vertical
     ```
    */
    public enum GestureDirection {

        /// Horizontal (left - right) gestures.
        case horizontal
        /// Vertical (up - down) gestures.
        case vertical
    }

    /**
     Enum to hold supported browser styles.

     ```
     case linear
     case carousel
     ```
     */
    public enum BrowserStyle {

        /// Linear browser with *0* as first index and *numItems-1* as last index.
        case linear
        /// Carousel browser. The media items are repeated in a circular fashion.
        case carousel
    }

    /**
     Enum to hold supported content draw orders.

     ```
     case previousToNext
     case nextToPrevious
     ```
     - note:
        Remember that this is draw order, not positioning. This order decides which item will
     be above or below other items, when they overlap.
     */
    public enum ContentDrawOrder {

        /// In this mode, media items are rendered in [previous]-[current]-[next] order.
        case previousToNext
        /// In this mode, media items are rendered in [next]-[current]-[previous] order.
        case nextToPrevious
    }

    // MARK: - Exposed variables

    /// Data-source object to supply media browser contents.
    public weak var dataSource: MediaBrowserViewControllerDataSource?
    /// Delegate object to get callbacks on media browser events.
    public weak var delegate: MediaBrowserViewControllerDelegate?

    /// Gesture direction. Default is `horizontal`.
    public var gestureDirection: GestureDirection = .horizontal
    /// Content transformer closure. Default is `horizontalMoveInOut`.
    public var contentTransformer: ContentTransformer = DefaultContentTransformers.horizontalMoveInOut {
        didSet {

            MediaContentView.contentTransformer = contentTransformer
            contentViews.forEach({ $0.updateTransform() })
        }
    }
    /// Content draw order. Default is `previousToNext`.
    public var drawOrder: ContentDrawOrder = .previousToNext {
        didSet {
            if oldValue != drawOrder {
                mediaContainerView.exchangeSubview(at: 0, withSubviewAt: 2)
            }
        }
    }
    /// Browser style. Default is carousel.
    public var browserStyle: BrowserStyle = .carousel
    /// Gap between consecutive media items. Default is `50.0`.
    public var gapBetweenMediaViews: CGFloat = Constants.gapBetweenContents {
        didSet {
            MediaContentView.interItemSpacing = gapBetweenMediaViews
            contentViews.forEach({ $0.updateTransform() })
        }
    }
    /// Variable to hide/show page control in media browser.
    public var shouldShowPageControl: Bool = true {
        didSet {
            pageControl.isHidden = !shouldShowPageControl
        }
    }
    /// Variable to hide/show controls(close & page control). Default is false.
    public var hideControls: Bool = false {
        didSet {
            hideControlViews(hideControls)
        }
    }
    /**
    Variable to schedule/cancel auto-hide controls(close & page control). Default is false.
    Default delay is `3.0` seconds.
    - todo: Update to accept auto-hide-delay.
     */
    public var autoHideControls: Bool = false {
        didSet {
            if autoHideControls {
                DispatchQueue.main.asyncAfter(
                    deadline: .now() + Constants.controlHideDelay,
                    execute: controlToggleTask
                )
            } else {
                controlToggleTask.cancel()
            }
        }
    }

    /// Item index of the current item. In range `0..<numMediaItems`
    public var currentItemIndex: Int {

        return sanitizeIndex(index)
    }

    // MARK: - Private Enumerations

    private enum Constants {

        static let gapBetweenContents: CGFloat = 50.0
        static let minimumVelocity: CGFloat = 15.0
        static let minimumTranslation: CGFloat = 0.1
        static let animationDuration = 0.3
        static let updateFrameRate: CGFloat = 60.0
        static let bounceFactor: CGFloat = 0.1
        static let controlHideDelay = 3.0

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

        enum PageControl {

            static let bottom: CGFloat = -10.0
            static let tintColor: UIColor = .lightGray
            static let selectedTintColor: UIColor = .white
        }
    }

    // MARK: - Private variables
    private(set) var index: Int = 0 {
        didSet {
            pageControl.currentPage = index
        }
    }

    private var contentViews: [MediaContentView] = []

    private var controlViews: [UIView] = []
    lazy private var controlToggleTask: DispatchWorkItem = { [unowned self] in

        let item = DispatchWorkItem {
            self.hideControls = true
        }
        return item
    }()
    lazy private var tapGestureRecognizer: UITapGestureRecognizer = { [unowned self] in
        let gesture = UITapGestureRecognizer()
        gesture.numberOfTapsRequired = 1
        gesture.numberOfTouchesRequired = 1
        gesture.delegate = self
        gesture.addTarget(self, action: #selector(tapGestureEvent(_:)))
        return gesture
    }()

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

    lazy internal private(set) var mediaContainerView: UIView = { [unowned self] in
        let container = UIView()
        container.backgroundColor = .clear
        return container
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

    lazy private var pageControl: UIPageControl = { [unowned self] in
        let pageControl = UIPageControl()
        pageControl.hidesForSinglePage = true
        pageControl.numberOfPages = numMediaItems
        pageControl.currentPageIndicatorTintColor = Constants.PageControl.selectedTintColor
        pageControl.tintColor = Constants.PageControl.tintColor
        pageControl.currentPage = index
        return pageControl
    }()

    lazy internal private(set) var visualEffectContainer: UIView = UIView()
    lazy private var visualEffectContentView: UIImageView = { [unowned self] in
        let imageView = UIImageView(frame: view.frame)
        imageView.contentMode = .scaleAspectFill
        return imageView
    }()
    lazy private var blurEffect: UIBlurEffect = {
        return UIBlurEffect(style: .dark)
    }()
    lazy private var visualEffectView: UIVisualEffectView = { [unowned self] in
        return UIVisualEffectView(effect: blurEffect)
    }()

    private var numMediaItems = 0

    private lazy var dismissController = DismissAnimationController(
        gestureDirection: gestureDirection,
        viewController: self
    )

    // MARK: - Public methods

    /// Invoking this method reloads the contents media browser.
    public func reloadContentViews() {

        numMediaItems = dataSource?.numberOfItems(in: self) ?? 0
        if shouldShowPageControl {
            pageControl.numberOfPages = numMediaItems
        }

        for contentView in contentViews {

            updateContents(of: contentView)
        }

        dataSource?.mediaBrowser(self, updateCloseButton: closeButton)
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

        initialize()
    }

    public required init?(coder aDecoder: NSCoder) {

        super.init(coder: aDecoder)

        initialize()
    }

    private func initialize() {

        view.backgroundColor = .clear

        modalPresentationStyle = .custom

        modalTransitionStyle = .crossDissolve
    }
}

// MARK: - View Lifecycle and Events

extension MediaBrowserViewController {

    override public var prefersStatusBarHidden: Bool {

        return true
    }

    override public func viewDidLoad() {

        super.viewDidLoad()

        numMediaItems = dataSource?.numberOfItems(in: self) ?? 0

        addVisualEffectView()

        populateContentViews()

        addCloseButton()

        addPageControl()

        view.addGestureRecognizer(panGestureRecognizer)
        view.addGestureRecognizer(tapGestureRecognizer)
    }

    override public func viewDidAppear(_ animated: Bool) {

        super.viewDidAppear(animated)

        contentViews.forEach({ $0.updateTransform() })
    }

    override public func viewWillDisappear(_ animated: Bool) {

        super.viewWillDisappear(animated)

        if !controlToggleTask.isCancelled {
            controlToggleTask.cancel()
        }
    }

    private func addVisualEffectView() {

        view.addSubview(visualEffectContainer)
        visualEffectContainer.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            visualEffectContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            visualEffectContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            visualEffectContainer.topAnchor.constraint(equalTo: view.topAnchor),
            visualEffectContainer.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])

        visualEffectContainer.addSubview(visualEffectContentView)
        visualEffectContentView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            visualEffectContentView.leadingAnchor.constraint(equalTo: visualEffectContainer.leadingAnchor),
            visualEffectContentView.trailingAnchor.constraint(equalTo: visualEffectContainer.trailingAnchor),
            visualEffectContentView.topAnchor.constraint(equalTo: visualEffectContainer.topAnchor),
            visualEffectContentView.bottomAnchor.constraint(equalTo: visualEffectContainer.bottomAnchor)
        ])

        visualEffectContainer.addSubview(visualEffectView)
        visualEffectView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            visualEffectView.leadingAnchor.constraint(equalTo: visualEffectContainer.leadingAnchor),
            visualEffectView.trailingAnchor.constraint(equalTo: visualEffectContainer.trailingAnchor),
            visualEffectView.topAnchor.constraint(equalTo: visualEffectContainer.topAnchor),
            visualEffectView.bottomAnchor.constraint(equalTo: visualEffectContainer.bottomAnchor)
        ])
    }

    private func populateContentViews() {

        view.addSubview(mediaContainerView)
        mediaContainerView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            mediaContainerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            mediaContainerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            mediaContainerView.topAnchor.constraint(equalTo: view.topAnchor),
            mediaContainerView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])

        MediaContentView.interItemSpacing = gapBetweenMediaViews
        MediaContentView.contentTransformer = contentTransformer

        contentViews.forEach({ $0.removeFromSuperview() })
        contentViews.removeAll()

        for i in -1...1 {
            let mediaView = MediaContentView(
                index: i + index,
                position: CGFloat(i),
                frame: view.bounds
            )
            mediaContainerView.addSubview(mediaView)
            mediaView.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                mediaView.leadingAnchor.constraint(equalTo: mediaContainerView.leadingAnchor),
                mediaView.trailingAnchor.constraint(equalTo: mediaContainerView.trailingAnchor),
                mediaView.topAnchor.constraint(equalTo: mediaContainerView.topAnchor),
                mediaView.bottomAnchor.constraint(equalTo: mediaContainerView.bottomAnchor)
            ])

            contentViews.append(mediaView)

            if numMediaItems > 0 {
                updateContents(of: mediaView)
            }
        }
        if drawOrder == .nextToPrevious {
            mediaContainerView.exchangeSubview(at: 0, withSubviewAt: 2)
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
        controlViews.append(closeButton)
    }

    private func addPageControl() {

        view.addSubview(pageControl)
        pageControl.translatesAutoresizingMaskIntoConstraints = false
        var bottomAnchor = view.bottomAnchor
        if #available(iOS 11.0, *) {
            bottomAnchor = view.safeAreaLayoutGuide.bottomAnchor
        }
        NSLayoutConstraint.activate([
            pageControl.bottomAnchor.constraint(equalTo: bottomAnchor, constant: Constants.PageControl.bottom),
            pageControl.centerXAnchor.constraint(equalTo: view.centerXAnchor)
        ])

        controlViews.append(pageControl)
    }

    private func hideControlViews(_ hide: Bool) {

        UIView.animate(
            withDuration: Constants.animationDuration,
            delay: 0.0,
            options: .beginFromCurrentState,
            animations: {
                self.controlViews.forEach { $0.alpha = hide ? 0.0 : 1.0 }
            },
            completion: nil
        )
    }

    @objc private func didTapOnClose(_ sender: UIButton) {

        if let targetFrame = dataSource?.targetFrameForDismissal(self) {
            dismissController.image = sourceImage()
            dismissController.beginTransition()
            dismissController.animateToTargetFrame(targetFrame)
        } else {
            dismiss(animated: true, completion: nil)
        }
    }
}

// MARK: - Gesture Recognizers

extension MediaBrowserViewController {

    @objc private func panGestureEvent(_ recognizer: UIPanGestureRecognizer) {

        if dismissController.interactionInProgress {
            dismissController.handleInteractiveTransition(recognizer)
            return
        }

        guard numMediaItems > 0 else {
            return
        }

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

            if browserStyle == .linear || numMediaItems <= 1 {
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

    @objc private func tapGestureEvent(_ recognizer: UITapGestureRecognizer) {

        guard !dismissController.interactionInProgress else {
            return
        }

        if !controlToggleTask.isCancelled {
            controlToggleTask.cancel()
        }
        hideControls = !hideControls
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

            index = sanitizeIndex(index + 1)

            // Previous item is taken and placed on right/down most side
            previousView.position += CGFloat(viewCount)
            previousView.index += viewCount
            updateContents(of: previousView)

            if let image = nextView.image {
                self.visualEffectContentView.image = image
            }

            contentViews.removeFirst()
            contentViews.append(previousView)

            switch drawOrder {
            case .previousToNext:
                mediaContainerView.bringSubview(toFront: previousView)
            case .nextToPrevious:
                mediaContainerView.sendSubview(toBack: previousView)
            }

            delegate?.mediaBrowser(self, didChangeFocusTo: index)

        } else if middleView.position > (1 + normalizedGap - normalizedCenter) {

            index = sanitizeIndex(index - 1)

            // Next item is taken and placed on left/top most side
            nextView.position -= CGFloat(viewCount)
            nextView.index -= viewCount
            updateContents(of: nextView)

            if let image = previousView.image {
                self.visualEffectContentView.image = image
            }

            contentViews.removeLast()
            contentViews.insert(nextView, at: 0)

            switch drawOrder {
            case .previousToNext:
                mediaContainerView.sendSubview(toBack: nextView)
            case .nextToPrevious:
                mediaContainerView.bringSubview(toFront: nextView)
            }

            delegate?.mediaBrowser(self, didChangeFocusTo: index)
        }
    }

    private func calculateNormalizedTranslation(translation: CGPoint, viewSize: CGSize) -> CGPoint {

        let middleView = contentViews[1]

        var normalizedTranslation = CGPoint(
            x: (translation.x)/viewSize.width,
            y: (translation.y)/viewSize.height
        )

        if browserStyle != .carousel || numMediaItems <= 1 {
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
        let convertedIndex = sanitizeIndex(contentView.index)
        contentView.isLoading = true
        dataSource?.mediaBrowser(self, imageAt: convertedIndex, completion: { (index, image, zoom, _) in

            if convertedIndex == index && image != nil {
                contentView.image = image
                contentView.zoomLevels = zoom

                if index == self.index {
                    self.visualEffectContentView.image = image
                }
            }
            contentView.isLoading = false
        })
    }

    private func sanitizeIndex(_ index: Int) -> Int {

        let newIndex = index % numMediaItems
        if newIndex < 0 {
            return newIndex + numMediaItems
        }
        return newIndex
    }

    func sourceImage() -> UIImage? {

        guard contentViews.count > 1 else { return nil }

        return contentViews[1].image
    }
}

// MARK: - UIGestureRecognizerDelegate

extension MediaBrowserViewController: UIGestureRecognizerDelegate {

    public func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {

        if let recognizer = gestureRecognizer as? UIPanGestureRecognizer {

            let translation = recognizer.translation(in: recognizer.view)

            if gestureDirection == .horizontal {
                dismissController.interactionInProgress = abs(translation.y) > abs(translation.x)
            } else {
                dismissController.interactionInProgress = abs(translation.x) > abs(translation.y)
            }
            if dismissController.interactionInProgress {
                dismissController.image = sourceImage()
            }
        }
        return true
    }

    public func gestureRecognizer(
        _ gestureRecognizer: UIGestureRecognizer,
        shouldBeRequiredToFailBy otherGestureRecognizer: UIGestureRecognizer
        ) -> Bool {

        if gestureRecognizer is UIPanGestureRecognizer,
            let scrollView = otherGestureRecognizer.view as? MediaContentView {
            return scrollView.zoomScale == 1.0
        }
        return false
    }

    public func gestureRecognizer(
        _ gestureRecognizer: UIGestureRecognizer,
        shouldRequireFailureOf otherGestureRecognizer: UIGestureRecognizer
        ) -> Bool {

        if gestureRecognizer is UITapGestureRecognizer {
            return otherGestureRecognizer.view is MediaContentView
        }
        return false
    }
}
