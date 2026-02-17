import SwiftUI

extension Equipment {
    var displayName: String {
        switch self {
        case .barbell: "Barbell"
        case .dumbbell: "Dumbbell"
        case .machine: "Machine"
        case .cable: "Cable"
        case .bodyweight: "Bodyweight"
        case .band: "Band"
        case .kettlebell: "Kettlebell"
        case .other: "Other"
        }
    }

    var localizedDisplayName: String {
        switch self {
        case .barbell: "바벨"
        case .dumbbell: "덤벨"
        case .machine: "머신"
        case .cable: "케이블"
        case .bodyweight: "맨몸"
        case .band: "밴드"
        case .kettlebell: "케틀벨"
        case .other: "기타"
        }
    }

    var equipmentDescription: String {
        switch self {
        case .barbell: "긴 봉에 원판을 끼워 사용하는 프리웨이트 기구. 높은 중량 훈련에 적합"
        case .dumbbell: "한 손에 하나씩 드는 프리웨이트. 좌우 균형 발달에 효과적"
        case .machine: "가이드 레일이 있어 궤적이 고정된 기구. 초보자도 안전하게 사용 가능"
        case .cable: "도르래와 케이블로 연결된 기구. 다양한 각도에서 저항 운동 가능"
        case .bodyweight: "기구 없이 자기 체중만으로 수행하는 운동"
        case .band: "탄성 밴드를 이용한 저항 운동. 강도 조절이 쉽고 휴대 가능"
        case .kettlebell: "손잡이가 달린 구형 중량 기구. 스윙, 클린 등 동적 운동에 적합"
        case .other: "기타 보조 기구"
        }
    }

    var iconName: String {
        switch self {
        case .barbell: "dumbbell.fill"
        case .dumbbell: "dumbbell.fill"
        case .machine: "gearshape.fill"
        case .cable: "cable.connector"
        case .bodyweight: "figure.stand"
        case .band: "circle.dashed"
        case .kettlebell: "dumbbell.fill"
        case .other: "ellipsis.circle"
        }
    }
}
