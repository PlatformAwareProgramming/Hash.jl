# ------------------------------------------------------------------
# Licensed under the MIT License. See LICENCE in the project root.
# ------------------------------------------------------------------

using Hash
using Test

# list of tests
testfiles = [
    "basics.jl"
]

@testset "Hash.jl" begin
    for testfile in testfiles
        println("Testing $testfile...")
        include(testfile)
    end
end