//
//  ZoomTransition.swift
//  TestButtonAnimation
//
//  Created by Jae hyung Kim on 10/27/25.
//

import UIKit

final class CustomZoomTransition: NSObject, UINavigationControllerDelegate {
    private let config: CustomZoomTransitionConfiguration
    private weak var referenceView: UIView?
    private let presentingTransitionAnimator: CustomPresentingTransitionAnimator
    private let dismissalTransitionAnimator: CustomDismissalTransitionAnimator
    private var presentationController: UIPresentationController?
    private var currentTranslationY: CGFloat = 0
    private var originalCenter: CGPoint = .zero
    private var originalAnchor: CGPoint = .zero
    private var ended: (() -> Void)

    // MARK: - Initializers

    init(
        referenceView: UIView,
        config: CustomZoomTransitionConfiguration = CustomZoomTransitionConfiguration(),
        ended: @escaping () -> Void
    ) {
        self.referenceView = referenceView
        self.config = config
        self.ended = ended

        presentingTransitionAnimator = CustomPresentingTransitionAnimator(
            config: config,
            referenceView: referenceView
        )
        
        dismissalTransitionAnimator = CustomDismissalTransitionAnimator(
            config: config,
            referenceView: referenceView,
        )
    }
    
    func navigationController(_ navigationController: UINavigationController, animationControllerFor operation: UINavigationController.Operation, from fromVC: UIViewController, to toVC: UIViewController) -> (any UIViewControllerAnimatedTransitioning)? {
        switch operation {
        case .push:
            return presentingTransitionAnimator
        case .pop:
            return dismissalTransitionAnimator
        default:
            return nil
        }
    }
    
    deinit {
        print("** DEAD \(Self.description())")
    }
}

// MARK: - UIViewControllerTransitioningDelegate 구현

extension CustomZoomTransition: UIViewControllerTransitioningDelegate {
    
    /// 프레젠트 시 사용할 애니메이터 객체를 반환
    func animationController(
        forPresented presented: UIViewController,
        presenting: UIViewController,
        source: UIViewController
    ) -> UIViewControllerAnimatedTransitioning? {
        print("\(#function)")
        referenceView?.alpha = 0
        return presentingTransitionAnimator
    }

    /// 디스미스 시 사용할 애니메이터 객체를 반환
    func animationController(
        forDismissed dismissed: UIViewController
    ) -> UIViewControllerAnimatedTransitioning? {
        print("\(#function)")
        return dismissalTransitionAnimator
    }

    /// 프레젠트 시 인터랙티브 애니메이터(제스처 기반)를 제공할지 여부를 반환 (현재 사용 안 함)
    func interactionControllerForPresentation(
        using animator: UIViewControllerAnimatedTransitioning
    ) -> UIViewControllerInteractiveTransitioning? {
        print("\(#function)")
        return nil
    }

    /// 디스미스 시 인터랙티브 애니메이터(제스처 기반)를 반환
    func interactionControllerForDismissal(
        using animator: UIViewControllerAnimatedTransitioning
    ) -> UIViewControllerInteractiveTransitioning? {
        print("\(#function)")
        DispatchQueue.main.asyncAfter(deadline: .now() + config.transitionDuration) { [weak self] in
            self?.referenceView?.alpha = 1
            self?.ended()
        }
        return dismissalTransitionAnimator
    }

    /// 프레젠트 시 뷰 계층을 관리하는 프레젠테이션 컨트롤러를 반환.
    func presentationController(
        forPresented presented: UIViewController,
        presenting: UIViewController?,
        source: UIViewController
    ) -> UIPresentationController? {
        print("\(#function)")
        let presentationController = UIPresentationController(
            presentedViewController: presented,
            presenting: source
        )
        let panGestureRecognizer = UIPanGestureRecognizer(
            target: self,
            action: #selector(handlePanGesture(_:))
        )

        presented.view.addGestureRecognizer(panGestureRecognizer)

        self.presentationController = presentationController

        return presentationController
    }

    // MARK: - 제스처 처리
    /// 프레젠트된 화면에서 팬 제스처를 감지해 이동/알파/디스미스를 제어
    @objc
    private func handlePanGesture(_ gesture: UIPanGestureRecognizer) {
        guard let presentedVC = presentationController?.presentedViewController,
              let container = presentedVC.view.superview else {
            return
        }

        guard let targetView = presentedVC.view else { return }

        switch gesture.state {
        case .began:
            targetView.layer.cornerRadius = 45
            // 1) 기존 뷰의 중앙, 포인트를 저장
            originalCenter = targetView.center
            originalAnchor = targetView.layer.anchorPoint

            // 2) 터치 지점을 뷰 좌표로
            let touchInView = gesture.location(in: targetView)

            // 3) anchorPoint로 바꿀 비율 (0~1)
            let newAnchor = CGPoint(
                x: touchInView.x / targetView.bounds.width,
                y: touchInView.y / targetView.bounds.height
            )
            // 0.5, 0.5 (중심) --> 드래그 앵커
            targetView.layer.anchorPoint = newAnchor
            
            // 4) anchorPoint를 바꾸면 position이 바뀌어버리니, 그만큼 보정
            let oldPos = targetView.layer.position
            print("began - oldPos: ", oldPos) // began - oldPos:  (220.0, 478.0)
            print("began - originalAnchor", originalAnchor) // began - originalAnchor (0.5, 0.5)
            print("began - newAnchor", newAnchor) // began - newAnchor (0.02727272727272727, 0.3158995815899582)
            
            let moveX = (newAnchor.x - originalAnchor.x) // 기준점x 0.47..만큼 왼쪽으로
            let moveY = (newAnchor.y - originalAnchor.y) // 기준점y 0.19..만큼 위로
            
            // px 로 전환
            let moveXPx = moveX * targetView.bounds.width
            let moveYPx = moveY * targetView.bounds.height
            
            let newPos = CGPoint(
                x: oldPos.x + moveXPx,
                y: oldPos.y + moveYPx
            )
            
            targetView.layer.position = newPos

        case .changed:
            let translation = gesture.translation(in: container)
            let dx = translation.x
            let dy = translation.y

            // 전체 이동 거리 (피타고라스)
            let distance = hypot(dx, dy)

            // 얼마나 줄일지
            let maxDrag: CGFloat = 300
            let progress = min(distance / maxDrag, 1)

            let minScale: CGFloat = 0.4
            let scale = 1 - (1 - minScale) * progress

            let scaleTransform = CGAffineTransform(scaleX: scale, y: scale)
            let translateTransform = CGAffineTransform(translationX: dx, y: dy)
            targetView.transform = scaleTransform.concatenating(translateTransform)

            // 투명도도 전체 거리 기준
            targetView.alpha = 1 - 0.4 * progress

        case .ended, .cancelled:
            // 원래대로
            let shouldDismiss = targetView.transform.ty > 150
            if shouldDismiss {
                presentedVC.dismiss(animated: true)
            } else {
                UIView.animate(withDuration: 0.2, animations: { [weak self] in
                    guard let weakSelf = self else { return }
                    targetView.transform = .identity
                    targetView.alpha = 1
                    // anchorPoint도 원래대로
                    targetView.layer.anchorPoint = weakSelf.originalAnchor
                    targetView.center = weakSelf.originalCenter
                    targetView.layer.cornerRadius = 0
                })
            }

        default:
            break
        }
    }
    
    // MARK: - 유틸리티
    /// 팬 제스처의 이동량(양축)을 기반으로 알파 값을 계산합니다.
    /// - 이동 거리 0일 때: 1.0
    /// - 이동 거리가 `alphaRangeDistance` 이상일 때: `minAlphaDuringPan`
    /// - 그 사이 구간은 선형으로 감소합니다.
    func getAlpha(for translation: CGPoint) -> CGFloat {
        let distance = hypot(translation.x, translation.y) // 루트(x^2 + y^2)
        guard config.alphaRangeDistance > 0 else { return 1.0 }
        let clamp = min(max(distance / config.alphaRangeDistance, 0), 1)
        let alpha = 1.0 - clamp * (1.0 - config.minAlphaDuringPan)
        return CGFloat(alpha)
    }
}


final class CustomPresentingTransitionAnimator: NSObject {
    private let config: CustomZoomTransitionConfiguration
    private let referenceView: UIView
    private var transitionContext: UIViewControllerContextTransitioning?

    // MARK: - 초기화
    init(config: CustomZoomTransitionConfiguration, referenceView: UIView) {
        self.config = config
        self.referenceView = referenceView
    }
}

// MARK: - UIViewControllerAnimatedTransitioning 구현

extension CustomPresentingTransitionAnimator: UIViewControllerAnimatedTransitioning {
    
    /// 프레젠트 전환에 소요되는 총 시간을 반환
    func transitionDuration(
        using transitionContext: UIViewControllerContextTransitioning?
    ) -> TimeInterval {
        print("\(#function)")
        return config.transitionDuration
    }

    /// 버튼 위치/ 크기에서 시작해 화면 전체로 확대되는 프레젠트 애니메이션.
    func animateTransition(
        using transitionContext: UIViewControllerContextTransitioning
    ) {
        print("\(#function)")
        // 이번에 나타나야 하는 뷰컨 받기
        guard let presentedViewController = transitionContext.viewController(forKey: .to) else {
            return
        }

        self.transitionContext = transitionContext

        let containerView = transitionContext.containerView

        // 배경 디밍 뷰를 준비하고 컨테이너에 추가
        let backgroundView = makeBackgroundView(in: containerView)

        // 최종 프레임과 버튼(referenceView)의 시작 프레임을 계산
        let finalFrame = containerView.bounds
        let refFrameInContainer = containerView.convert(referenceView.bounds, from: referenceView)

        // 프레젠트될 뷰를 초기 상태(작게/버튼 위치)로 설정
        let presentedView = presentedViewController.view!
        preparePresentedView(presentedView,
                             finalFrame: finalFrame,
                             refFrameInContainer: refFrameInContainer)

        // 컨테이너에 프레젠트 뷰를 추가합니다(디밍 뷰 위).
        containerView.addSubview(presentedView)

        // 확대 애니메이션
        animatePresentation(backgroundView: backgroundView,
                            presentedView: presentedView,
                            finalFrame: finalFrame,
                            transitionContext: transitionContext)
    }

    /// 프레젠트 애니메이션 종료 시 호출됩니다.
    func animationEnded(_ transitionCompleted: Bool) {
        print("\(#function)")
        transitionContext = nil
    }
}

private extension CustomPresentingTransitionAnimator {
    
    /// 컨테이너에 디밍(배경) 뷰를 생성/추가하고 반환
    func makeBackgroundView(in containerView: UIView) -> UIView {
        let backgroundView = UIView(frame: containerView.bounds)
        backgroundView.backgroundColor = containerView.backgroundColor
        backgroundView.alpha = 0
        containerView.addSubview(backgroundView)
        return backgroundView
    }

    /// 프레젠트될 뷰를 버튼 위치/크기에서 시작하도록 초기 상태를 설정
    /// - 최종 프레임, 버튼 프레임을 기반으로 스케일/센터/코너 라운드를 구성
    func preparePresentedView(_ presentedView: UIView,
                              finalFrame: CGRect,
                              refFrameInContainer: CGRect) {
        // 최종 프레임을 기준으로 레이아웃 설정
        presentedView.frame = finalFrame

        // 확대/축소 중 코너 라운드가 잘 보이도록 마스킹 활성화
        presentedView.layer.masksToBounds = true
        let referenceCorner = referenceView.layer.cornerRadius

        // 버튼 대비 전체 화면의 스케일 비율 계산
        let minScale: CGFloat = 0.001 // 0 스케일 방지
        let scaleX = max(refFrameInContainer.width / max(finalFrame.width, 1), minScale)
        let scaleY = max(refFrameInContainer.height / max(finalFrame.height, 1), minScale)

        // 스케일 상태에서 버튼 코너와 유사하게 보이도록 초기 코너 보정
        let effectiveScale = max(min(scaleX, scaleY), 0.001)
        let initialCorner = referenceCorner / effectiveScale
        presentedView.layer.cornerRadius = initialCorner

        // 버튼 중심 위치에서 작게 시작하도록 설정
        presentedView.transform = CGAffineTransform(scaleX: scaleX, y: scaleY)
        presentedView.center = CGPoint(x: refFrameInContainer.midX, y: refFrameInContainer.midY)
    }

    /// 디밍 알파/스케일/센터/코너 라운드를 애니메이션하여 화면 전체로 확대
    func animatePresentation(backgroundView: UIView,
                             presentedView: UIView,
                             finalFrame: CGRect,
                             transitionContext: UIViewControllerContextTransitioning) {
        UIView.animate(
            withDuration: config.transitionDuration,
            delay: 0,
            usingSpringWithDamping: config.springWithDamping,
            initialSpringVelocity: config.initialSpringVelocity,
            options: [.beginFromCurrentState]
        ) {
            backgroundView.alpha = 1
            presentedView.transform = .identity
            presentedView.center = CGPoint(x: finalFrame.midX, y: finalFrame.midY)
            presentedView.layer.cornerRadius = 0
        } completion: { _ in
            backgroundView.removeFromSuperview()
            transitionContext.completeTransition(transitionContext.transitionWasCancelled == false)
        }
    }
}

final class CustomDismissalTransitionAnimator: NSObject {
    private let config: CustomZoomTransitionConfiguration
    private let referenceView: UIView

    // MARK: - 초기화
    init(config: CustomZoomTransitionConfiguration, referenceView: UIView) {
        self.config = config
        self.referenceView = referenceView
    }
}

// MARK: - UIViewControllerAnimatedTransitioning 구현
extension CustomDismissalTransitionAnimator: UIViewControllerAnimatedTransitioning {
    
    /// 디스미스 전환에 소요되는 총 시간을 반환
    func transitionDuration(
        using transitionContext: UIViewControllerContextTransitioning?
    ) -> TimeInterval {
        print("\(#function)")
        return config.transitionDuration
    }

    /// 인터랙티브 디스미스(모달방식)를 사용하므로 이 메서드에서는 별도 애니메이션을 수행하지 않습니다. 단, 네비게이션 방식에선 사용됩니다.
    func animateTransition(using ctx: UIViewControllerContextTransitioning) {
        // 네비 pop일 때 호출되는 곳
        guard
            let fromVC = ctx.viewController(forKey: .from),
            let toVC   = ctx.viewController(forKey: .to)
        else {
            ctx.completeTransition(false)
            return
        }
        
        let container = ctx.containerView
        // pop일 땐 toVC를 아래에 깔아야 함
        container.insertSubview(toVC.view, belowSubview: fromVC.view)
        
        // referenceView의 최종 위치
        let targetFrame = container.convert(referenceView.bounds, from: referenceView)
        
        let duration = transitionDuration(using: ctx)
        
        UIView.animate(withDuration: duration,
                       delay: 0,
                       options: [.curveEaseInOut],
                       animations: { [weak self] in
            guard let self else { return }
            // fromVC.view를 버튼 위치만큼 줄이기
            fromVC.view.frame = targetFrame
            fromVC.view.layer.cornerRadius = self.referenceView.layer.cornerRadius
        }, completion: { finished in
            // 끝나면 pop 완료
            let cancelled = ctx.transitionWasCancelled
            if !cancelled {
                fromVC.view.removeFromSuperview()
            }
            ctx.completeTransition(!cancelled)
        })
    }

    /// 디스미스 애니메이션 종료 시 호출
    func animationEnded(_ transitionCompleted: Bool) {
        print("\(#function)")
    }
}

// MARK: - UIViewControllerInteractiveTransitioning 구현

extension CustomDismissalTransitionAnimator: UIViewControllerInteractiveTransitioning {
    
    /// 제스처 진행도에 따라 축소/코너 라운드 변화가 적용되는 인터랙티브 디스미스를 시작
    func startInteractiveTransition(_ transitionContext: UIViewControllerContextTransitioning) {
        print("\(#function)")
        guard let fromVC = transitionContext.viewController(forKey: .from) else {
            return
        }

        fromVC.view.isHidden = true
        
        let containerView = transitionContext.containerView
        let startPoint = CGPoint(x: fromVC.view.frame.minX,
                                 y: fromVC.view.frame.minY)
        
        let startSize = fromVC.view.frame.size

        let transitionView = UIView(frame: CGRect(origin: startPoint, size: startSize))
        transitionView.backgroundColor = fromVC.view.backgroundColor
        transitionView.layer.masksToBounds = true
        transitionView.layer.cornerRadius = 0
        containerView.addSubview(transitionView)

        let finalFrame = containerView.convert(referenceView.bounds, from: referenceView)

        UIView.animate(withDuration: config.transitionDuration,
                       delay: 0,
                       usingSpringWithDamping: config.springWithDamping,
                       initialSpringVelocity: config.initialSpringVelocity,
                       options: [.beginFromCurrentState]) { [weak self] in 
            guard let self else { return }
            transitionView.frame = finalFrame
            transitionView.layer.cornerRadius = referenceView.layer.cornerRadius
        } completion: { wasCancelled in
            transitionContext.completeTransition(true)
        }
    }
}

