import Foundation
import Testing
@testable import Dailve

@Suite("WorkoutActivityType")
struct WorkoutActivityTypeTests {

    @Test("Running is distance-based")
    func runningIsDistanceBased() {
        #expect(WorkoutActivityType.running.isDistanceBased)
    }

    @Test("Strength training is not distance-based")
    func strengthNotDistanceBased() {
        #expect(!WorkoutActivityType.traditionalStrengthTraining.isDistanceBased)
    }

    @Test("Category mapping — running is cardio")
    func runningIsCardio() {
        #expect(WorkoutActivityType.running.category == .cardio)
    }

    @Test("Category mapping — yoga is mindBody")
    func yogaIsMindBody() {
        #expect(WorkoutActivityType.yoga.category == .mindBody)
    }

    @Test("Category mapping — boxing is combat")
    func boxingIsCombat() {
        #expect(WorkoutActivityType.boxing.category == .combat)
    }

    @Test("typeName returns readable name")
    func typeNameReadable() {
        #expect(WorkoutActivityType.running.typeName == "Running")
        #expect(WorkoutActivityType.highIntensityIntervalTraining.typeName == "HIIT")
        #expect(WorkoutActivityType.other.typeName == "Workout")
    }

    @Test("All cases have non-empty typeName")
    func allTypesHaveNames() {
        for type in WorkoutActivityType.allCases {
            #expect(!type.typeName.isEmpty, "Missing typeName for \(type.rawValue)")
        }
    }
}

@Suite("MilestoneDistance")
struct MilestoneDistanceTests {

    @Test("Detects 5K from distance >= 5000m")
    func detect5K() {
        // detect returns highest matching milestone where distance >= meters
        #expect(MilestoneDistance.detect(from: 5000) == .fiveK)
        #expect(MilestoneDistance.detect(from: 5150) == .fiveK)
        // Below 5000 → nil
        #expect(MilestoneDistance.detect(from: 4850) == nil)
    }

    @Test("Detects 10K from distance >= 10000m")
    func detect10K() {
        #expect(MilestoneDistance.detect(from: 10000) == .tenK)
        // 7500 >= 5000 → fiveK (highest matching)
        #expect(MilestoneDistance.detect(from: 7500) == .fiveK)
    }

    @Test("Detects half marathon")
    func detectHalfMarathon() {
        #expect(MilestoneDistance.detect(from: 21097) == .halfMarathon)
    }

    @Test("Detects marathon")
    func detectMarathon() {
        #expect(MilestoneDistance.detect(from: 42195) == .marathon)
    }

    @Test("Returns nil for distances below 5K")
    func noMilestone() {
        #expect(MilestoneDistance.detect(from: 3000) == nil)
        #expect(MilestoneDistance.detect(from: 4999) == nil)
    }

    @Test("Returns nil for nil distance")
    func nilDistance() {
        #expect(MilestoneDistance.detect(from: nil) == nil)
    }

    @Test("Returns nil for negative distance")
    func negativeDistance() {
        #expect(MilestoneDistance.detect(from: -5000) == nil)
    }

    @Test("Prioritizes marathon over shorter milestones")
    func marathonPriority() {
        // Marathon distance is ~42195, which shouldn't match 5K or 10K
        let result = MilestoneDistance.detect(from: 42195)
        #expect(result == .marathon)
    }
}
