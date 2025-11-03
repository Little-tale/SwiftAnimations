//
//  CustomTransitionConfiguration.swift
//  TestButtonAnimation
//
//  Created by Jae hyung Kim on 10/27/25.
//

import UIKit

/// ZOOM 전환(프레젠트/디스미스) 시 사용되는 설정 값 모음
/// - 전환 시간, 스프링 파라미터
/// - 팬 제스처(양축) 기반 알파/디스미스 임계값 계산
struct CustomZoomTransitionConfiguration {
    // MARK: - 애니메이션 기본 파라미터
    /// 전환(프레젠트/디스미스)에 걸리는 총 시간
    let transitionDuration: TimeInterval
    /// 스프링 애니메이션의 감쇠 비율 --> (작을수록 더 출렁임)
    let springWithDamping: CGFloat
    /// 스프링 애니메이션의 초기 속도
    let initialSpringVelocity: CGFloat

    // MARK: - 팬 제스처 관련 파라미터
    /// 이 거리(픽셀) 이상 이동하면 디스미스 처리
    let panGestureDismissThreshold: CGFloat
    /// 팬 제스처 중 최소 알파 값
    let minAlphaDuringPan: CGFloat
    /// 이 거리까지 선형으로 알파가 감소 (0 → minAlphaDuringPan)
    let alphaRangeDistance: CGFloat

    init(
        transitionDuration: TimeInterval = 0.5,
        springWithDamping: CGFloat = 0.85,
        initialSpringVelocity: CGFloat = 0.8,
        panGestureDismissThreshold: CGFloat = 120,
        minAlphaDuringPan: CGFloat = 0.6,
        alphaRangeDistance: CGFloat = 160
    ) {
        self.transitionDuration = transitionDuration
        self.springWithDamping = springWithDamping
        self.initialSpringVelocity = initialSpringVelocity
        self.panGestureDismissThreshold = panGestureDismissThreshold
        self.minAlphaDuringPan = minAlphaDuringPan
        self.alphaRangeDistance = alphaRangeDistance
    }
}
