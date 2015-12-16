#ifndef GRAPH_H
#define GRAPH_H

#include <iostream>
#include <unordered_map>
#include <vector>
#include <cassert>

#include "node.h"

using namespace std;


template <class N, typename C>
class Graph 
{
	// Members
	private:
		// Nodes of the graph
		unordered_map<N, Node<N, C>> nodes_;

	// Methods
    public:

		// Constructor
        Graph() {};

        //  Get the number of nodes in the graph.
        int numNodes() const { return nodes_.size(); }

		// Get the node corresponding to a label
        Node<N, C>* node(const N& label)
        {
            auto it = nodes_.find(label);

            if (it == nodes_.end()) 
                return nullptr;

            return &(it->second);
        }

		// Get the node corresponding to a label (const version)
        const Node<N, C>* node(const N& label) const 
        {
            auto it = nodes_.find(label);

            if (it == nodes_.end()) 
                return nullptr;

            return &(it->second);
        }

		// Get the edge (from <-> to)
        const C edge(const N& from, const N& to) const 
        {
            assert(hasNode(from) && hasNode(to));

            auto n1 = node(from);
            auto n2 = node(to);

            return n1->edgeTo(n2);
        }

		// Check if the graph has node label
        bool hasNode(const N& label) const {
            return nodes_.find(label) != nodes_.end();
        }

		// Get all the graph nodes
        unordered_map<N, Node<N, C>>& nodes() { return nodes_; }

		// Get all the graph nodes (const version)
        const unordered_map<N, Node<N, C>>& nodes() const { return nodes_; }


        // Add the node with label to the graph nodes
        const Node<N, C>* addNode(const N& label) {
            auto item = pair<N, Node<N, C>>(label, Node<N, C>(label));
            auto succ = nodes_.insert(item);
            return &succ.first->second;
        }

		// Add the directed edge (nodefrom -> nodeto) to the graph
        bool addEdge(
            const N& nodefrom, 
            const N& nodeto, 
            const C& val = 0
			) 
        {
			assert(hasNode(nodefrom) && hasNode(nodeto));

			auto from = node(nodefrom);
			auto to = node(nodeto);

			from->addEdgeTo(to, val);
			to->addEdgeFrom(from, val);

            return true;
        }


        //  Printing method (as friend)
        friend ostream& operator << (ostream& out, const Graph& g) 
        {
            for (auto node: g.nodes_) 
                out << node.second << endl;

            return out;
        }

};

#endif