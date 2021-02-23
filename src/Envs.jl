"""
This module provides pre-defined environments describing known dynamical systems.
"""
module Envs

using LinearAlgebra
using Parameters
using LazyFym: Fym
import LazyFym: size, flatten_length, index  # to improve the simulation speed


"""
An example of continuous-time nonlinear dynamical system introduced in
several studies on approximate dynamic programming.
# Reference
[1] K. G. Vamvoudakis and F. L. Lewis, “Online Actor-Critic Algorithm to Solve the Continuous-Time Infinite Horizon Optimal Control Problem,” Automatica, vol. 46, no. 5, pp. 878–888, 2010, doi: 10.1016/j.automatica.2010.02.018.
[2] V. Nevistic and J. A. Primbs, “Constrained Nonlinear Optimal Control: a Converse HJB Approach,” 1996.
"""
@with_kw struct InputAffineQuadraticCostEnv <: Fym
    Q = Matrix(I, 2, 2)
    R = 1
    P = [0.5 0; 0 1]
end

function f(env::InputAffineQuadraticCostEnv, x)
    x1 = x[1]
    x2 = x[2]
    f1 = -x1 + x2
    f2 = -0.5x1 -0.5(1-(cos(2x1)+2)^2)
    return  [f1, f2]
end

function g(env::InputAffineQuadraticCostEnv, x)
    x1 = x[1]
    g1 = 0
    g2 = cos(2x1 +2)
    return [g1, g2]
end

function V_optimal(env::InputAffineQuadraticCostEnv, x)
    return x'*env.P*x
end

function u_optimal(env::InputAffineQuadraticCostEnv, x)
    _g = g(env, x)
    return -_g'*env.P*x
end

function ẋ(env::InputAffineQuadraticCostEnv, x, t, u)
    ẋ = f(env, x) + g(env, x)*u
    return ẋ
end

_size = (2,)
_flatten_length = 2
_index = 1:2
size(env::InputAffineQuadraticCostEnv, x) = _size
flatten_length(env::InputAffineQuadraticCostEnv, x) = _flatten_length
index(env::InputAffineQuadraticCostEnv, x) = _index

end  # module
