const DecisionVariable = String

struct DecisionVariables{T}
    names::Vector{DecisionVariable}
    decisions::Vector{T}

    function DecisionVariables(::Type{T}) where T <: AbstractFloat
        return new{T}(Vector{DecisionVariable}(), Vector{T}())
    end

    function DecisionVariables(names::Vector{String}, ::Type{T}) where T <: AbstractFloat
        return new{T}(names, zeros(T, length(names)))
    end

    function DecisionVariables(names::Vector{String}, decisions::Vector{T}) where T <: AbstractFloat
        return new{T}(names, decisions)
    end
end

function decision_names(decision_variables::DecisionVariables)
    return decision_variables.names
end

function decisions(decision_variables::DecisionVariables)
    return decision_variables.decisions
end

function set_decision_variables!(decision_variables::DecisionVariables{T}, names::Vector{DecisionVariable}) where T <: AbstractFloat
    empty!(decision_variables.names)
    append!(decision_variables.names, names)
    empty!(decision_variables.decisions)
    append!(decision_variables.decisions, zeros(T, length(names)))
    return nothing
end

function set_decision_variables!(decision_variables::DecisionVariables{T}, origin::JuMP.Model) where T <: AbstractFloat
    n = num_variables(origin)
    resize!(decision_variables.names, n)
    for i in 1:n
        decision_variables.names[i] = name(VariableRef(origin, MOI.VariableIndex(i)))
    end
    empty!(decision_variables.decisions)
    append!(decision_variables.decisions, zeros(T, n))
    return nothing
end

function get_decision_variables(model::JuMP.Model)
    !haskey(model.ext, :decisionvariables) && error("No decision variables in model")
    return model.ext[:decisionvariables]
end

function clear_decision_variables!(decision_variables::DecisionVariables)
    empty!(decision_variables.names)
    empty!(decision_variables.decisions)
    return nothing
end

function add_decision_variable(model::JuMP.Model, name::String)
    decision_variables = get_decision_variables(model)
    index = findfirst(d -> d == name, decision_variables.names)
    index == nothing && error("No matching decision variable with name $name.")
    return DecisionRef(model, MOI.VariableIndex(index))
end

function extract_decision_variables(model::JuMP.Model, decision_variables::DecisionVariables{T}) where T <: AbstractFloat
    termination_status(model) == MOI.OPTIMAL || error("Model is not optimized, cannot extract decision variables.")
    length(decision_variables.names) > 0 || error("No decision variables.")
    decision = zeros(T, length(decision_variables.names))
    for (i,dvar) in enumerate(decision_variables.names)
        var = variable_by_name(model, dvar)
        var == nothing && error("Decision variable $dvar not in given model.")
        decision[i] = value(var)
    end
    return decision
end

function update_decision_variables!(model::JuMP.Model, x::AbstractVector)
    !haskey(model.ext, :decisionvariables) && error("No decision variables in model")
    update_decision_variables!(model.ext[:decisionvariables], x)
    return nothing
end

function update_decision_variables!(decision_variables::DecisionVariables, x::AbstractVector)
    length(decision_variables.decisions) == length(x) || error("Given decision of length $(length(x)) not compatible with defined decision variables of length $(length(decision_variables.decisions)).")
    decision_variables.decisions .= x
    return nothing
end

function Base.copy(decision_variables::DecisionVariables)
    return DecisionVariables(copy(decision_variables.names), decision_variables.decisions)
end

include("decision_variable.jl")
include("aff_expr.jl")
include("constraint.jl")
include("bridge.jl")
include("operators.jl")
include("mutable_arithmetics.jl")