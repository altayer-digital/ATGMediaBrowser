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

    // TODO: Remove
    private static var tempIndex = 0

    override init(frame: CGRect) {

        super.init(frame: frame)
    }

    required init?(coder aDecoder: NSCoder) {

        super.init(coder: aDecoder)

    }

    private func initialize() {

        backgroundColor = [UIColor.purple, UIColor.green, UIColor.magenta][MediaContentView.tempIndex]
        MediaContentView.tempIndex += 1
    }
}
