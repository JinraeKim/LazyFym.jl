"""
    sequentialise(data)

Convert an array of arrays to a concatenated array throught the first dimension.

It would be useful when plotting figures using data obtained from Transducers.

# Examples
```jldoctest
julia> using LazyFym

julia> sequentialise([[1, 2], [3, 4], [5, 6]])
3×2 Array{Int64,2}:
 1  2
 3  4
 5  6
```
"""
function sequentialise(data)
    return vcat([reshape(data[i], (1, size(data[i])...)) for i in 1:length(data)]...)
end
