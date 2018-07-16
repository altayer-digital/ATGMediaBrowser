//
//  ContentTransformers.swift
//  ATGMediaBrowser
//
//  Created by Suraj Thomas K on 7/17/18.
//  Copyright © 2018 Al Tayer Group LLC. All rights reserved.
//
//  Save to the extent permitted by law, you may not use, copy, modify,
//  distribute or create derivative works of this material or any part
//  of it without the prior written consent of Al Tayer Group LLC.
//  Any reproduction of this material must contain this notice.
//

public typealias ContentTransformer = (UIView, CGFloat) -> Void

// MARK: - Default Transitions

public enum DefaultContentTransformers {

    // GestureDirection : Horizontal
    // DrawOrder : Any
    public static let horizontalMoveInOut: ContentTransformer = { contentView, position in

        let widthIncludingGap = contentView.bounds.size.width + MediaContentView.interItemSpacing
        contentView.transform = CGAffineTransform(translationX: widthIncludingGap * position, y: 0.0)
    }

    // GestureDirection : Vertical
    // DrawOrder : Any
    public static let verticalMoveInOut: ContentTransformer = { contentView, position in

        let heightIncludingGap = contentView.bounds.size.height + MediaContentView.interItemSpacing
        contentView.transform = CGAffineTransform(translationX: 0.0, y: heightIncludingGap * position)
    }

    // GestureDirection : Horizontal
    // DrawOrder : PreviousToNext
    public static let horizontalSlideOut: ContentTransformer = { contentView, position in

        var scale: CGFloat = 1.0
        if position < -0.5 {
            scale = 0.9
        } else if -0.5...0.0 ~= Double(position) {
            scale = 1.0 + (position * 0.2)
        }
        var transform = CGAffineTransform(scaleX: scale, y: scale)

        let widthIncludingGap = contentView.bounds.size.width + MediaContentView.interItemSpacing
        let x = position >= 0.0 ? widthIncludingGap * position : 0.0
        transform = transform.translatedBy(x: x, y: 0.0)

        contentView.transform = transform

        let margin: CGFloat = 0.0000001
        contentView.isHidden = ((1.0-margin)...(1.0+margin) ~= abs(position))
    }
}
