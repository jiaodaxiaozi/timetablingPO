#ifndef _GRAPH_H
#define _GRAPH_H

#include "types.h"
#include "network.h"
#include "node.h"
#include "matrix.h"
#include "path.h"

#include <deque>
#include <unordered_map>


class Graph
{


private:

	// nodes in the graph
	unordered_map<string, unordered_map<uint, unordered_map<State, Node*>>> nodes;

	// compulsory stops
	vector<string> stops;

	// basic path: sequence of stations
	vector<string> path;

	// topologic order of the graph that is used in the shortest path
	vector<Node*> ordering;

	// lastest departure time for each station
	map<string, uint> latestDep_v;

	// Number of possible departures
	uint nbDep;
	uint LatestDep;

	// Optimal path
	map<Node*, Node*> pred;
	// objective value 
	double phi;

	// Revenues from each departure
	map<Node*, double> revDep;

	// source and sink (virtual nodes)
	Node source, sink;

private:
	void unroll(deque<Node*> &node, Network& n);

public:
	// constructors
	Graph();
	Graph(Network &n, uint requestID);


	// add the newly generated path
	uint AddPath(Path &p, Network &n);

	// methods
	void computeSP(matd &costs, Network &n, Path *genPath);

	//  Printing method (as friend)
	friend ostream& operator << (ostream& out, const Network& n);

	// destructor
	~Graph();
};



#endif