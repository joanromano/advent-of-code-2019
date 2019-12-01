func fuel(_ mass: Int) -> Int {
    let divided = Double(mass) / 3
    guard divided > 0 else { return 0 }
    let substracted = Int(divided) - 2
    guard substracted > 0 else { return 0 }
    return substracted + fuel(substracted)
}