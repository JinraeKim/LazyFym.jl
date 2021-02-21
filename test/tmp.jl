using LazyFym
using Transducers

struct MyT <: FymEnv
    syss
end

struct Syss <: FymEnv
    sys1
    sys2
end

struct Sys1 <: FymSys
    a
end

LazyFym.initial_condition(sys::Sys1) = [1, 2, 3]
syss = Syss(Sys1(1), Sys1(2))
myt = MyT(syss)
x0 = LazyFym.initial_condition(myt)
LazyFym.size(myt, x0)
LazyFym.index(myt, x0)

@show initial_condition(syss)
res = initial_condition(myt)
