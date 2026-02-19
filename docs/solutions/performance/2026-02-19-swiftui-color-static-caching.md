---
tags: [swiftui, color, caching, static-let, hot-path, muscle-map, render-performance]
category: performance
date: 2026-02-19
severity: critical
related_files:
  - Dailve/Presentation/Shared/Extensions/FatigueLevel+View.swift
  - Dailve/Presentation/Activity/Components/MuscleRecoveryMapView.swift
related_solutions:
  - performance/2026-02-19-numberformatter-static-caching.md
  - performance/2026-02-16-computed-property-caching-pattern.md
---

# Solution: SwiftUI Color Static Caching for Hot Render Paths

## Problem

### Symptoms

- `FatigueLevel.color(for:)` called 26+ times per render cycle (13 muscles x front/back ForEach + legend)
- Each call creates a new `Color(hue:saturation:brightness:)` instance via switch statement
- On body diagram scroll/animation, this multiplies further with SwiftUI redraw frequency

### Root Cause

`Color(hue:saturation:brightness:)` is a value type initializer that allocates on every call. When used inside `ForEach` body with 13+ iterations, each view re-evaluation triggers dozens of allocations. The muscle recovery map renders these colors for every visible muscle path plus the legend bar.

## Solution

### Changes Made

| File | Change | Reason |
|------|--------|--------|
| `FatigueLevel+View.swift` | Replace per-call Color init with static cached arrays | Reduce allocations from 26+/render to 0 |

### Key Code

```swift
// BEFORE: new Color per call
func color(for colorScheme: ColorScheme) -> Color {
    switch self {
    case .fullyRecovered:
        return Color(hue: 0.39, saturation: 0.70, brightness: colorScheme == .dark ? 0.90 : 0.50)
    // ... 10 more cases
    }
}

// AFTER: static cached arrays indexed by rawValue
func color(for colorScheme: ColorScheme) -> Color {
    if self == .noData { return ColorCache.noDataColor }
    let cache = colorScheme == .dark ? ColorCache.dark : ColorCache.light
    return cache[Int(rawValue)]
}

private enum ColorCache {
    static let noDataColor = Color.secondary.opacity(0.2)
    static let dark: [Color] = buildColors(isDark: true)
    static let light: [Color] = buildColors(isDark: false)

    private static func buildColors(isDark: Bool) -> [Color] {
        let specs: [(hue: Double, sat: Double, darkB: Double, lightB: Double)] = [
            (0, 0, 0, 0),              // 0: noData placeholder
            (0.39, 0.70, 0.90, 0.50),  // 1: fullyRecovered
            // ... indexed by rawValue
        ]
        return specs.map { Color(hue: $0.hue, saturation: $0.sat, brightness: isDark ? $0.darkB : $0.lightB) }
    }
}
```

### Pattern

**When to apply**: Any `Color`/`Font`/`NSObject`-based value used in `ForEach` or hot render paths (charts, lists, maps).

**Structure**: `private enum Cache { static let values = build() }` — enum prevents instantiation, `static let` guarantees single initialization.

**Index strategy**: Use enum `rawValue` as array index when enum cases are contiguous integers starting from 0.

## Prevention

### Checklist Addition

- [ ] New Color/Font/Formatter in ForEach body? → Must use static cache (Correction #80)
- [ ] Enum-to-visual mapping? → Consider static array indexed by rawValue

## Lessons Learned

- `Color(hue:saturation:brightness:)` appears lightweight but creates a new instance each time — problematic at 26+ calls per render
- The `private enum { static let }` pattern is more idiomatic than `class` or `struct` for pure caches — prevents accidental instantiation
- Array indexing by `rawValue` is O(1) and eliminates the switch statement entirely, but requires contiguous integer raw values
