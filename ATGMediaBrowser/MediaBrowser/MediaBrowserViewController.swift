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

public class MediaBrowserViewController: UIViewController {

    private enum Constants {

        static let gapBetweenContents: CGFloat = 50.0
    }

    private var contentViews: [MediaContentView] = []

    // MARK: - Initializers
    public init() {

        super.init(nibName: nil, bundle: nil)
        initialize()
    }

    public required init?(coder aDecoder: NSCoder) {

        super.init(coder: aDecoder)
        initialize()
    }

    private func initialize() {

        view.backgroundColor = .red
    }

    override public func viewDidLoad() {

        super.viewDidLoad()

        populateContentViews()

        view.addGestureRecognizer(temporaryCloseGestureRecognizer)
    }

    override public func viewDidAppear(_ animated: Bool) {

        super.viewDidAppear(animated)

        contentViews.forEach({ $0.updateTransform() })
    }

    private func populateContentViews() {

        MediaContentView.interItemSpacing = Constants.gapBetweenContents

        contentViews.forEach({ $0.removeFromSuperview() })
        contentViews.removeAll()

        for i in 0..<3 {
            let mediaView = MediaContentView(index: i)
            view.addSubview(mediaView)
            mediaView.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                mediaView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                mediaView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
                mediaView.topAnchor.constraint(equalTo: view.topAnchor),
                mediaView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
            ])

            contentViews.append(mediaView)
        }
    }

    // TODO: - Remove: Temporary Shit
    lazy var temporaryCloseGestureRecognizer: UITapGestureRecognizer = { [unowned self] in

        let gesture = UITapGestureRecognizer()
        gesture.numberOfTapsRequired = 3
        gesture.addTarget(self, action: #selector(temporaryCloseMethod))
        return gesture
    }()

    @objc func temporaryCloseMethod() {

        dismiss(animated: true, completion: nil)
    }
}
