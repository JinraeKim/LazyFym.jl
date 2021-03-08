using LazyFym
using DifferentialEquations
using Plots
using Transducers

struct Env1 <: Fym
end
struct Env21 <: Fym
end
struct Env22 <: Fym
end
struct Env2 <: Fym
    env21::Env21
    env22::Env22
end
struct NestedEnv <: Fym
    env1::Env1
    env2::Env2
end
LazyFym.initial_condition(env::Env1) = 1
LazyFym.initial_condition(env::Env21) = rand(5, 3)
LazyFym.initial_condition(env::Env22) = rand(100)
nestedenv = NestedEnv(Env1(), Env2(Env21(), Env22()))
x0 = LazyFym.initial_condition(nestedenv)
_x0 = LazyFym.raw(nestedenv, x0)

function f(x, t)
    dx1 = -x.env1
    dx21 = -x.env2.env21
    dx22 = -x.env2.env22
    (; env1 = dx1, env2 = (; env21 = dx21, env22 = dx22))
end
env_index_nt, env_size_nt = LazyFym.preprocess(nestedenv, x0)
_f(_x, p, t) = LazyFym.raw(nestedenv, f(LazyFym.process(_x, env_index_nt, env_size_nt), t))
tspan = (0.0, 100.0)
prob = ODEProblem(_f, _x0, tspan)
@time sol = solve(prob, Tsit5(), saveat=0:0.01:100)
xs = sol.u |> Map(_x -> LazyFym.process(_x, env_index_nt, env_size_nt)) |> collect
nothing

# f(x, p, t) = 1.01 * x
# x0 = rand(4, 2)
# tspan = (0.0, 1.0)
# prob = ODEProblem(f, x0, tspan)
# sol = solve(prob, Tsit5())
# plot(sol)
