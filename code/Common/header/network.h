#ifndef _Network_H
#define _Network_H

#include "types.h"


#include <iostream> // ostream
#include <map> // map


class Network
{


private:
	// requests
	vector<Request> requests;

	// blocks capacity
	vector<uint> capacities;

	// station capacities
	map<string, uint> StatCap;

	// mapping identifier and blocks and stops
	map<pair<string, string>, uint> blocks;

	// network (links with durations)
	map<string, map<string, Duration>> network;

	// terminus
	string terminusL;
	string terminusR;

	// sizes
	uint B, T, S;


public:

	vector<string> path_terminus;// path from terminusL to terminusR

	// constructors
	Network();
	Network(string filename);

	// methods
	uint getNbRequests();
	uint getCapacity(uint b);
	Request getRequest(uint r);
	vector<string> getPath(string from, string to);
	int getStationBlockID(string from, string to);
	bool isStation(string pos);
	map<string, map<string, Duration>> getNetwork();
	double getRevenue(uint r, uint t);
	uint getB();
	uint getT();
	uint getS();

	// desctructor
	~Network();
};


#endif
