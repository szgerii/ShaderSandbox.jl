mutable struct AverageQueue{T<:Number}
    mem::Vector{T}
    capacity::UInt
    _size::UInt
    _sum::T
    _curr_idx::UInt

    AverageQueue{T}(capacity::UInt) where T<:Number = new{T}(Vector{T}(), capacity, 0, 0, 1)
    AverageQueue{T}(capacity::Any) where T<:Number = AverageQueue{T}(convert(UInt, capacity))
end

function add!(queue::AverageQueue{T}, el::T) where T<:Number
    if queue._size >= queue.capacity
        queue._sum -= queue.mem[queue._curr_idx]
        queue.mem[queue._curr_idx] = el
    else
        push!(queue.mem, el)
        queue._size += 1
    end

    queue._sum += el
    queue._curr_idx += 1

    # we (over)wrote every element in the array, the last element now is at the first idx
    if queue._curr_idx > queue.capacity
        queue._curr_idx = 1
    end
end

add!(queue::AverageQueue{T}, el::Number) where T<:Number = add!(queue, convert(T, el))

function avg(queue::AverageQueue{T})::Union{T,Nothing} where T<:Number
    if queue._size == 0
        return nothing
    end

    return queue._sum / queue._size
end
