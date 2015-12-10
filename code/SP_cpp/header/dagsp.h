#ifndef DAGSP_H
#define DAGSP_H

#include <limits>
#include <algorithm>
#include <cassert>
#include <unordered_map>
#include <string>
//#include <mex.h>

#include <stdint.h>

#include "graph.h"
#include "node.h"


using namespace std;

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
	const map< set<string>, pair<int, int> > &ids,
	int B,
	double* subGrad,
	double* capMat
	)
{
	auto curr = predecessors.at(sink);

	// include the starting station
	// get the times
	int time_start = curr->label().time_ - 1;

	// get the positions
	string start = curr->label().position_;

	// find the block identifier
	set<string> arc_start;
	arc_start.insert(start);
	const auto& it_start = ids.find(arc_start);

	// check the existence
	assert(it_start != ids.end());

	// get the block info (id, cap)
	int b = it_start->second.first - 1;
	int cap = it_start->second.second;

	// Subgradient & capacity consumption
	// Initialize with the capacity
	subGrad[b + B*time_start] = cap;

	// One unit of capacity is consumed
	subGrad[b + B*time_start] -= 1;
	capMat[b + B*time_start] = 1; // here we can add the blocking rules


	// include the path
	while (predecessors.at(curr)->label().position_ != "START")
	{
		// get the times
		int time_from = curr->label().time_-1;
		int time_to = predecessors.at(curr)->label().time_ - 1;

		// get the positions
		string to = curr->label().position_;
		string from = predecessors.at(curr)->label().position_;
		
		// find the block identifier
		set<string> arc;
		arc.insert(from); arc.insert(to);
		const auto& it = ids.find(arc);

		// check the existence
		assert(it != ids.end());

		// get the block info (id, cap)
		b = it->second.first-1;
		cap = it->second.second;
		
		// Subgradient & capacity consumption
		for (int t = time_to; t <= time_from; t++){
			// Initialize with the capacity
			if (subGrad[b + B*t] == 0)
				subGrad[b + B*t] = cap;

			// One unit of capacity is consumed
			subGrad[b + B*t] -= 1;
			capMat[b + B*t] = 1; // here we can add the blocking rules
		}

		// move to the predecessor node
		curr = predecessors.at(curr);		
	}

	// include the starting station
	// get the times
	int time_end = curr->label().time_ - 1;

	// get the positions
	string end = curr->label().position_;

	// find the block identifier
	set<string> arc_end;
	arc_end.insert(end);
	const auto& it_end = ids.find(arc_end);

	// check the existence
	assert(it_end != ids.end());

	// get the block info (id, cap)
	b = it_end->second.first - 1;
	cap = it_end->second.second;

	// Subgradient & capacity consumption
	if (subGrad[b + B*time_end] == 0)
		subGrad[b + B*time_end] = cap;

	// One unit of capacity is consumed
	subGrad[b + B*time_end] -= 1;
	capMat[b + B*time_end] = 1; // here we can add the blocking rules

}
#endif