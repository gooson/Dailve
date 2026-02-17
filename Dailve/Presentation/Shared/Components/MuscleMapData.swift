import SwiftUI

// MARK: - Shared data for muscle map visualizations

struct MuscleMapItem: Identifiable {
    let id: String
    let muscle: MuscleGroup
    let position: CGPoint  // Normalized (0...1)
    let size: CGSize       // Normalized (0...1)
    let cornerRadius: CGFloat

    init(muscle: MuscleGroup, position: CGPoint, size: CGSize, cornerRadius: CGFloat) {
        self.id = "\(muscle.rawValue)-\(position.x)-\(position.y)"
        self.muscle = muscle
        self.position = position
        self.size = size
        self.cornerRadius = cornerRadius
    }
}

// MARK: - Body Outline

enum MuscleMapData {
    static func bodyOutline(width: CGFloat, height: CGFloat) -> Path {
        var path = Path()
        let cx = width * 0.5
        // Head
        path.addEllipse(in: CGRect(x: cx - 18, y: height * 0.02, width: 36, height: 42))
        // Neck
        path.addRect(CGRect(x: cx - 8, y: height * 0.1, width: 16, height: height * 0.03))
        // Torso
        path.addRoundedRect(in: CGRect(x: cx - width * 0.18, y: height * 0.13, width: width * 0.36, height: height * 0.32), cornerSize: CGSize(width: 12, height: 12))
        // Left arm
        path.addRoundedRect(in: CGRect(x: cx - width * 0.3, y: height * 0.15, width: width * 0.1, height: height * 0.28), cornerSize: CGSize(width: 8, height: 8))
        // Right arm
        path.addRoundedRect(in: CGRect(x: cx + width * 0.2, y: height * 0.15, width: width * 0.1, height: height * 0.28), cornerSize: CGSize(width: 8, height: 8))
        // Left leg
        path.addRoundedRect(in: CGRect(x: cx - width * 0.14, y: height * 0.47, width: width * 0.12, height: height * 0.38), cornerSize: CGSize(width: 8, height: 8))
        // Right leg
        path.addRoundedRect(in: CGRect(x: cx + width * 0.02, y: height * 0.47, width: width * 0.12, height: height * 0.38), cornerSize: CGSize(width: 8, height: 8))
        return path
    }

    // MARK: - Muscle Positions

    static let frontMuscles: [MuscleMapItem] = [
        // Chest
        MuscleMapItem(muscle: .chest, position: CGPoint(x: 0.42, y: 0.21), size: CGSize(width: 0.12, height: 0.08), cornerRadius: 6),
        MuscleMapItem(muscle: .chest, position: CGPoint(x: 0.58, y: 0.21), size: CGSize(width: 0.12, height: 0.08), cornerRadius: 6),
        // Shoulders
        MuscleMapItem(muscle: .shoulders, position: CGPoint(x: 0.33, y: 0.16), size: CGSize(width: 0.08, height: 0.06), cornerRadius: 8),
        MuscleMapItem(muscle: .shoulders, position: CGPoint(x: 0.67, y: 0.16), size: CGSize(width: 0.08, height: 0.06), cornerRadius: 8),
        // Biceps
        MuscleMapItem(muscle: .biceps, position: CGPoint(x: 0.27, y: 0.27), size: CGSize(width: 0.06, height: 0.1), cornerRadius: 6),
        MuscleMapItem(muscle: .biceps, position: CGPoint(x: 0.73, y: 0.27), size: CGSize(width: 0.06, height: 0.1), cornerRadius: 6),
        // Forearms
        MuscleMapItem(muscle: .forearms, position: CGPoint(x: 0.25, y: 0.38), size: CGSize(width: 0.05, height: 0.08), cornerRadius: 4),
        MuscleMapItem(muscle: .forearms, position: CGPoint(x: 0.75, y: 0.38), size: CGSize(width: 0.05, height: 0.08), cornerRadius: 4),
        // Core
        MuscleMapItem(muscle: .core, position: CGPoint(x: 0.5, y: 0.33), size: CGSize(width: 0.12, height: 0.12), cornerRadius: 6),
        // Quads
        MuscleMapItem(muscle: .quadriceps, position: CGPoint(x: 0.42, y: 0.55), size: CGSize(width: 0.1, height: 0.14), cornerRadius: 6),
        MuscleMapItem(muscle: .quadriceps, position: CGPoint(x: 0.58, y: 0.55), size: CGSize(width: 0.1, height: 0.14), cornerRadius: 6),
        // Calves
        MuscleMapItem(muscle: .calves, position: CGPoint(x: 0.42, y: 0.75), size: CGSize(width: 0.07, height: 0.1), cornerRadius: 4),
        MuscleMapItem(muscle: .calves, position: CGPoint(x: 0.58, y: 0.75), size: CGSize(width: 0.07, height: 0.1), cornerRadius: 4),
    ]

    static let backMuscles: [MuscleMapItem] = [
        // Traps
        MuscleMapItem(muscle: .traps, position: CGPoint(x: 0.5, y: 0.15), size: CGSize(width: 0.16, height: 0.06), cornerRadius: 6),
        // Rear delts
        MuscleMapItem(muscle: .shoulders, position: CGPoint(x: 0.33, y: 0.17), size: CGSize(width: 0.08, height: 0.06), cornerRadius: 8),
        MuscleMapItem(muscle: .shoulders, position: CGPoint(x: 0.67, y: 0.17), size: CGSize(width: 0.08, height: 0.06), cornerRadius: 8),
        // Lats
        MuscleMapItem(muscle: .lats, position: CGPoint(x: 0.4, y: 0.26), size: CGSize(width: 0.1, height: 0.12), cornerRadius: 8),
        MuscleMapItem(muscle: .lats, position: CGPoint(x: 0.6, y: 0.26), size: CGSize(width: 0.1, height: 0.12), cornerRadius: 8),
        // Triceps
        MuscleMapItem(muscle: .triceps, position: CGPoint(x: 0.27, y: 0.27), size: CGSize(width: 0.06, height: 0.1), cornerRadius: 6),
        MuscleMapItem(muscle: .triceps, position: CGPoint(x: 0.73, y: 0.27), size: CGSize(width: 0.06, height: 0.1), cornerRadius: 6),
        // Lower back
        MuscleMapItem(muscle: .back, position: CGPoint(x: 0.5, y: 0.37), size: CGSize(width: 0.14, height: 0.08), cornerRadius: 6),
        // Glutes
        MuscleMapItem(muscle: .glutes, position: CGPoint(x: 0.42, y: 0.48), size: CGSize(width: 0.1, height: 0.08), cornerRadius: 8),
        MuscleMapItem(muscle: .glutes, position: CGPoint(x: 0.58, y: 0.48), size: CGSize(width: 0.1, height: 0.08), cornerRadius: 8),
        // Hamstrings
        MuscleMapItem(muscle: .hamstrings, position: CGPoint(x: 0.42, y: 0.6), size: CGSize(width: 0.1, height: 0.12), cornerRadius: 6),
        MuscleMapItem(muscle: .hamstrings, position: CGPoint(x: 0.58, y: 0.6), size: CGSize(width: 0.1, height: 0.12), cornerRadius: 6),
        // Calves
        MuscleMapItem(muscle: .calves, position: CGPoint(x: 0.42, y: 0.75), size: CGSize(width: 0.07, height: 0.1), cornerRadius: 4),
        MuscleMapItem(muscle: .calves, position: CGPoint(x: 0.58, y: 0.75), size: CGSize(width: 0.07, height: 0.1), cornerRadius: 4),
    ]
}
