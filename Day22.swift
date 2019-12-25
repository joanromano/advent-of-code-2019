enum Technique {
    case dealIntoNewStack
    case cut(cards: Int)
    case deal(increment: Int)

    init(_ string: String) {
        if string == "deal into new stack" {
            self = .dealIntoNewStack
        } else if string.hasPrefix("cut ") {
            self = .cut(cards: Int(String(string.dropFirst("cut ".count)))!)
        } else if string.hasPrefix("deal with increment ") {
            self = .deal(increment: Int(String(string.dropFirst("deal with increment ".count)))!)
        } else {
            fatalError()
        }
    }
}

extension Array where Element == Int {
    func appying(_ technique: Technique) -> [Int] {
        switch technique {
        case .dealIntoNewStack:
            return self.reversed()
        case let .cut(cards):
            if cards >= 0 {
                return Array(self[cards...] + self[0..<cards])
            } else {
                let index = (count-abs(cards))
                return Array(self[index...] + self[0..<index])
            }
        case let .deal(increment):
            var copy = self
            
            for index in 0..<count {
                copy[(index*increment)%count] = self[index]
            }
            
            return copy
        }
    }
}

/*
 Sample input: """
 deal into new stack
 deal with increment 68
 cut 4888
 deal with increment 44
 cut -7998
 deal into new stack
 cut -5078
 deal with increment 26
 cut 7651
 """
 */
func indexOf(_ value: Int, _ stackOrder: Int, _ input: String) -> Int {
    let inputLines = input.split(separator: "\n")
    var stack: [Int] = (0..<stackOrder).map { $0 }

    for line in inputLines {
        stack = stack.appying(Technique(String(line)))
    }

    return stack.firstIndex(of: value) ?? 0
}