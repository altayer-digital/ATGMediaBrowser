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

    public static let horizontalMoveInOut: ContentTransformer = { contentView, position in

        let widthIncludingGap = contentView.frame.size.width + MediaContentView.interItemSpacing
        contentView.transform = CGAffineTransform(translationX: widthIncludingGap * position, y: 0.0)
    }

    public static let verticalMoveInOut: ContentTransformer = { contentView, position in

        let heightIncludingGap = contentView.frame.size.height + MediaContentView.interItemSpacing
        contentView.transform = CGAffineTransform(translationX: 0.0, y: heightIncludingGap * position)
    }
}
