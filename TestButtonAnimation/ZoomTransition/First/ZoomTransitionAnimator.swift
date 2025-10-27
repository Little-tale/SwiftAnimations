//
//  ZoomTransitionAnimator.swift
//  TestButtonAnimation
//
//  Created by Jae hyung Kim on 10/27/25.
//

import UIKit

protocol ZoomTransitionable: NSObject {
    /// 확대/축소의 기준이 되는 뷰
    var zoomSourceView: UIView? { get }
}

final class ZoomTransitionAnimator: NSObject, UIViewControllerAnimatedTransitioning {
    enum Op { case push, pop }
    let op: Op
    init(op: Op) { self.op = op }

    func transitionDuration(using _: UIViewControllerContextTransitioning?) -> TimeInterval { 0.35 }

    func animateTransition(using ctx: UIViewControllerContextTransitioning) {
        let container = ctx.containerView
        guard
            let fromVC = ctx.viewController(forKey: .from) as? (UIViewController & ZoomTransitionable),
            let toVC   = ctx.viewController(forKey: .to)   as? (UIViewController & ZoomTransitionable)
        else { ctx.completeTransition(false); return }

        // 배치
        toVC.view.frame = ctx.finalFrame(for: toVC)
        toVC.view.layoutIfNeeded()
        if op == .push {
            toVC.view.alpha = 0
            container.addSubview(toVC.view)
        } else {
            container.insertSubview(toVC.view, belowSubview: fromVC.view)
        }

        // push/pop 모두 fromVC → toVC 기준
        guard
            let fromView = fromVC.zoomSourceView,
            let toView   = toVC.zoomSourceView,
            let snapshot = fromView.snapshotView(afterScreenUpdates: false)
        else { ctx.completeTransition(false); return }

        let start = container.convert(fromView.bounds, from: fromView)
        let end   = container.convert(toView.bounds,   from: toView)

        let startRadius = fromView.layer.cornerRadius
        let endRadius   = toView.layer.cornerRadius

        snapshot.frame = start
        snapshot.layer.masksToBounds = true
        snapshot.layer.cornerRadius = startRadius
        container.addSubview(snapshot)
        fromView.isHidden = true
        toView.isHidden = true

        let dur = transitionDuration(using: ctx)
        UIView.animate(withDuration: dur, delay: 0, options: .curveEaseInOut, animations: {
            if self.op == .push { toVC.view.alpha = 1 } else { fromVC.view.alpha = 0 }
            snapshot.frame = end
            snapshot.layer.cornerRadius = endRadius
        }, completion: { _ in
            fromView.isHidden = false
            toView.isHidden = false
            snapshot.removeFromSuperview()
            fromVC.view.alpha = 1
            toVC.view.alpha = 1
            ctx.completeTransition(!ctx.transitionWasCancelled)
        })
    }

}


final class ZoomInteractivePop: UIPercentDrivenInteractiveTransition {
    private weak var nav: UINavigationController?
    private(set) var isActive = false

    init(navigationController: UINavigationController, attachTo view: UIView) {
        self.nav = navigationController
        super.init()
        let edge = UIScreenEdgePanGestureRecognizer(target: self, action: #selector(handle(_:)))
        edge.edges = .left
        view.addGestureRecognizer(edge)
    }

    @objc private func handle(_ g: UIScreenEdgePanGestureRecognizer) {
        guard let v = g.view else { return }
        let p = max(0, min(1, g.translation(in: v).x / v.bounds.width))
        switch g.state {
        case .began:
            isActive = true
            nav?.popViewController(animated: true)
        case .changed:
            update(p)
        case .ended, .cancelled:
            (p > 0.35 || g.velocity(in: v).x > 800) ? finish() : cancel()
            isActive = false
        default: break
        }
    }
}

final class ZoomNavDelegate: NSObject, UINavigationControllerDelegate {
    var interactivePop: ZoomInteractivePop?

    func navigationController(_ nav: UINavigationController,
                              animationControllerFor operation: UINavigationController.Operation,
                              from fromVC: UIViewController,
                              to toVC: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        switch operation {
        case .push: return ZoomTransitionAnimator(op: .push)
        case .pop:  return ZoomTransitionAnimator(op: .pop)
        default:    return nil
        }
    }

    func navigationController(_ nav: UINavigationController,
                              interactionControllerFor animationController: UIViewControllerAnimatedTransitioning)
    -> UIViewControllerInteractiveTransitioning? {
        (interactivePop?.isActive == true) ? interactivePop : nil
    }
}

