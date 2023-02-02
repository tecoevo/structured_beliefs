using DataFrames, CSV, Statistics

strategies = ["[1 1 1]" "[1 1 2]" "[1 2 1]" "[1 2 2]" "[2 1 1]" "[2 1 2]" "[2 2 1]" "[2 2 2]"]

initial = 32
network = "WS"
α =0.0
μ_1 = 0.001
n_graphs = 10
Runs = 100

for ω in [1.0]
    for μ_2 in [0.01]
        time_list = []
        stacked_bar_data = [0 0 0 0 0 0 0 0]
        for plot in 1:n_graphs
            for run in 1:Runs
                data = CSV.read("Beliefs_$(network)_HH1_$(initial)_$(α)_$(ω)_$(μ_1)_$(μ_2)_$(plot)_$(run).csv", DataFrame, delim=',', header=false) #load simulation results
                a = [sum([count(i->(i==strat), data[:,j])/(nrow(data)) for j in ncol(data)]) for strat in strategies] #determine population composition in every timestep
                #println(a)
                stacked_bar_data = stacked_bar_data + a
                for i in 1:nrow(data) #find first time point with no hare hunters
                    if "[1 1 1]" ∉ data[i, :] && "[1 1 2]" ∉ data[i, :] && "[1 2 1]" ∉ data[i, :] && "[2 1 2]" ∉ data[i, :] && i != nrow(data)
                        append!(time_list, i-1)
                        break
                    end
                end
                println(run)
            end
            println(plot)
        end
        #agregate data
        ultimate_bar = [stacked_bar_data[i]/(n_graphs*Runs) for i in Vector(1:8)]
        time_value = mean(time_list)
        number_fixed = size(time_list)
        full_data = [ultimate_bar, time_value, number_fixed[1]]
        println(μ_2)
        CSV.write("$(network)_HH1_$(initial)_$(α)_$(ω)_$(μ_1)_$(μ_2).csv" , Tables.table(full_data), header=false, append=false, delim=',') #save file with agregated sata
    end
end
