#include "path.h"

using namespace std;

template <class N, typename C>
int Path<N,C>::size() const{
	return nodes_list.size();
}


template <class N, typename C>
bool Path<N, C>::operator == (const Path<N, C>& o) const {

	// two paths with different sizes are different
	if (o.size() != nodes_list.size())
		return false;

	// same size, check the nodes one by one

}


template <class N, typename C>
Path<N, C>::Path(unordered_map<const Node<N, C>*, const Node<N, C>*> p, const Node<N, C>* s){
	nodes_list = unordered_map<const Node<N, C>*, const Node<N, C>*> new(p);
	sink = s;
}