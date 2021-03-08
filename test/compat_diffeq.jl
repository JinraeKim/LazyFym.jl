using LazyFym
using DifferentialEquations
using Plots
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
LazyFym.initial_condition(env::Env1) = 1
LazyFym.initial_condition(env::Env21) = rand(5, 3)
LazyFym.initial_condition(env::Env22) = rand(10)
nestedenv = NestedEnv(Env1(), Env2(Env21(), Env22()))
x0 = LazyFym.initial_condition(nestedenv)
_x0 = LazyFym.raw(nestedenv, x0)

function f(x, p, t)
    dx1 = -p[1]*x.env1
    dx21 = -p[2]*x.env2.env21
    dx22 = -p[3]*x.env2.env22
    (; env1 = dx1, env2 = (; env21 = dx21, env22 = dx22))
end
env_index_nt, env_size_nt = LazyFym.preprocess(nestedenv, x0)
_f(_x, p, t) = LazyFym.raw(nestedenv, f(LazyFym.process(_x, env_index_nt, env_size_nt), p, t))
tspan = (0.0, 100.0)
prob = ODEProblem(_f, _x0, tspan)
p0 = [1.0, 2, 3]
dosetimes = 0:0.01:tspan[end]
affect!(integrator) = integrator.p = integrator.p .+ 1e-3*integrator.t
cb_param_update = PresetTimeCallback(dosetimes, affect!)
saved_values = SavedValues(Float64, NamedTuple)
cb_save = SavingCallback((u, t, integrator) -> (; u=u, p=integrator.p), saved_values, saveat=0:0.01:100)
terminate_condition(u, t, integrator) = norm(u) - 1e-3  # == 0
terminate_affect!(integrator) = terminate!(integrator)
cb_terminate = ContinuousCallback(terminate_condition, terminate_affect!)
cbset = CallbackSet(cb_param_update, cb_save, cb_terminate)
@time sol = solve(prob, Tsit5(); p=p0, callback=cbset)
xs = sol.u |> Map(_x -> LazyFym.process(_x, env_index_nt, env_size_nt)) |> collect
plot(sol)
