
# Ehrenmann Smeers Example
# LINES = ["1-3","1-2","2-3","1-6","2-5","5-6","4-5","4-6"]
# SLACK = 6
# NODES = collect(1:6)
# incedence = [1 0 -1 0 0 0; # 1 - 3
#             1 -1 0 0 0 0; # 1 - 2
#             0 1 -1 0 0 0; # 2 - 3
#             1 0 0 0 0 -1; # 1 - 6
#             0 1 0 0 -1 0; # 2 - 5
#             0 0 0 0 1 -1; # 5 - 6
#             0 0 0 1 -1 0; # 4 - 5-
#             0 0 0 1 0 -1; # 4 - 6
#             ]
# b_vector = [1;1;1;0.5;0.5;1;1;1]

# Three Node Example
SLACK = 2
NODES = collect(1:3)
incedence = [1 0 -1;
             1 -1 0;
             0 1 -1]

b_vector = [1;1;1]
B = Diagonal(b_vector)
Bl = B*incedence # Line suceptance Matrix
Bn = (incedence'*B)*incedence # Nodes suceptance Matrix

B_inv = zeros(length(NODES),length(NODES))
B_inv[setdiff(NODES,SLACK), setdiff(NODES,SLACK)] = inv(Bn[setdiff(NODES,SLACK), setdiff(NODES,SLACK)])
PTDF = Bl*B_inv


 INJ = [1;10;50]
 flow = PTDF*INJ
