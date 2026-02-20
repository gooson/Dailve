import SwiftUI

/// Detail view for the Wellness Score.
/// Shows score ring, sub-score breakdown, condition contributors, and explainer.
struct WellnessScoreDetailView: View {
    let wellnessScore: WellnessScore
    let conditionScore: ConditionScore?

    @Environment(\.horizontalSizeClass) private var sizeClass

    private var isRegular: Bool { sizeClass == .regular }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: isRegular ? DS.Spacing.xxl : DS.Spacing.xl) {
                // Hero + Guide
                if isRegular {
                    HStack(alignment: .top, spacing: DS.Spacing.xxl) {
                        scoreHero
                            .frame(maxWidth: .infinity)

                        VStack(alignment: .leading, spacing: DS.Spacing.lg) {
                            guideSection
                            subScoreBreakdown
                        }
                        .frame(maxWidth: .infinity)
                    }
                } else {
                    scoreHero
                    guideSection
                    subScoreBreakdown
                }

                // Condition Contributors (if available)
                if let condition = conditionScore, !condition.contributions.isEmpty {
                    StandardCard {
                        ScoreContributorsView(contributions: condition.contributions)
                    }
                }

                // Explainer
                StandardCard {
                    explainerSection
                }
            }
            .padding(isRegular ? DS.Spacing.xxl : DS.Spacing.lg)
        }
        .navigationTitle("Wellness Score")
        .navigationBarTitleDisplayMode(.large)
    }

    // MARK: - Score Hero

    private var ringSize: CGFloat { isRegular ? 180 : 120 }
    private var ringLineWidth: CGFloat { isRegular ? 16 : 12 }

    private var scoreHero: some View {
        HStack {
            Spacer()
            VStack(spacing: DS.Spacing.md) {
                ZStack {
                    ProgressRingView(
                        progress: Double(wellnessScore.score) / 100.0,
                        ringColor: wellnessScore.status.color,
                        lineWidth: ringLineWidth,
                        size: ringSize
                    )

                    VStack(spacing: DS.Spacing.xxs) {
                        Text("\(wellnessScore.score)")
                            .font(DS.Typography.heroScore)
                            .fontDesign(.rounded)

                        Text(wellnessScore.status.label)
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            Spacer()
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Wellness score \(wellnessScore.score), \(wellnessScore.status.label)")
    }

    // MARK: - Guide Section

    private var guideSection: some View {
        StandardCard {
            HStack(spacing: DS.Spacing.md) {
                Image(systemName: wellnessScore.status.iconName)
                    .font(.title3)
                    .foregroundStyle(wellnessScore.status.color)

                VStack(alignment: .leading, spacing: DS.Spacing.xs) {
                    Text(wellnessScore.status.label)
                        .font(.subheadline)
                        .fontWeight(.semibold)

                    Text(wellnessScore.guideMessage)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 0)
            }
        }
    }

    // MARK: - Sub-Score Breakdown

    private var subScoreBreakdown: some View {
        StandardCard {
            VStack(alignment: .leading, spacing: DS.Spacing.md) {
                Text("Score Breakdown")
                    .font(.subheadline)
                    .fontWeight(.semibold)

                subScoreRow(
                    label: "Sleep",
                    weight: 40,
                    score: wellnessScore.sleepScore,
                    color: DS.Color.sleep,
                    icon: "moon.zzz.fill",
                    description: "Sleep quality and duration from last night."
                )

                Divider()

                subScoreRow(
                    label: "Condition",
                    weight: 35,
                    score: wellnessScore.conditionScore,
                    color: DS.Color.hrv,
                    icon: "waveform.path.ecg",
                    description: "HRV and resting heart rate relative to your baseline."
                )

                Divider()

                subScoreRow(
                    label: "Body",
                    weight: 25,
                    score: wellnessScore.bodyScore,
                    color: DS.Color.body,
                    icon: "figure.stand",
                    description: "Weight and body composition trend over the past week."
                )
            }
        }
    }

    private func subScoreRow(
        label: String,
        weight: Int,
        score: Int?,
        color: Color,
        icon: String,
        description: String
    ) -> some View {
        VStack(alignment: .leading, spacing: DS.Spacing.sm) {
            HStack(spacing: DS.Spacing.sm) {
                Image(systemName: icon)
                    .font(.subheadline)
                    .foregroundStyle(color)
                    .frame(width: 20)

                Text(label)
                    .font(.subheadline)
                    .fontWeight(.medium)

                Text("\(weight)%")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(color.opacity(0.1), in: Capsule())

                Spacer()

                Text(score.map { "\($0)" } ?? "--")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .fontDesign(.rounded)
                    .foregroundStyle(score != nil ? .primary : .quaternary)
            }

            // Progress bar
            GeometryReader { geo in
                let fraction = CGFloat(score ?? 0) / 100.0
                Capsule()
                    .fill(color.opacity(0.15))
                    .overlay(alignment: .leading) {
                        Capsule()
                            .fill(color)
                            .frame(width: geo.size.width * fraction)
                    }
            }
            .frame(height: 6)

            Text(description)
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(label), \(weight) percent weight, score \(score.map { "\($0)" } ?? "no data")")
    }

    // MARK: - Explainer

    private var explainerSection: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.md) {
            HStack(spacing: DS.Spacing.sm) {
                Image(systemName: "info.circle.fill")
                    .foregroundStyle(.secondary)
                Text("How It Works")
                    .font(.subheadline)
                    .fontWeight(.semibold)
            }

            VStack(alignment: .leading, spacing: DS.Spacing.sm) {
                explainerItem(
                    "Your Wellness Score combines three key health dimensions into a single 0-100 score."
                )
                explainerItem(
                    "Sleep (40%): Based on sleep duration, stages, and efficiency from Apple Watch."
                )
                explainerItem(
                    "Condition (35%): Uses HRV trends and resting heart rate changes compared to your personal baseline."
                )
                explainerItem(
                    "Body (25%): Tracks weight and body composition stability over the past week."
                )
                explainerItem(
                    "Missing data is handled by redistributing weights among available scores."
                )
            }
        }
    }

    private func explainerItem(_ text: String) -> some View {
        HStack(alignment: .top, spacing: DS.Spacing.sm) {
            Circle()
                .fill(.tertiary)
                .frame(width: 4, height: 4)
                .padding(.top, 6)

            Text(text)
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}
