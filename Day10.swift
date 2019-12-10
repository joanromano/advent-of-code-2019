struct Key {
    let key: Double
    let coordindate: Coordinate
    
    init(_ key: Double, _ coordindate: Coordinate) {
        self.key = key
        self.coordindate = coordindate
    }
}

struct Coordinate: Hashable {
    let x: Int
    let y: Int
    
    init(_ x: Int, _ y: Int) {
        self.x = x
        self.y = y
    }
}

func getVaporizedAsteroid(at position: Int, using asteroidMap: [[String]]) -> Coordinate {
    let (monitoringLocation, asteroids) = computeBestMonitoringLocation(asteroidMap)
    
    var toSort = [Key]()
    for asteroid in asteroids {
        var key = atan2(Double(asteroid.x),Double(asteroid.y))
        if key > Double.pi/2 {
            key -= 2*Double.pi
        }
        toSort.append(Key(key, asteroid))
    }

    toSort = toSort.sorted { $0.key < $1.key }.reversed()
    
    let vaporized = toSort[position-1].coordindate
    var r = monitoringLocation.x - vaporized.x
    var c = monitoringLocation.y + vaporized.y
    while input[r][c] != "#" {
        r -= vaporized.x
        c += vaporized.y
    }

    return Coordinate(c,r)
}

func computeBestMonitoringLocation(_ asteroidMap: [[String]]) -> (location: Coordinate, asteroids: Set<Coordinate>) {
    let rows = asteroidMap.count
    let columns = asteroidMap[0].count
    var asteroidsResult = Set<Coordinate>()
    var locationResult = Coordinate(0,0)
    
    for r in 0..<rows {
        for c in 0..<columns {
            if asteroidMap[r][c] != "#" { continue }
            
            var seen = Set<Coordinate>()
            for rr in 0..<rows {
                for cc in 0..<columns {
                    if asteroidMap[rr][cc] == "#" && (r != rr || c != cc) {
                        let dr = rr - r
                        let dc = cc - c
                        var g = gcd(dr,dc)
                        if g < 0 { g *= -1 }
                        seen.insert(Coordinate(-dr/g,dc/g))
                    }
                }
            }
            
            if seen.count > asteroidsResult.count {
                asteroidsResult = seen
                locationResult = Coordinate(r,c)
            }
        }
    }
    
    return (locationResult,asteroidsResult)
}