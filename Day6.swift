// Part 1

func totalNumberOfOrbitsPart1(_ orbits: [String]) -> Int {
    var graph = [String:String]()
    
    for orbit in orbits {
        let split = orbit.split(separator: ")")
        graph[String(split[1])] = String(split[0])
    }
    
    return _numberOfOrbits(graph)
}

func _numberOfOrbits(_ graph: [String:String]) -> Int {
    var count = 0
    
    for key in graph.keys {
        count += _numberOfOrbits(key, graph)
    }
    
    return count
}

func _numberOfOrbits(_ node: String, _ graph: [String:String]) -> Int {
    guard let next = graph[node] else { return 0 }
    return 1 + _numberOfOrbits(next, graph)
}

// Part 2

func totalNumberOfOrbitsPart2(_ orbits: [String]) -> Int {
    var graph = [String:[String]]()
    var visited = Set<String>()
    
    for orbit in orbits {
        let split = orbit.split(separator: ")")
        graph[String(split[1])] = (graph[String(split[1])] ?? []) + [String(split[0])]
        graph[String(split[0])] = (graph[String(split[0])] ?? []) + [String(split[1])]
    }
    
    return _dfs("YOU", &visited, graph) - 2 // (Substract 2 to remove "YOU" and "SANTA" from the result)
}

func _dfs(_ node: String, _ visited: inout Set<String>, _ graph: [String:[String]]) -> Int {
    guard node != "SAN" else { return 0 }
    
    var result = Int.max
    visited.insert(node)
    
    for child in graph[node] ?? [] where !visited.contains(child) {
        let nextResult = _dfs(child, &visited, graph)
        
        if nextResult != Int.max {
            result = min(result, 1 + nextResult)
        }
    }
    
    return result
}