//
//  BottomPresentationController.swift
//  THK-IM-IOS
//
//  Created by vizoss on 2024/1/20.
//  Copyright © 2024 THK. All rights reserved.
//

import UIKit

class BottomPresentationController: UIPresentationController {

    private var dimmingView: UIView!

    override init(
        presentedViewController: UIViewController,
        presenting presentingViewController: UIViewController?
    ) {
        super.init(
            presentedViewController: presentedViewController, presenting: presentingViewController)
        setupDimmingView()
    }

    private func setupDimmingView() {
        dimmingView = UIView()
        dimmingView.translatesAutoresizingMaskIntoConstraints = false
        dimmingView.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        dimmingView.alpha = 0.0

        let tapGestureRecognizer = UITapGestureRecognizer(
            target: self, action: #selector(dimmingViewTapped(_:)))
        dimmingView.addGestureRecognizer(tapGestureRecognizer)
    }

    @objc private func dimmingViewTapped(_ tapRecognizer: UITapGestureRecognizer) {
        presentingViewController.dismiss(animated: true)
    }

    override func presentationTransitionWillBegin() {
        guard let containerView = containerView else { return }

        containerView.insertSubview(dimmingView, at: 0)
        NSLayoutConstraint.activate([
            dimmingView.topAnchor.constraint(equalTo: containerView.topAnchor),
            dimmingView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),
            dimmingView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            dimmingView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
        ])

        // 利用转场协调器为背景遮罩添加淡入效果
        guard let transitionCoordinator = presentedViewController.transitionCoordinator else {
            dimmingView.alpha = 1.0
            return
        }

        transitionCoordinator.animate(alongsideTransition: { _ in
            self.dimmingView.alpha = 1.0
        })
    }

    override func dismissalTransitionDidEnd(_ completed: Bool) {
        if completed {
            dimmingView.removeFromSuperview()
        }
    }

    override var frameOfPresentedViewInContainerView: CGRect {
        guard let containerView = containerView else { return .zero }
        return CGRect(
            x: 0, y: containerView.bounds.height / 2,
            width: containerView.bounds.width, height: containerView.bounds.height / 2)
    }

    override func containerViewWillLayoutSubviews() {
        super.containerViewWillLayoutSubviews()
        presentedView?.frame = frameOfPresentedViewInContainerView
    }
}
