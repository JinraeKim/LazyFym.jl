using LazyFym
using DifferentialEquations
using Transducers
using InfiniteArrays
using LinearAlgebra

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
function postprocess(x)
    (; x=x)
end
LazyFym.initial_condition(env::Env1) = rand(2)
LazyFym.initial_condition(env::Env21) = rand(5, 3)
LazyFym.initial_condition(env::Env22) = rand(10)
env = NestedEnv(Env1(), Env2(Env21(), Env22()))
x0 = LazyFym.initial_condition(env)
_x0 = LazyFym.raw(env, x0)

function f(x, p, t)
    dx1 = -p[1]*x.env1
    dx21 = -p[2]*x.env2.env21
    dx22 = -p[3]*x.env2.env22
    (; env1 = dx1, env2 = (; env21 = dx21, env22 = dx22))
end
env_index_nt, env_size_nt = LazyFym.preprocess(env, x0)
function _f(_x, p, t)
    LazyFym.raw(env, f(LazyFym.process(_x, env_index_nt, env_size_nt), p, t))
end
macro f_ode(f, env)
    ex = quote
        x0 = LazyFym.initial_condition($env)
        env_index_nt, env_size_nt = LazyFym.preprocess($env, x0)
        (_x, p, t) -> LazyFym.raw($env, $f(LazyFym.process(_x, env_index_nt, env_size_nt), p, t))
    end
    ex
end
function _my_macro(f, env::Fym)
    x0 = LazyFym.initial_condition(env)
    env_index_nt, env_size_nt = LazyFym.preprocess(env, x0)
    return :((_x, p, t) -> LazyFym.raw($env, $f(LazyFym.process(_x, $env_index_nt, $env_size_nt), p, t)))
end
function ode(prob::ODEProblem, env)
    ex = :()
    eval(ex)
end
macro raw(x0, env)
    :(LazyFym.raw($env, $x0))
end
macro process(_x0, env)
    ex = quote
        x0 = LazyFym.initial_condition($env)
        env_index_nt, env_size_nt = LazyFym.preprocess($env, x0)
        LazyFym.process($_x0, env_index_nt, env_size_nt)
    end
    ex
end
macro ode(ex, env)
    :($(ex.args[1])(@f_ode($(ex.args[2]), $env), @raw($(ex.args[3]), $env), $(ex.args[4])))
end
function DifferentialEquations.ODEProblem(env::Fym, f, x0, tspan; kwargs...)
    env_index_nt, env_size_nt = LazyFym.preprocess(env, x0)
    _x0 = LazyFym.raw(env, x0)
    _f(_x, p, t) = LazyFym.raw(env, f(LazyFym.process(_x, env_index_nt, env_size_nt), p, t))
    ODEProblem(_f, _x0, tspan; kwargs...)
end
function my_process(env::Fym, dummy)
    x0 = dummy == nothing ? error("Give an example (dummy) to understand the structure of $(typeof(env))") : dummy
    env_index_nt, env_size_nt = LazyFym.preprocess(env, x0)
    process(_x) = LazyFym.process(_x, env_index_nt, env_size_nt)
end
t0 = 0.0
tf = 10.0
tspan = (t0, tf)
p0 = [1.0, 2, 3]
prob = ODEProblem(env, f, x0, tspan)
sol = solve(prob, Tsit5(); p=p0, saveat=t0:0.01:tf)
process = my_process(env, x0)
xs = sol.u |> Map(process) |> collect

LazyFym.@register env x0  # necessary
function test()
    t2 = 0.1
    x_at_t2 = LazyFym.@readable env sol(t2)
    x_all = LazyFym.@readable env sol.u
    _x_at_t2 = LazyFym.@raw env x_at_t2
    @show x_at_t2
    @show _x_at_t2
    @show x_all == xs
end
test()
nothing
