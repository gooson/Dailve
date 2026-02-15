import Foundation
import Testing
@testable import Dailve

@Suite("CalculateConditionScoreUseCase")
struct CalculateConditionScoreUseCaseTests {
    let sut = CalculateConditionScoreUseCase()

    @Test("Returns nil score when insufficient days")
    func insufficientDays() {
        let samples = (0..<3).map { day in
            HRVSample(value: 50, date: Calendar.current.date(byAdding: .day, value: -day, to: Date())!)
        }
        let input = CalculateConditionScoreUseCase.Input(
            hrvSamples: samples, todayRHR: nil, yesterdayRHR: nil
        )
        let output = sut.execute(input: input)
        #expect(output.score == nil)
        #expect(!output.baselineStatus.isReady)
    }

    @Test("Returns valid score with 7 days of data")
    func sufficientDays() {
        let samples = (0..<7).map { day in
            HRVSample(value: 50, date: Calendar.current.date(byAdding: .day, value: -day, to: Date())!)
        }
        let input = CalculateConditionScoreUseCase.Input(
            hrvSamples: samples, todayRHR: nil, yesterdayRHR: nil
        )
        let output = sut.execute(input: input)
        #expect(output.score != nil)
        #expect(output.baselineStatus.isReady)
    }

    @Test("Score is clamped to 0-100")
    func scoreClamped() {
        // Extreme variance: today very high, baseline very low
        var samples = (1..<7).map { day in
            HRVSample(value: 10, date: Calendar.current.date(byAdding: .day, value: -day, to: Date())!)
        }
        samples.insert(HRVSample(value: 200, date: Date()), at: 0)

        let input = CalculateConditionScoreUseCase.Input(
            hrvSamples: samples, todayRHR: nil, yesterdayRHR: nil
        )
        let output = sut.execute(input: input)
        if let score = output.score {
            #expect(score.score >= 0 && score.score <= 100)
        }
    }

    @Test("Returns nil for zero-value HRV samples")
    func zeroValueSamples() {
        let samples = (0..<7).map { day in
            HRVSample(value: 0, date: Calendar.current.date(byAdding: .day, value: -day, to: Date())!)
        }
        let input = CalculateConditionScoreUseCase.Input(
            hrvSamples: samples, todayRHR: nil, yesterdayRHR: nil
        )
        let output = sut.execute(input: input)
        #expect(output.score == nil)
    }

    @Test("RHR correction lowers score when RHR rises and HRV drops")
    func rhrCorrection() {
        // Normal baseline
        var samples = (1..<7).map { day in
            HRVSample(value: 50, date: Calendar.current.date(byAdding: .day, value: -day, to: Date())!)
        }
        // Today: lower HRV
        samples.insert(HRVSample(value: 30, date: Date()), at: 0)

        let withoutRHR = sut.execute(input: .init(
            hrvSamples: samples, todayRHR: nil, yesterdayRHR: nil
        ))
        let withRHR = sut.execute(input: .init(
            hrvSamples: samples, todayRHR: 75, yesterdayRHR: 65
        ))

        if let scoreWithout = withoutRHR.score, let scoreWith = withRHR.score {
            #expect(scoreWith.score <= scoreWithout.score)
        }
    }
}
