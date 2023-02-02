# structured_beliefs

---
This repository contains the code for the project "Collective beliefs and trust in structured populations" by
Małgorzata Fic and Chaitanya S. Gokhale

---

## Details

In this repository, we provide 

- Julia code for simulation results

----

- Provided code can be used to recreate the simulations run for the project. 
  - Julia Release Julia 1.6.4
- Results presented in the manuscript are aggregated over 10 networks generated for a given parameter set, and 100 simulation runs for each generated network.
- Julia Packages used in the code:
  -  Graphs.jl
  -  MetaGraphs.jl
  -  Tables.jl
  -  StatsBase.jl
  -  CSV.jl
  -  Random.jl
  -  DataFrames.jl
  -  Statistics
- One run of the Simulator.jl produces a CSV. file, each line representing the population composition after a time step.
- Script provided in Averages.jl can be used to agregate data from multiple simulation runs and produce CSV files used to create figures.
- Script provided in Tipping_points.jl can be used to agregate data from multiple simulation runs and prodeuce CSV files used to create Figure 4.
