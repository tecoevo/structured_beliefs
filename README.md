# structured_beliefs

---
This repository contains the code for the project "Collective beliefs and trust in structured populations" by
Małgorzata Fic and Chaitanya S. Gokhale

---

## Details

In this repository we provide 

- Julia code for simulation results

----

- Provided code can be used to recreate the simulations run for project. 
  - Julia Release Julia 1.6.4
- Results presented in the manuscript are agregated over 10 networks generated for a given parameter set and 100 simulations runs on each network generated.
- Julia Packages used in the code:
  -  Graphs.jl
  -  MetaGraphs.jl
  -  Tables.jl
  -  StatsBase.jl
  -  CSV.jl
  -  Random.jl
- One run of the code produces a CSV. file, each line of the file representing the population composition after a time step. 
