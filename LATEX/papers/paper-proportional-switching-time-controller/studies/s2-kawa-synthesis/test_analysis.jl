# Fast Julia unit checks. The real solve/export is checked independently by test_synthesis.py.
# From the paper root: task kawa-synthesis:test-synthesis
using Test
include(joinpath(@__DIR__, "analysis.jl"))

@testset "matrix JSON uses rows" begin
    matrix = [1.0 2.0 3.0; 4.0 5.0 6.0]
    encoded = JSON3.write(json_value(Dict("nested" => (matrix = matrix,))))
    rows = JSON3.read(encoded).nested.matrix
    @test length(rows) == 2
    @test collect(rows[1]) == [1.0, 2.0, 3.0]
    @test json_matrix(rows) == matrix
end

@testset "direct discrete Lyapunov certificate" begin
    A = [0.7 0.1 -0.05; 0.0 0.6 0.15; 0.02 0.0 0.5]
    rate = 0.9
    P, residual = zero_gain_certificate(A, rate)
    Id = Matrix{Float64}(I, 3, 3)
    Q = Matrix(symmetric(P - (A / rate)' * P * (A / rate)))
    @test Q ≈ tr(Q) / 3 * Id atol = 1e-12
    @test tr(inv(P)) ≈ 3 atol = 1e-12
    @test residual > 0
    certificate = check_certificate(A, zeros(3, 2), zeros(2, 3), P)
    @test maximum(certificate["Pnorm_rates"]) < rate
    @test_throws ErrorException check_certificate(Id, zeros(3, 2), zeros(2, 3), Id)
    @test_throws ErrorException check_certificate(A, zeros(3, 2), zeros(2, 3), -Id)
end
