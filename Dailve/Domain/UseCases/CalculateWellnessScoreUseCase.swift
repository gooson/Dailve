import Foundation

protocol WellnessScoreCalculating: Sendable {
    func execute(input: CalculateWellnessScoreUseCase.Input) -> WellnessScore?
}

struct CalculateWellnessScoreUseCase: WellnessScoreCalculating, Sendable {
    // Weight allocation (must sum to 1.0)
    private let sleepWeight = 0.40
    private let conditionWeight = 0.35
    private let bodyWeight = 0.25

    struct Input: Sendable {
        let sleepScore: Int?
        let conditionScore: Int?
        let bodyTrend: BodyTrend?
    }

    /// Body composition trend over the last 7 days.
    struct BodyTrend: Sendable {
        let weightChange: Double?   // kg change (negative = loss)
        let bodyFatChange: Double?  // percentage points change (negative = loss)

        /// Convert body trend into a 0-100 score.
        /// Stable or improving trends score higher.
        var score: Int {
            var points = 50.0 // neutral baseline

            // Weight stability/loss is generally positive for fitness users
            if let wc = weightChange {
                let absChange = abs(wc)
                if absChange < 0.5 {
                    points += 25 // stable weight
                } else if wc < 0 {
                    points += 15 // losing weight (generally positive)
                } else {
                    points -= min(15, absChange * 5) // gaining weight
                }
            }

            // Body fat decrease is positive
            if let bfc = bodyFatChange {
                let absChange = abs(bfc)
                if absChange < 0.3 {
                    points += 25 // stable body fat
                } else if bfc < 0 {
                    points += 25 // losing body fat
                } else {
                    points -= min(25, absChange * 10) // gaining body fat
                }
            }

            return Int(max(0, min(100, points)).rounded())
        }
    }

    func execute(input: Input) -> WellnessScore? {
        // Count available components
        let hasSleep = input.sleepScore != nil
        let hasCondition = input.conditionScore != nil
        let hasBody = input.bodyTrend != nil

        let componentCount = [hasSleep, hasCondition, hasBody].filter(\.self).count

        // Need at least 1 component to produce a score
        guard componentCount >= 1 else { return nil }

        let bodyScoreValue = input.bodyTrend?.score

        // Calculate weighted score, redistributing missing weights proportionally
        var totalWeight = 0.0
        var weightedSum = 0.0

        if let sleep = input.sleepScore {
            totalWeight += sleepWeight
            weightedSum += Double(sleep) * sleepWeight
        }
        if let condition = input.conditionScore {
            totalWeight += conditionWeight
            weightedSum += Double(condition) * conditionWeight
        }
        if let body = bodyScoreValue {
            totalWeight += bodyWeight
            weightedSum += Double(body) * bodyWeight
        }

        guard totalWeight > 0 else { return nil }

        let rawScore = weightedSum / totalWeight
        guard !rawScore.isNaN, !rawScore.isInfinite else { return nil }

        return WellnessScore(
            score: Int(rawScore.rounded()),
            sleepScore: input.sleepScore,
            conditionScore: input.conditionScore,
            bodyScore: bodyScoreValue
        )
    }
}
