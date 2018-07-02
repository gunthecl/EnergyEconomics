using NamedArrays
using JuMP
using Gurobi

NODES = collect(1:6)
SLACK = 6
DEM_NODES = [3,5,6]
SUP_NODES = [1,2,4]
LINES = ["1-3","1-2","2-3","1-6","2-5","5-6","4-5","4-6"]

PRICE_ZONES = Dict("Z1" => [1,2,3], "Z2" => [4,5,6])#, "Z3" => [2], "Z4" => [6])

NODES_IN_ZONE = Dict()
for node in NODES, zone in keys(PRICE_ZONES)
    if node in PRICE_ZONES[zone]
        NODES_IN_ZONE[node] = zone
    end
end

ptdf_array =[
 0.125  -0.1667  -0.5208  -0.0208  -0.0417  0.0;
 0.25   -0.3333  -0.0417  -0.0417  -0.0833  0.0;
 0.125  -0.1667   0.4792  -0.0208  -0.0417  0.0;
 0.625   0.5      0.5625   0.0625   0.125   0.0;
 0.375   0.5      0.4375  -0.0625  -0.125   0.0;
 0.25    0.3333   0.2917   0.2917   0.5833  0.0;
 0.125   0.1667   0.1458  -0.3542   0.2917  0.0;
 0.125   0.1667   0.1458   0.6458   0.2917  0.0;
 ]

ptdf = NamedArray(ptdf_array, (LINES, NODES), ("Lines","Nodes"))

a = Dict(collect(zip(NODES, [10;15;37.5;42.5;75;80])))
b = Dict(collect(zip(NODES, [0.05;0.05;-0.05;0.025;-0.1;-0.1])))

cap = Dict("1-6" => 200, "2-5" => 250)

Ehrenmann = Model(solver=GurobiSolver())
@variables Ehrenmann begin
    Q[NODES] >= 0
    INJ[NODES]
    FLOWS
    PRICE[keys(PRICE_ZONES)]
end

@objective(Ehrenmann, Max,
    sum((a[dem_node] + 0.5*b[dem_node]*Q[dem_node])*Q[dem_node]
    for dem_node in DEM_NODES)
    - sum((a[sup_node] + 0.5*b[sup_node]*Q[sup_node])*Q[sup_node]
    for sup_node in SUP_NODES)
    );

@constraint(Ehrenmann, EnergyBalance[node=NODES],
    sum(Q[sup_node] for sup_node in intersect(node, SUP_NODES)) -
    sum(Q[dem_node] for dem_node in intersect(node, DEM_NODES)) == INJ[node]
    );

@constraint(Ehrenmann, Slack,
    sum(INJ[node] for node in setdiff(NODES, SLACK)) == -INJ[SLACK]
    );

@constraintref CapacityConstraints[1:length(keys(cap))*2]
i = 1
for line in LINES
    if line in keys(cap)
        CapacityConstraints[i] = @constraint(Ehrenmann,
            sum(ptdf[line, node]*INJ[node] for node in NODES) <= cap[line]
        );
        i = i + 1
        CapacityConstraints[i] = @constraint(Ehrenmann,
            sum(ptdf[line, node]*INJ[node] for node in NODES) >= -cap[line]
        );
        i = i + 1
    end
end

@constraint(Ehrenmann, ZonalPrice[node=NODES],
    a[node]+b[node].*Q[node] == PRICE[NODES_IN_ZONE[node]]
    );

solve(Ehrenmann)
results = Dict()
results["objective"]    = getobjectivevalue(Ehrenmann)
results["quantity"]     = NamedArray(getvalue(Q).innerArray)
results["prices_dual"]  = NamedArray(getdual(EnergyBalance).innerArray)
# a+b*q, as seen in section 2.2 on page 6
results["prices_marg"]  = [10;15;37.5;42.5;75;80] +
                         [0.05;0.05;-0.05;0.025;-0.1;-0.1].*results["quantity"]
results["price"]        = NamedArray(getvalue(PRICE).innerArray)
results["netinjection"] = getvalue(INJ).innerArray
results["flows"]        = ptdf*results["netinjection"]
