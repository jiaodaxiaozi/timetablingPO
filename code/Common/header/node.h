#ifndef _NODE_H
#define _NODE_H


#include "types.h"

#include <map>

/*
#include <cassert>
#include <iostream>

*/

using namespace std;


// Class that describes a node in the graph
class Node
{


	// static variable (used to count number of instantiations)
	

public:

	string pos; // train stop label
	uint time; // node time
	State state; // state of the train at the block

	vector< Node*> inNodes_; // incoming edges with their costs (or capacity for network nodes)
	vector< Node*> outNodes_; // outgoing edges with their costs (or capacity for network nodes)

public:
	// constructor
	Node();
	Node(string b, uint t, State s);

	// operator
	Node& operator=(Node &n);
	
	// methods
	void addInNode(Node *node);
	void addOutNode(Node *node);
	vector<Node*> getOutNode();
	string getPosition();
	State getState();
	uint getTime();

	// compare nodes equality
	virtual bool operator == (const Node& o) const {
		return (pos == o.pos) && (time == o.time) && (state == o.state);
	}

};

#endif
