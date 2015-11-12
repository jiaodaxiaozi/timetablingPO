#ifndef DAGSP_H
#define DAGSP_H

#include <limits>
#include <algorithm>
#include <cassert>
#include <unordered_map>
//#include <mex.h>

#include <stdint.h>

#include "graph.h"
#include "node.h"


static const double infd = std::numeric_limits<double>::infinity();

template <class N, typename C>
using ndmap = std::unordered_map<const Node<N, C>*, double>;

template <class N, typename C>
using nnmap = std::unordered_map<const Node<N, C>*, const Node<N, C>*>;


////////////////////////////////////////////////////////////////////////////////
template <class N, typename C>
void relax_node(
    const Node<N, C>* node, 
    ndmap<N, C>& costs, 
    nnmap<N, C>& predecessors) 
{    
    for (auto it : node->outEdges()) 
    {
        if (costs[node] + it.second < costs[it.first]) {    // it.first is dest node, 
                                                            // it.second is cost to dest node 
            costs[it.first] = costs[node] + it.second;
            predecessors[it.first] = node;
        }
    }
}


////////////////////////////////////////////////////////////////////////////////
template <class N, typename C>
C dagsp(
    const Graph<N, C>& g, 
    const std::vector<const Node<N, C>*>& sorting,
    nnmap<N, C>& predecessors)
{    
    assert (g.numNodes() == sorting.size());
    
    //  initialise costs
    ndmap<N, C> costs;
	
    for(auto it : sorting)
        costs[it] = infd;

    costs[sorting[0]] = 0.0;
    
    //  update distances in topological order
	for (auto it : sorting)
		relax_node(it, costs, predecessors);
	
	// The path cost
	return costs.at(sorting[sorting.size() - 1]);
}


////////////////////////////////////////////////////////////////////////////////
template <class N, typename C>
void evaluatePath(
	const Node<N, C>* sink,
	const unordered_map<const Node<TimePos, float>*, const Node<TimePos, float>*>& predecessors,
	const unordered_map<string, size_t> &ids,
	int B,
	double* subGrad,
	double* capMat
	)
{
	auto curr = predecessors.at(sink);

	while (curr->label().position_ != "START")
	{
		// get the times
		int time = curr->label().time_;
		string position = curr->label().position_;
		int b = ids.at(position)-1;

		// Subgradient & capacity consumption
		// Initialize with the capacity
		if (subGrad[b + B*time] == 0)
			subGrad[b + B*time] = 1; // capacity 1 for all blocks for now

		// One unit of capacity is consumed
		subGrad[b + B*time] -= 1;
		capMat[b + B*time] = 1;

		// move to the predecessor node
		curr = predecessors.at(curr);			
	}
}
#endif