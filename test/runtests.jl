
using AutoHashEquals

@static if !isdefined(Base, :Nothing)
    const Nothing = Void
end

@static if VERSION >= v"0.7"
    using Test
    using Serialization
    using Markdown: plain
else
    using Base.Test
    using Base.Markdown: plain
end

function sausage(x)
    buf = IOBuffer()
    serialize(buf, x)
    seekstart(buf)
    deserialize(buf)
end

@auto_hash_equals struct A
    a::Int
    b
end
@test typeof(A(1,2)) == A
@test_broken hash(A(1,2)) == hash(2,hash(1,hash(:A)))
@test A(1,2) == A(1,2)
@test A(1,2) == sausage(A(1,2))
@test A(1,2) != A(1,3)
@test A(1,2) != A(3,2)

abstract type B end
@auto_hash_equals struct C<:B x::Int end
@auto_hash_equals struct D<:B x::Int end
@test isa(C(1), B)
@test isa(D(1), B)
@test C(1) != D(1)
@test hash(C(1)) != hash(D(1))
@test C(1) == C(1)
@test C(1) == sausage(C(1))
@test hash(C(1)) == hash(C(1))

abstract type E{N<:Union{Nothing,Int}} end
@auto_hash_equals mutable struct F{N}<:E{N} e::N end
@auto_hash_equals mutable struct G{N}<:E{N}
    e::N
end
G() = G{Nothing}(nothing)
@test_broken hash(F(1)) == hash(1, hash(:F))
@test hash(F(1)) != hash(F(2))
@test F(1) == F(1)
@test F(1) == sausage(F(1))
@test F(1) != F(2)
@test_broken hash(G()) == hash(nothing, hash(:G))
@test G() == G()

macro dummy(x)
    esc(x)
end
@test @dummy(1) == 1

@auto_hash_equals mutable struct H
    @dummy h
    i
    @dummy j::Int
end
@test H(1,2,3) != H(2,1,3)
@test H(1,2,3) == H(1,2,3)
@test H(1,2,3) == sausage(H(1,2,3))
@test hash(H(1,2,3)) == hash(H(1,2,3))
@test hash(H(1,2,3)) != hash(H(2,1,3))

@auto_hash_equals struct I{A,B}
    a::A
    b::B
end
@test I{AbstractString,Int}("a", 1) == I{AbstractString,Int}("a", 1)
@test I{AbstractString,Int}("a", 1) == sausage(I{AbstractString,Int}("a", 1))

@test isequal(I(NaN, nothing), I(NaN, nothing))
@test (I(NaN, nothing) != I(NaN, nothing))

@test isequal(I(missing, nothing), I(missing, nothing))
@test missing === (I(missing, nothing) == I(missing, nothing))

@testset "use fields, not properties" begin
    @test I(1, 2) == I(1, 2)
    h = hash(I(1, 2))
    Base.getproperty(x::I, f::Symbol) = rand()
    @test h == hash(I(1, 2))
    @test I(1, 2) == I(1, 2)
end

@auto_hash_equals struct Val2{T} end
@test hash(Val2{:one}()) != hash(Val2{:two}())

module ModA
    using AutoHashEquals
    @auto_hash_equals struct Foo{T}
        x::T
    end
end

module ModB
    using AutoHashEquals
    @auto_hash_equals struct Foo{T}
        x::T
    end
end

@test ModA.Foo(1) != ModB.Foo(1)
@test hash(ModA.Foo(1)) != hash(ModB.Foo(1))

macro cond(test, block)
    if eval(test)
        block
    end
end

"""this is my data type"""
@auto_hash_equals mutable struct MyType
    field::Int
end
@test plain(@doc MyType) == "this is my data type\n"

println("ok")
