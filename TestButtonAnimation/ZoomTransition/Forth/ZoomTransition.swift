//
//  ZoomTransition.swift
//  TestButtonAnimation
//
//  Created by Jae hyung Kim on 10/27/25.
//

import UIKit

final class CustomZoomTransition: NSObject {
    private let config: CustomZoomTransitionConfiguration
    private let referenceView: UIView
    private let presentingTransitionAnimator: CustomPresentingTransitionAnimator
    private let dismissalTransitionAnimator: CustomDismissalTransitionAnimator
    private var presentationController: UIPresentationController?
    private var currentTranslationY: CGFloat = 0

    // MARK: - Initializers

    init(
        referenceView: UIView,
        config: CustomZoomTransitionConfiguration = CustomZoomTransitionConfiguration()
    ) {
        self.referenceView = referenceView
        self.config = config

        presentingTransitionAnimator = CustomPresentingTransitionAnimator(
            config: config,
            referenceView: referenceView
        )
        
        dismissalTransitionAnimator = CustomDismissalTransitionAnimator(
            config: config,
            referenceView: referenceView
        )
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
    private func handlePanGesture(_ gestureRecognizer: UIPanGestureRecognizer) {
        guard let presentedVC = presentationController?.presentedViewController else {
            return
        }

        switch gestureRecognizer.state {
        case .changed:
            let translation = gestureRecognizer.translation(in: presentedVC.view)
            currentTranslationY = hypot(translation.x, translation.y)
            presentedVC.view.alpha = config.getAlpha(by: translation)
            presentedVC.view.transform = CGAffineTransform(translationX: translation.x, y: translation.y)
            gestureRecognizer.setTranslation(translation, in: presentedVC.view)
        case .ended, .cancelled:
            presentedVC.view.alpha = 1
            if currentTranslationY > config.panGestureDismissThreshold {
                presentedVC.dismiss(animated: true, completion: nil)
            }
            else {
                currentTranslationY = 0

                UIView.animate(withDuration: 0.1) {
                    presentedVC.view.transform = .identity
                }
            }
        default:
            break
        }
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
    private var transitionContext: UIViewControllerContextTransitioning?

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

    /// 인터랙티브 디스미스를 사용하므로 이 메서드에서는 별도 애니메이션을 수행하지 않습니다.
    func animateTransition(
        using transitionContext: UIViewControllerContextTransitioning
    ) {
        print("\(#function)")
        // InteractiveTransitioning을 사용하므로, 아무동작도 하지 않는다.
    }

    /// 디스미스 애니메이션 종료 시 호출
    func animationEnded(_ transitionCompleted: Bool) {
        print("\(#function)")
        transitionContext = nil
    }
}

// MARK: - UIViewControllerInteractiveTransitioning 구현

extension CustomDismissalTransitionAnimator: UIViewControllerInteractiveTransitioning {
    
    /// 제스처 진행도에 따라 축소/코너 라운드 변화가 적용되는 인터랙티브 디스미스를 시작
    func startInteractiveTransition(_ transitionContext: UIViewControllerContextTransitioning) {
        print("\(#function)")
        guard let singleColorVC = transitionContext.viewController(forKey: .from) else {
            return
        }
    
        self.transitionContext = transitionContext

        singleColorVC.view.isHidden = true
        
        let containerView = transitionContext.containerView
        let startPoint = CGPoint(x: singleColorVC.view.frame.minX,
                                 y: singleColorVC.view.frame.minY)
        
        let startSize = singleColorVC.view.frame.size

        let transitionView = UIView(frame: CGRect(origin: startPoint, size: startSize))
        transitionView.backgroundColor = singleColorVC.view.backgroundColor
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

