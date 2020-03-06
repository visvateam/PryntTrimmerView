//
//  PryntTrimmerView.swift
//  PryntTrimmerView
//
//  Created by HHK on 27/03/2017.
//  Copyright © 2017 Prynt. All rights reserved.
//

import AVFoundation
import UIKit

public protocol TrimmerViewDelegate: class {
    func didChangePositionBar(_ playerTime: CMTime)
    func positionBarStoppedMoving(_ playerTime: CMTime)
}

/// A view to select a specific time range of a video. It consists of an asset preview with thumbnails inside a scroll view, two
/// handles on the side to select the beginning and the end of the range, and a position bar to synchronize the control with a
/// video preview, typically with an `AVPlayer`.
/// Load the video by setting the `asset` property. Access the `startTime` and `endTime` of the view to get the selected time
// range
@IBDesignable public class TrimmerView: AVAssetTimeSelector {

    // MARK: - Properties

    // MARK: Color Customization

    /// The color of the main border of the view
    @IBInspectable public var mainColor: UIColor = UIColor.gray {
        didSet {
            updateMainColor()
        }
    }

    /// The color of the handles on the side of the view
    @IBInspectable public var handleColor: UIColor = UIColor.gray {
        didSet {
           updateHandleColor()
        }
    }

    /// The color of the position indicator
    @IBInspectable public var positionBarColor: UIColor = UIColor.white {
        didSet {
            positionBar.backgroundColor = positionBarColor
        }
    }

    /// The color used to mask unselected parts of the video
    @IBInspectable public var maskColor: UIColor = UIColor.white {
        didSet {
            leftMaskView.backgroundColor = maskColor
            rightMaskView.backgroundColor = maskColor
        }
    }

    // MARK: Interface

    public weak var delegate: TrimmerViewDelegate?

    // MARK: Subviews

    private let trimView = UIView()
    private let leftHandleView = HandlerView()
    private let rightHandleView = HandlerView()
    private let positionBar = UIView()
    private let leftHandleKnob = UIView()
    private let rightHandleKnob = UIView()
    private let leftMaskView = UIView()
    private let rightMaskView = UIView()

    // MARK: Constraints

    private var currentLeftConstraint: CGFloat = 0
    private var currentRightConstraint: CGFloat = 0
    private var leftConstraint: NSLayoutConstraint?
    private var rightConstraint: NSLayoutConstraint?
    private var positionConstraint: NSLayoutConstraint?

    private let handleWidth: CGFloat = 15

    /// The minimum duration allowed for the trimming. The handles won't pan further if the minimum duration is attained.
    public var minDuration: Double = 3
    /// The maximum duration allowed for the trimming. Both handles will translate equally  if the  maximum duration  is attained.
    public var maxDuration: Double = 60

    // MARK: - View & constraints configurations

    override func setupSubviews() {
        super.setupSubviews()
        layer.cornerRadius = 2
        layer.masksToBounds = true
        backgroundColor = UIColor.clear
        layer.zPosition = 1
        setupTrimmerView()
        setupHandleView()
        setupMaskView()
        setupPositionBar()
        setupGestures()
        updateMainColor()
        updateHandleColor()
    }

    override func constrainAssetPreview() {
        assetPreview.leftAnchor.constraint(equalTo: leftAnchor, constant: handleWidth).isActive = true
        assetPreview.rightAnchor.constraint(equalTo: rightAnchor, constant: -handleWidth).isActive = true
        assetPreview.topAnchor.constraint(equalTo: topAnchor).isActive = true
        assetPreview.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
    }

    private func setupTrimmerView() {
        trimView.layer.borderWidth = 2.0
        trimView.layer.cornerRadius = 2.0
        trimView.translatesAutoresizingMaskIntoConstraints = false
        trimView.isUserInteractionEnabled = false
        addSubview(trimView)

        trimView.topAnchor.constraint(equalTo: topAnchor).isActive = true
        trimView.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
        leftConstraint = trimView.leftAnchor.constraint(equalTo: leftAnchor)
        rightConstraint = trimView.rightAnchor.constraint(equalTo: rightAnchor)
        leftConstraint?.isActive = true
        rightConstraint?.isActive = true
    }

    private func setupHandleView() {

        leftHandleView.isUserInteractionEnabled = true
        leftHandleView.layer.cornerRadius = 2.0
        leftHandleView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(leftHandleView)

        leftHandleView.heightAnchor.constraint(equalTo: heightAnchor).isActive = true
        leftHandleView.widthAnchor.constraint(equalToConstant: handleWidth).isActive = true
        leftHandleView.leftAnchor.constraint(equalTo: trimView.leftAnchor).isActive = true
        leftHandleView.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true

        leftHandleKnob.translatesAutoresizingMaskIntoConstraints = false
        leftHandleView.addSubview(leftHandleKnob)

        leftHandleKnob.heightAnchor.constraint(equalTo: heightAnchor, multiplier: 0.5).isActive = true
        leftHandleKnob.widthAnchor.constraint(equalToConstant: 2).isActive = true
        leftHandleKnob.centerYAnchor.constraint(equalTo: leftHandleView.centerYAnchor).isActive = true
        leftHandleKnob.centerXAnchor.constraint(equalTo: leftHandleView.centerXAnchor).isActive = true

        rightHandleView.isUserInteractionEnabled = true
        rightHandleView.layer.cornerRadius = 2.0
        rightHandleView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(rightHandleView)

        rightHandleView.heightAnchor.constraint(equalTo: heightAnchor).isActive = true
        rightHandleView.widthAnchor.constraint(equalToConstant: handleWidth).isActive = true
        rightHandleView.rightAnchor.constraint(equalTo: trimView.rightAnchor).isActive = true
        rightHandleView.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true

        rightHandleKnob.translatesAutoresizingMaskIntoConstraints = false
        rightHandleView.addSubview(rightHandleKnob)

        rightHandleKnob.heightAnchor.constraint(equalTo: heightAnchor, multiplier: 0.5).isActive = true
        rightHandleKnob.widthAnchor.constraint(equalToConstant: 2).isActive = true
        rightHandleKnob.centerYAnchor.constraint(equalTo: rightHandleView.centerYAnchor).isActive = true
        rightHandleKnob.centerXAnchor.constraint(equalTo: rightHandleView.centerXAnchor).isActive = true
    }

    private func setupMaskView() {

        leftMaskView.isUserInteractionEnabled = false
        leftMaskView.backgroundColor = .white
        leftMaskView.alpha = 0.7
        leftMaskView.translatesAutoresizingMaskIntoConstraints = false
        insertSubview(leftMaskView, belowSubview: leftHandleView)

        leftMaskView.leftAnchor.constraint(equalTo: leftAnchor).isActive = true
        leftMaskView.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
        leftMaskView.topAnchor.constraint(equalTo: topAnchor).isActive = true
        leftMaskView.rightAnchor.constraint(equalTo: leftHandleView.centerXAnchor).isActive = true

        rightMaskView.isUserInteractionEnabled = false
        rightMaskView.backgroundColor = .white
        rightMaskView.alpha = 0.7
        rightMaskView.translatesAutoresizingMaskIntoConstraints = false
        insertSubview(rightMaskView, belowSubview: rightHandleView)

        rightMaskView.rightAnchor.constraint(equalTo: rightAnchor).isActive = true
        rightMaskView.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
        rightMaskView.topAnchor.constraint(equalTo: topAnchor).isActive = true
        rightMaskView.leftAnchor.constraint(equalTo: rightHandleView.centerXAnchor).isActive = true
    }

    private func setupPositionBar() {

        positionBar.frame = CGRect(x: 0, y: 0, width: 3, height: frame.height)
        positionBar.backgroundColor = positionBarColor
        positionBar.center = CGPoint(x: leftHandleView.frame.maxX, y: center.y)
        positionBar.layer.cornerRadius = 1
        positionBar.translatesAutoresizingMaskIntoConstraints = false
        positionBar.isUserInteractionEnabled = false
        addSubview(positionBar)

        positionBar.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
        positionBar.widthAnchor.constraint(equalToConstant: 3).isActive = true
        positionBar.heightAnchor.constraint(equalTo: heightAnchor).isActive = true
        positionConstraint = positionBar.leftAnchor.constraint(equalTo: leftHandleView.rightAnchor, constant: 0)
        positionConstraint?.isActive = true
    }

    private func setupGestures() {

        let leftPanGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(TrimmerView.handlePanGesture))
        leftHandleView.addGestureRecognizer(leftPanGestureRecognizer)
        let rightPanGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(TrimmerView.handlePanGesture))
        rightHandleView.addGestureRecognizer(rightPanGestureRecognizer)
        let seekGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(TrimmerView.handleSeekGesture))
        assetPreview.addGestureRecognizer(seekGestureRecognizer)

    }

    private func updateMainColor() {
        trimView.layer.borderColor = mainColor.cgColor
        leftHandleView.backgroundColor = mainColor
        rightHandleView.backgroundColor = mainColor
    }

    private func updateHandleColor() {
        leftHandleKnob.backgroundColor = handleColor
        rightHandleKnob.backgroundColor = handleColor
    }

    // MARK: - Trim Gestures

    @objc func handlePanGesture(_ gestureRecognizer: UIPanGestureRecognizer) {
        guard let view = gestureRecognizer.view, let superView = gestureRecognizer.view?.superview else { return }
        let isLeftGesture = view == leftHandleView
        switch gestureRecognizer.state {

        case .began:
            currentLeftConstraint = leftConstraint!.constant
            currentRightConstraint = rightConstraint!.constant
            updateSelectedTime(stoppedMoving: false)
        case .changed:
            let translation = gestureRecognizer.translation(in: superView)
            if isLeftGesture {
                updateLeftConstraint(with: translation)
            } else {
                updateRightConstraint(with: translation)
            }
            layoutIfNeeded()
            if let startTime = startTime, isLeftGesture {
                seek(to: startTime)
            } else if let endTime = endTime {
                seek(to: endTime)
            }
            updateSelectedTime(stoppedMoving: false)
        case .cancelled, .ended, .failed:
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                self.updateHandleConstraints(isLeftHandle: isLeftGesture)
                self.updateSelectedTime(stoppedMoving: true)
            }
        default: break
        }
    }

    @objc func handleSeekGesture(_ seekGestureRecognizer: UIPanGestureRecognizer) {
        let location = seekGestureRecognizer.location(in: trimView)
        updatePositionBar(with: location)
    }

    private func updateLeftConstraint(with translation: CGPoint) {
        let maxConstraint = max(rightHandleView.frame.origin.x - handleWidth - minimumDistanceBetweenHandle, 0)
        let newLeftConstraint = min(max(0, currentLeftConstraint + translation.x), maxConstraint)
        leftConstraint?.constant = newLeftConstraint

        updateHandleConstraints(isLeftHandle: true)

        layoutIfNeeded()
    }

    private func updateRightConstraint(with translation: CGPoint) {
        let maxConstraint = min(2 * handleWidth - frame.width + leftHandleView.frame.origin.x + minimumDistanceBetweenHandle, 0)
        let newRightConstraint = max(min(0, currentRightConstraint + translation.x), maxConstraint)
        rightConstraint?.constant = newRightConstraint

        updateHandleConstraints(isLeftHandle: false)

        layoutIfNeeded()
    }

    private func updateHandleConstraints(isLeftHandle leftHandle: Bool) {
        guard let asset = asset,
            asset.duration.seconds >  maxDuration,
            let endTime = endTime?.seconds,
            let startTime = startTime?.seconds,
            (endTime - startTime) > maxDuration
        else { return }

        if leftHandle {
            guard let endPosition = getPosition(from: CMTime(seconds: startTime + maxDuration,
                                                             preferredTimescale: asset.duration.timescale)) else { return }
            rightConstraint?.constant = 0 - assetPreview.contentView.frame.width + endPosition
        } else {
            guard let startPosition = getPosition(from: CMTime(seconds: endTime - maxDuration,
                                                               preferredTimescale: asset.duration.timescale)) else { return }
            leftConstraint?.constant = startPosition
        }
    }

    private func updatePositionBar(with location: CGPoint) {
        guard location.x > 0 && location.x < trimView.frame.width - (2 * rightHandleView.frame.width) else { return }

        positionConstraint?.constant = location.x

        layoutIfNeeded()

        guard let positionBarTime = positionBarTime else { return }

        seek(to: positionBarTime)
        updateSelectedTime(stoppedMoving: false)
    }

    // MARK: - Asset loading

    override func assetDidChange(newAsset: AVAsset?) {
        super.assetDidChange(newAsset: newAsset)
        resetHandleViewPosition()
    }

    private func resetHandleViewPosition() {
        leftConstraint?.constant = 0
        rightConstraint?.constant = 0

        guard let asset = asset, asset.duration.seconds > maxDuration,
        let position = getPosition(from: CMTime(seconds: maxDuration, preferredTimescale: asset.duration.timescale)) else { return }

        rightConstraint?.constant = 0 - assetPreview.contentView.frame.width + position
    }

    // MARK: - Time Equivalence

    /// Move the position bar to the given time.
    public func seek(to time: CMTime) {
        if let newPosition = getPosition(from: time) {

            let offsetPosition = newPosition - assetPreview.contentOffset.x - leftHandleView.frame.origin.x
            let maxPosition = rightHandleView.frame.origin.x - (leftHandleView.frame.origin.x + handleWidth)
                              - positionBar.frame.width
            let normalizedPosition = min(max(0, offsetPosition), maxPosition)
            positionConstraint?.constant = normalizedPosition
            layoutIfNeeded()
        }
    }

    /// The selected start time for the current asset.
    public var startTime: CMTime? {
        let startPosition = leftHandleView.frame.origin.x + assetPreview.contentOffset.x
        return getTime(from: startPosition)
    }

    /// The selected end time for the current asset.
    public var endTime: CMTime? {
        let endPosition = rightHandleView.frame.origin.x + assetPreview.contentOffset.x - handleWidth
        return getTime(from: endPosition)
    }

    private func updateSelectedTime(stoppedMoving: Bool) {
        guard let playerTime = positionBarTime else {
            return
        }
        if stoppedMoving {
            delegate?.positionBarStoppedMoving(playerTime)
        } else {
            delegate?.didChangePositionBar(playerTime)
        }
    }

    private var positionBarTime: CMTime? {
        let barPosition = positionBar.frame.origin.x + assetPreview.contentOffset.x - handleWidth
        return getTime(from: barPosition)
    }

    private var minimumDistanceBetweenHandle: CGFloat {
        guard let asset = asset else { return 0 }
        return CGFloat(minDuration) * assetPreview.contentView.frame.width / CGFloat(asset.duration.seconds)
    }

    private var maximumDistanceBetweenHandle: CGFloat {
        guard let asset = asset else { return 0 }
        return CGFloat(maxDuration) * assetPreview.contentView.frame.width / CGFloat(asset.duration.seconds)
    }

    // MARK: - Scroll View Delegate

    public func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        updateSelectedTime(stoppedMoving: true)
    }

    public func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if !decelerate {
            updateSelectedTime(stoppedMoving: true)
        }
    }
    public func scrollViewDidScroll(_ scrollView: UIScrollView) {
        updateSelectedTime(stoppedMoving: false)
    }
}
