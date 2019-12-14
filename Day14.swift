struct Chemical {
    let name: String
    let amount: Int
    
    init(_ name: String, _ amount: Int) {
        self.name = name
        self.amount = amount
    }
}

struct Reaction {
    let name: String
    let chemicals: [Chemical]
    let amount: Int
    
    init(_ name: String, _ chemicals: [Chemical], _ amount: Int) {
        self.name = name
        self.chemicals = chemicals
        self.amount = amount
    }
}

extension String {
    var chemical: Chemical {
        var number = ""
        var copy = self
        for character in self {
            guard character.isNumber else { break }
            copy.removeFirst()
            number += [character]
        }
        copy.removeFirst() // Remove in between space
        
        return Chemical(copy, Int(number)!)
    }
}

extension Dictionary where Key == String, Value == [String] {
    func topologicalSorted(starting vertex: String) -> [String] {
        var visited = Set<String>()
        var stack = [String]()
        topologicalSort(vertex, &visited, &stack)
        return Array(stack.reversed())
    }
    
    private func topologicalSort(_ vertex: String, _ visited: inout Set<String>, _ stack: inout [String]) {
        guard !visited.contains(vertex) else {
            return
        }
        
        visited.insert(vertex)

        for child in self[vertex] ?? [] {
            topologicalSort(child, &visited, &stack)
        }
        
        stack.append(vertex)
    }
}

func oreRequired(forFuel fuelCount: Int, rawReactions: [[String]]) -> Int {
    var reactions = [String:Reaction]()
    var dependencyGraph = [String:[String]]()
    var requested = ["FUEL":fuelCount]

    for rawReaction in rawReactions {
        let outputChemical = rawReaction.last!.chemical
        let inputChemicals = rawReaction[0..<rawReaction.count-1].map { $0.chemical }
        reactions[outputChemical.name] = Reaction(outputChemical.name, inputChemicals, outputChemical.amount)
        dependencyGraph[outputChemical.name] = inputChemicals.map { $0.name }.filter { $0 != "ORE" }
    }

    for item in dependencyGraph.topologicalSorted(starting: "FUEL") {
        guard let reaction = reactions[item], let amountRequested = requested[item] else { continue }
        let multiplier = (amountRequested+reaction.amount-1)/reaction.amount
        for chemical in reaction.chemicals {
            requested[chemical.name] = requested[chemical.name, default: 0] + multiplier * chemical.amount
        }
    }
    
    return requested["ORE"] ?? 0
}

func maxFuelCount(withOreCount oreCount: Int = 1000000000000) -> Int {
    func bSearch(min: Int, max: Int) -> Int {
        guard min < max else { return min }
        
        let mid = min + (max - min) / 2
        let next = oreRequired(forFuel: mid, rawReactions: inputs)
        if next < oreCount {
            return bSearch(min: mid, max: max)
        } else {
            return bSearch(min: min, max: mid-1)
        }
    }
    
    return bSearch(min: 0, max: oreCount)
}