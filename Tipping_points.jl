using DataFrames, CSV, Statistics
using Peaks

strategies = ["[1 1 1]" "[1 1 2]" "[1 2 1]" "[1 2 2]" "[2 1 1]" "[2 1 2]" "[2 2 1]" "[2 2 2]"]

function get_timeseries(network, α, μ_2, plots, runs) #get population composition in each time step until stag hunters take over
    stacked_bar_data = [0 0 0 0 0 0 0 0]
    data = CSV.read("Beliefs_$(network)_HH1_$(initial)_$(α)_$(ω)_$(μ_1)_$(μ_2)_$(plots)_$(runs).csv", DataFrame, delim=',', header=false)
    stags = []
    belief = []
    for k in 1:nrow(data)
        time_step = [count(i->(i==strat), data[k,:]) for strat in strategies]
        stags_single = sum(time_step[:,i] for i in [4, 5, 7, 8])[1]
        #belief_single = sum(time_step[:,i] for i in [2, 4, 6, 8])[1]
        append!(stags, stags_single)
        #append!(belief, belief_single)
        if stags_single == 32
            break
        end
    end
    return stags
end

initial = 32
ω = 1.0
μ_1 = 0.001
initial = 32

peaks = []
for network in ["WS"]
    for α in [2.0, 0.0, -2.0]
        for μ_2 in [0.00001, 0.0001, 0.001, 0.01]
            peaks = []
            for plots in 1:10
                for runs in 1:100
                    strat = get_timeseries(network, α, μ_2, plots, runs)
                    #find the tipping point
                    tipping = minimum(findall(candidate->intersect(findall(x->strat[x]==candidate, 1:size(strat)[1]), findall(x->all(<=(candidate),first(strat, x-1)), 1:size(strat)[1]), findall(x->all(>=(candidate),last(strat, size(strat)[1]-x)), 1:size(strat)[1]))!=[], 1:32))
                    append!(peaks, tipping)
                    println(runs,plots)
                end
            end
            peak = mean(peaks)
            variance = var(peaks)
            full = [peak, variance]
            CSV.write("tipping_$(network)_HH1_$(initial)_$(α)_$(ω)_$(μ_1)_$(μ_2)_2.csv" , Tables.table(full), header=false, append=false, delim=',')
        end
    end
end
