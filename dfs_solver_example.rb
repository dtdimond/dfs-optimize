# This is an example daily fantasy football optimization problem using rglpk,
#  a linear programming solver ruby gem. The purpose is to optimize the projected
#  DFS score given 2 WRs, 2 RBs, and 1 K but only slots for 1 RB, 1 WR, 1 RB/WR Flex, and 1 K.
#  That's 5 players but only 4 lineup slots.
#
# The method:
# First define the rows and their bounds. These correspond to the number of slots
# available. We setup duplicates for each position to allow an upper and lower bound for
# that position (number of slots) to allow for the possibility of a flex in that position.
# Note that we even have a duplicate for the K, though it can't be flexed. This could
# also be accomplished by having just one, and setting a FX bound.
#
# Next define the columns and their types. These correspond to the players available to choose
# from and their variables are binary 1 or 0 indicating whether they are in the lineup or not.
#
# Next setup the objective coefficients. This is the projected points for each player and is
# the function to maximize.
#
# Finally we propagate the matrix to fill in the values of the rows/columns we've created.
# The top row is the cost constraint, and the subsequent rows (except last) are rows
# indicating the position of each column (player). The last row indicates whether a player
# is flexable or not.
#
# Lastly, we let the solver do it's work. Note that this is a mixed integer programming
# problem, as at least some of the variables are constrained to be integers (in this case all).
# We still have to call p.simplex and the p.mip to get the result.

require 'rglpk'
require 'pry'

p = Rglpk::Problem.new
p.name = "dfs_optimize"
p.obj.dir = Rglpk::GLP_MAX

rows = p.add_row
p.rows[0].name = "cost_constraint"
p.rows[0].set_bounds(Rglpk::GLP_UP, 0, 100)
rows = p.add_row
p.rows[1].name = "wr_constraint"
p.rows[1].set_bounds(Rglpk::GLP_LO, 1, nil) #require at least 1 qb
rows = p.add_row
p.rows[2].name = "wr_constraint_flex"
p.rows[2].set_bounds(Rglpk::GLP_UP, nil, 2) #require at most 2 qbs
rows = p.add_row
p.rows[3].name = "rb_constraint"
p.rows[3].set_bounds(Rglpk::GLP_LO, 1, nil) #require at least 1 rb
rows = p.add_row
p.rows[4].name = "rb_constraint_flex"
p.rows[4].set_bounds(Rglpk::GLP_UP, nil, 2) #require at most 2 rbs
rows = p.add_row
p.rows[5].name = "k_constraint"
p.rows[5].set_bounds(Rglpk::GLP_LO, 1, nil) #require at least 1 k
rows = p.add_row
p.rows[6].name = "k_constraint_flex" #no flex - UP bound is same as LO bound
p.rows[6].set_bounds(Rglpk::GLP_UP, nil, 1) #require at most 1 k
rows = p.add_row
p.rows[7].name = "num_flexable_constraint"
p.rows[7].set_bounds(Rglpk::GLP_FX, 3, 3)


cols = p.add_cols(5)
cols[0].name = "x1"
cols[0].kind = Rglpk::GLP_BV
cols[1].name = "x2"
cols[1].kind = Rglpk::GLP_BV
cols[2].name = "x3"
cols[2].kind = Rglpk::GLP_BV
cols[3].name = "x4"
cols[3].kind = Rglpk::GLP_BV
cols[4].name = "x5"
cols[4].kind = Rglpk::GLP_BV

#              wr, wr, rb, rb, k
p.obj.coefs = [17, 11, 19, 12, 10]

p.set_matrix([
 5, 9, 7, 2, 3, #cost
 1, 1, 0, 0, 0, #wr
 1, 1, 0, 0, 0, #wr flex
 0, 0, 1, 1, 0, #rb
 0, 0, 1, 1, 0, #rb flex
 0, 0, 0, 0, 1, #k
 0, 0, 0, 0, 1, #k flex
 1, 1, 1, 1, 0  #all positions
])

p.simplex
p.mip
z = p.obj.mip
x1 = cols[0].mip_val
x2 = cols[1].mip_val
x3 = cols[2].mip_val
x4 = cols[3].mip_val
x5 = cols[4].mip_val

printf("z = %g; x1 = %g; x2 = %g; x3 = %g; x4 = %g; x5 = %g\n", z, x1, x2, x3, x4, x5)
