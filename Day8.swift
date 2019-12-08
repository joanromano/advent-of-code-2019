func decodeImage(_ data: [Int], _ width: Int, _ height: Int) -> [[Int]] {
    let count = data.count
    var dataIndex = 0, i = 0, j = 0
    var layers = [[[Int]]]()
    var result = Array(repeating: Array(repeating: 0, count: width), count: height)

    while dataIndex < count {
        i = 0
        var nextLayer = [[Int]]()
        
        while i < height {
            j = 0
            var nextRow = [Int]()
            
            while j < width {
                nextRow.append(data[dataIndex])
                j += 1
                dataIndex += 1
            }
            
            i += 1
            nextLayer.append(nextRow)
        }
        layers.append(nextLayer)
    }
    
    i = 0
    while i < height {
        j = 0
        while j < width {
            for layer in layers {
                if layer[i][j] == 2 { continue }
                result[i][j] = layer[i][j]
                break
            }
            j += 1
        }
        i += 1
    }
    
    return result
}