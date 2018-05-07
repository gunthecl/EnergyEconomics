# Homework 1

**Due Date**: May 14

## Task 1 Marginal Costs

Resulting marginal costs are:

Technologies  | Marginal Costs

Nuclear       | 19.0909
Lignite       | 23.5787
Hard coal     | 33.5971
Natural gas   |  56.085

Resulting dispatch:
\includegraphics[]{dispatch.png}

- Nuclear (lowest MC) always gets dispatched at full capacity, followed by lignite (almost const. full capacity) and some hard coal dispatch
- natural gas only gets dispatched at high peak
- storage level is increased from zero to max. capacity in first five period (low demand) and decreased to zero in peak demand period
- we use generation from storage to partly substitute natural gas (high mc)
- total costs are 36,325.8
\includegraphics[]{dispatch_2a.png}


## Task 2 Storages
Describe and explain the differences in a few sentences.

** Set the storage level to 50 percent in the first time step**
- dispatch plan very similar to that of task 1. Difference occur in the first period were we use less lignite capacity since less electricity is needed to reach the max. storage level
- total costs are 36124.8, which is roughly 200 lower compared to task 1. Cost difference occurs since we essentially get "electricity for free" by assuming the initial storage level to be 7.5 and do not impose an end condition.
\includegraphics[]{dispatch_2b.png}

** Set the storage level to 50 percent in the first and last time step**
- dispatch plan very similar to that of task 2a. Differences occur in the storage level patterns. Storage level is decreased to zero at peak demand but increased again to 7.5 in last period
- total costs are 36466.7, which are highest overall costs. High costs occur because of efficiency losses in storage. To reach the end storage level of 7.5 we must pay more than we gain by using the initially stored energy. 

** Force the start- and endlevel to be equal, without specifying a value**
- same dispatch schedule and total costs as in task 1 
- this means that if storage can act only as to shift generation between periods, the min storage level is optimal as starting condition 
\includegraphics[]{dispatch_2c.png}

## Task 3 Renewables

 

