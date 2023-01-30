using Graphs, MetaGraphs
using Tables, StatsBase
using CSV, Random


function populate(
    g::Graph,
    initial,
    α,
    initial_actions_1,
    initial_belief_1,
    initial_actions_2,
    initial_belief_2,
    final_nodes,
)
    mg = MetaGraph(g)
    a = shuffle!(Vector(1:final_nodes)) #randomize how initial strategies are situated
    for i in a[1:initial] #first initial strategy on \initial nodes
        special_degree = exp(α * degree(mg, i)) #value used to determine probability of getting a belief mutation
        set_props!(
            mg,
            i,
            Dict(
                :actions => initial_actions_1,
                :belief => initial_belief_1,
                :exp_degree => special_degree,
            ),
        )
    end
    for i in a[initial+1:end] #second initial strategy on the rest of the network
        special_degree = exp(α * degree(mg, i))
        set_props!(
            mg,
            i,
            Dict(
                :actions => initial_actions_2,
                :belief => initial_belief_2,
                :exp_degree => special_degree,
            ),
        )
    end
    for i in a #get probability of belieg mutation depending on connectivity of focal player and all neighbours
        sum_beliefs =
            get_prop(mg, i, :exp_degree) +
            sum([get_prop(mg, j, :exp_degree) for j in neighbors(mg, i)])
        set_prop!(
            mg,
            i,
            :prob_belief,
            get_prop(mg, i, :exp_degree) / sum_beliefs,
        )
    end
    return mg
end

#single instance of the stag hunt
function single_game(focal_player, P_h, P_s, M, ω, mg)
    involved_players = [i for i in neighbors(mg, focal_player)] #all neighbours of a player take part in the game
    append!(involved_players, focal_player) #add focal player to the hunting party
    reality_determiner = sample(involved_players) #choose random player in the group who's belief is accepted as a group belief
    reality = get_prop(mg, reality_determiner, :belief) #set the group belief
    payoff = P_h #if the player is not a stag hunter the defoult payoff is hare payoff
    if get_prop(mg, focal_player, :actions)[reality] == 2 #the payoff can change if the focal player is a stag hunter i the collectively chosen narrative
        stag_players = sum([
            1 for player in involved_players if
            get_prop(mg, player, :actions)[reality] == 2
        ])  #determine a number of stag hunters in the given narrative
        payoff = 0
        if stag_players >= M #check if the number of stag hunters passes the treshold
            payoff = P_s
        end
    end
    focal_fitness = 1 + ω * (payoff) #fitness including the selection intensity
    set_prop!(mg, focal_player, :fitness, focal_fitness) #set the fitness of the focal player
    return mg
end

#get fitness of all the players and determine the probability of having an offspring
function get_fitness(P_h, P_s, M, mg, ω, final_nodes)
    sum_fitness = 0
    for i in Vector(1:final_nodes) #determine fitness of every player
        mg = single_game(i, P_h, P_s, M, ω, mg)
        sum_fitness += get_prop(mg, i, :fitness)
    end
    prob_vector =
        [get_prop(mg, i, :fitness) / sum_fitness for i in Vector(1:final_nodes)] #get a vector of fitness relative to fitness sum
    proba = pweights(prob_vector)
    return proba, mg
end

#the birth death process
function birth_death(player, μ_1, mg)
    involved = [i for i in neighbors(mg, player)]#determine which players can be replaced
    append!(involved, player) #the focal player can also be chosen for death
    dying = sample(involved) #determine which player will die
    new_actions = get_prop(mg, player, :actions) #get actions of reproducing individual
    new_belief = get_prop(mg, player, :belief) #get belief of the reproducing individual
    if rand(Float64) < μ_1 #is action mutation taking place?
        new_actions = sample([1, 2], 2, replace = true) #determine new actions after mutatin
    end
    set_props!(mg, dying, Dict(:actions => new_actions, :belief => new_belief)) #replace the dying individual with the new offspring
    return mg
end

#the full run of the game
function game_run(
    g,
    Gens,
    P_h,
    P_s,
    M,
    final_nodes,
    μ_1,
    μ_2,
    α,
    ω,
    initial,
    initial_actions_1,
    initial_belief_1,
    initial_actions_2,
    initial_belief_2,
    plot,
    run,
    network_type,
)
    mg = populate(
        g::Graph,
        initial,
        α,
        initial_actions_1,
        initial_belief_1,
        initial_actions_2,
        initial_belief_2,
        final_nodes,
    )
    gen = 0
    strats = [
        vcat(get_prop(mg, i, :actions), get_prop(mg, i, :belief)) for
        i in Vector(1:final_nodes)
    ]
    #create the file with population composition.  Naming of the file assumes that the first type of the player introduced is HH1
    CSV.write(
        "Beliefs_$(network_type)_HH1_$(initial)_$(α)_$(ω)_$(μ_1)_$(μ_2)_$(plot)_$(run).csv",
        Tables.table(transpose(strats)),
        header = false,
        append = false,
        delim = ',',
    )
    while gen < Gens
        for play in Vector(1:final_nodes) #the birth death takes place Z times in each time step
            #check if mutation on beliefs occured
            if rand(Float64) < μ_2
                probabilities = [
                    get_prop(mg, i, :prob_belief) for
                    i in Vector(1:final_nodes)
                ] #check probabilities of belief mutation of all the players
                mutant = sample(Vector(1:final_nodes), pweights(probabilities)) #choose a player to introduce the belief mutation
                set_prop!(mg, mutant, :belief, sample([1, 2])) #mutation of the belief
            end
            proba, mg = get_fitness(P_h, P_s, M, mg, ω, final_nodes) #check fitness and the probability of reproduction of all the players
            player = sample(Vector(1:final_nodes), proba) #choose a player to reproduce
            mg = birth_death(player, μ_1, mg) #perform the birth dith process
        end
        gen += 1
        strats = [
            vcat(get_prop(mg, i, :actions), get_prop(mg, i, :belief)) for
            i in Vector(1:final_nodes)
        ] #save the population composition after the time step.
        CSV.write(
            "Beliefs_$(network_type)_HH1_$(initial)_$(α)_$(ω)_$(μ_1)_$(μ_2)_$(plot)_$(run).csv",
            Tables.table(transpose(strats)),
            append = true,
            delim = ',',
        )
    end
end



initial = 32 #initial number of individuals with initial_action_1 and initial_belief_1
α = 0.01
final_nodes = 32 #number of nodes in the network
μ_2 = 0.00001 #rate of belief mutation
μ_1 = 0.001 #rate of action mutations
P_h = 1 #value of a hare
P_s = 4 #value of the stag
M = 4 #treshholf for the stag hunt to be succesful
ω = 1.0 #selectoion intensity
Gens = 10 #^5 #number of timesteps in the population
graph = 1 #tracking of the number of graphs generated with given parameters
n_runs = 1 #tracking number of runs performed on a given network

#use while generating WS network
network_type = "WS"
avg_con = 8 #average connectivity in WS network
g = watts_strogatz(final_nodes, avg_con, 0.05)

#use while generating BA network
#network_type = "BA"
#min_con = 4 #minimal connectivity of the BA network
#g=complete_graph(min_con)
#barabasi_albert!(g, final_nodes, min_con)


#use while generating ER network
#network_type = "ER"
#g=erdos_renyi(final_nodes, 0.25) #use while generating BA network


initial_actions_1 = [1, 1] #actions of the first type initially introduced in the network
initial_belief_1 = 1 #belief of the first type initially introduced in the network
initial_actions_2 = [2, 1] #actions of the second type initially introduced in the network
initial_belief_2 = 1 #belief of the second type initially introduced in the network

game_run(
    g,
    Gens,
    P_h,
    P_s,
    M,
    final_nodes,
    μ_1,
    μ_2,
    α,
    ω,
    initial,
    initial_actions_1,
    initial_belief_1,
    initial_actions_2,
    initial_belief_2,
    graph,
    n_runs,
    network_type,
)
