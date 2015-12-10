#ifndef COMMON_H
#define COMMON_H

#include <iostream>
#include <utility>
#include <string>
#include <vector>


////////////////////////////////////////////////////////////////////////////////
template <class T>
std::ostream& operator<<(std::ostream& out, std::vector<T>& v) 
{
    out << "[";

    for (int i = 0; i < v.size() - 1; i++)
        out << v[i] << ", ";

    out << *(v.end()--) << "]";

    return out;
}

/*
pair<const string, const string> my_make_pair(const string from, const string to){

if (from.compare(to) < 0)
return pair<const string, const string>(from, to);
else
return pair<const string, const string>(to, from);
}
*/


#endif