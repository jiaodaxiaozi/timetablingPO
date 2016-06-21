#ifndef PATH_H
#define PATH_H



#include "node.h"
#include <iostream>
#include <unordered_map>


template <class N, typename C>
class Path{
	
private:
	unordered_map<const Node<N, C>*, const Node<N, C>*> nodes_list;
	Node<N, C>* sink;

public:
	Path(unordered_map<const Node<N, C>*, const Node<N, C>*> p, const Node<N, C>* sink);
	int size() const;

	bool operator == (const Path& p) const;

};

#endif