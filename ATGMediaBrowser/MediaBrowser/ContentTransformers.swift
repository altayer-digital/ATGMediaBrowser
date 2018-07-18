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

/**
 Content transformer used for transition between media item views.

 - parameter contentView: The content view on which transform corresponding to the position has to be applied.
 - parameter position: Current position for the passed content view.

 - note:
    The trasnform to be applied on the contentView has to be dependent on the position passed.
    The position value can be -ve, 0.0 or positive.

    Try to visualize content views at -1.0[previous]=>0.0[current]=>1.0[next].

    1. When position is -1.0, the content view should be at the place meant for previous view.

    2. When the position is 0.0, the transform applied on the content view should make it visible full screen at origin.

    3. When position is 1.0, the content view should be at the place meant for next view.

    Be mindful of the drawing order, when designing new transitions.
 */
public typealias ContentTransformer = (_ contentView: UIView, _ position: CGFloat) -> Void

// MARK: - Default Transitions

/// An enumeration to hold default content transformers
public enum DefaultContentTransformers {

    /**
     Horizontal move-in-out content transformer.

     - Requires:
         * GestureDirection: Horizontal
    */
    public static let horizontalMoveInOut: ContentTransformer = { contentView, position in

        let widthIncludingGap = contentView.bounds.size.width + MediaContentView.interItemSpacing
        contentView.transform = CGAffineTransform(translationX: widthIncludingGap * position, y: 0.0)
    }

    /**
     Vertical move-in-out content transformer.

     - Requires:
        * GestureDirection: Vertical
     */
    public static let verticalMoveInOut: ContentTransformer = { contentView, position in

        let heightIncludingGap = contentView.bounds.size.height + MediaContentView.interItemSpacing
        contentView.transform = CGAffineTransform(translationX: 0.0, y: heightIncludingGap * position)
    }

    /**
     Horizontal slide-out content transformer.

     - Requires:
        * GestureDirection: Horizontal
        * DrawOrder: PreviousToNext
     */
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

    /**
     Vertical slide-out content transformer.

     - Requires:
         * GestureDirection: Vertical
         * DrawOrder: PreviousToNext
     */
    public static let verticalSlideOut: ContentTransformer = { contentView, position in

        var scale: CGFloat = 1.0
        if position < -0.5 {
            scale = 0.9
        } else if -0.5...0.0 ~= Double(position) {
            scale = 1.0 + (position * 0.2)
        }
        var transform = CGAffineTransform(scaleX: scale, y: scale)

        let heightIncludingGap = contentView.bounds.size.height + MediaContentView.interItemSpacing
        let y = position >= 0.0 ? heightIncludingGap * position : 0.0
        transform = transform.translatedBy(x: 0.0, y: y)

        contentView.transform = transform

        let margin: CGFloat = 0.0000001
        contentView.isHidden = ((1.0-margin)...(1.0+margin) ~= abs(position))
    }

    /**
     Horizontal slide-in content transformer.

     - Requires:
         * GestureDirection: Horizontal
         * DrawOrder: NextToPrevious
     */
    public static let horizontalSildeIn: ContentTransformer = { contentView, position in

        var scale: CGFloat = 1.0
        if position > 0.5 {
            scale = 0.9
        } else if 0.0...0.5 ~= Double(position) {
            scale = 1.0 - (position * 0.2)
        }
        var transform = CGAffineTransform(scaleX: scale, y: scale)

        let widthIncludingGap = contentView.bounds.size.width + MediaContentView.interItemSpacing
        let x = position > 0.0 ? 0.0 : widthIncludingGap * position
        transform = transform.translatedBy(x: x, y: 0.0)

        contentView.transform = transform

        let margin: CGFloat = 0.0000001
        contentView.isHidden = ((1.0-margin)...(1.0+margin) ~= abs(position))
    }

    /**
     Vertical slide-in content transformer.

     - Requires:
         * GestureDirection: Vertical
         * DrawOrder: NextToPrevious
     */
    public static let verticalSlideIn: ContentTransformer = { contentView, position in

        var scale: CGFloat = 1.0
        if position > 0.5 {
            scale = 0.9
        } else if 0.0...0.5 ~= Double(position) {
            scale = 1.0 - (position * 0.2)
        }
        var transform = CGAffineTransform(scaleX: scale, y: scale)

        let heightIncludingGap = contentView.bounds.size.height + MediaContentView.interItemSpacing
        let y = position > 0.0 ? 0.0 : heightIncludingGap * position
        transform = transform.translatedBy(x: 0.0, y: y)

        contentView.transform = transform

        let margin: CGFloat = 0.0000001
        contentView.isHidden = ((1.0-margin)...(1.0+margin) ~= abs(position))
    }
}
