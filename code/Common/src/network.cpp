#include "network.h"

#include<assert.h> //assert
#include <fstream> //reading from data file


////////////////////////////////////////////////////////////////////////////////
Network::Network() {}

////////////////////////////////////////////////////////////////////////////////
Network::Network(string filename) {

	ifstream fin(filename);

	if (!fin.is_open())
		assert(false && "data file could not be opened!");

	string from, to, header, dur_str;

	getline(fin, header);  //  read header

	/// reading the durations
	while (fin)
	{
		// FROM
		if (!getline(fin, from, ';') || from == "")
			break;

		// TO
		if (!getline(fin, to, ';'))
			assert(false && "Duration TO: Format of the data file is incorrect!");

		// STOP - STOP
		Duration duration;
		if (!getline(fin, dur_str, ';'))
			assert(false && "Duration STOP-STOP: Format of the data file is incorrect!");
		duration[StopStop] = stoi(dur_str);

		// STOP - FULL
		if (!getline(fin, dur_str, ';'))
			assert(false && "Duration STOP-FULL: Format of the data file is incorrect!");
		duration[StopFull] = stoi(dur_str);

		// FULL - STOP
		if (!getline(fin, dur_str, ';'))
			assert(false && "Duration FULL-STOP: Format of the data file is incorrect!");
		duration[FullStop] = stoi(dur_str);

		// FULL - FULL
		if (!getline(fin, dur_str))
			assert(false && "Duration FULL-FULL: Format of the data file is incorrect!");
		duration[FullFull] = stoi(dur_str);

		// add the arc to the network
		network[from][to] = duration;
	}

	/// read stations with capacity 2 or more
	string name, cap;
	map<string, uint> StatCap;
	getline(fin, header);  // skip the separating line
	getline(fin, header);  // read header
	while (fin)
	{
		// NAME
		if (!getline(fin, name, ';') || name == "")
			break;

		// capacity at the station
		if (!getline(fin, cap, ';'))
			assert(false && "Station CAPACITY: Format of the data file is incorrect!");
		StatCap[name] = stoi(cap);

		// skip the rest of the line
		if (!getline(fin, header))
			assert(false && "Format of the data file is incorrect!");
	}

	// requests
	string early_dep, late_dep,
		ideal_dep, revenue, late_arr, stops_str;
	getline(fin, header);  // skip the separating line
	getline(fin, header);  // read header
	while (fin)
	{
		// reading the data
		if (!getline(fin, from, ';') || from == "")
			break;

		if (!getline(fin, to, ';'))
			assert(false && "Request TO: Format of the data file is incorrect!");

		if (!getline(fin, early_dep, ';'))
			assert(false && "Request EARLY-DEP: Format of the data file is incorrect!");

		if (!getline(fin, late_dep, ';'))
			assert(false && "Request LATE-DEP: Format of the data file is incorrect!");

		if (!getline(fin, ideal_dep, ';'))
			assert(false && "Request IDEAL-DEP: Format of the data file is incorrect!");

		if (!getline(fin, revenue, ';'))
			assert(false && "Request REVENUE: Format of the data file is incorrect!");

		if (!getline(fin, late_arr, ';'))
			assert(false && "Request LATE-ARR: Format of the data file is incorrect!");

		if (!getline(fin, stops_str))
			assert(false && "Request STOPS: Format of the data file is incorrect!");

		// filling in the data structure
		Request request(from, to, early_dep, late_dep,
			ideal_dep, revenue, late_arr, stops_str);

		requests.push_back(request);
	}

	/// read the terminus
	getline(fin, header);  // skip the separating line
	getline(fin, header);  // read header
	if (!getline(fin, terminusL, ';'))
		assert(false && "Request TERMINUS-L: Format of the data file is incorrect!");
	if (!getline(fin, header)) // skip the rest of the line
		assert(false && "Request: Format of the data file is incorrect!");
	if (!getline(fin, terminusR, ';'))
		assert(false && "Request TERMINUS-R: Format of the data file is incorrect!");
	if (!getline(fin, header)) // skip the rest of the line
		assert(false && "Request: Format of the data file is incorrect!");

	// close the data file
	fin.close();

	// Creating a mapping between (station pairs) and (block identifier "b")
	// the mapping is from one terminus to the other
	string curr = terminusL;
	string prev = "";
	uint block_id = 0;
	while (true)
	{
		// if the current node is a station, add an additional block
		auto it_st = StatCap.find(curr);
		if (it_st != StatCap.end()){
			blocks[make_pair(curr, curr)] = block_id;
			block_id++;
			capacities.push_back(it_st->second);
		}
		// add the node to the path from one terminus (L) to the other (R)
		path_terminus.push_back(curr);
		// if we reached the other terminus (R), stop
		if (curr == terminusR)
			break;
		// get the next stop
		auto it = network.find(curr);
		string next = it->second.begin()->first;
		if (next == prev) // IMPORTANT: if the first terminus (terminusL) is in a station  
			// in the middle of the described network, then check the second outgoing arc
			next = it->second.crbegin()->first;
		// add to the block between the current and next station (with capacity 1)
		blocks[make_pair(curr,next)] = block_id;
		blocks[make_pair(next,curr)] = block_id;
		capacities.push_back(1);
		block_id++;
		// move to the next stop
		prev = curr;
		curr = next;
	}
	// set the number of blocks
	B = block_id;
	// set the number of time slots
	uint t = 0;
	for (size_t i = 0; i < requests.size(); i++)
	{
		if (t < requests[i].late_arr)
			t = requests[i].late_arr;
	}
	T = currStep(t);
	// set the number of stations
	S = path_terminus.size();
}

////////////////////////////////////////////////////////////////////////////////
uint Network::getNbRequests(){
	return requests.size();
}

////////////////////////////////////////////////////////////////////////////////
Request Network::getRequest(uint r) {
	return requests[r];
}


////////////////////////////////////////////////////////////////////////////////
vector<string> Network::getPath(string from, string to) {
	vector<string> path;
	// find the stations
	auto from_it = find(path_terminus.begin(), path_terminus.end(), from);
	auto to_it = find(path_terminus.begin(), path_terminus.end(), to);
	int f = from_it - path_terminus.begin();
	int t = to_it - path_terminus.begin();
	// fill the path
	if (from_it  <= to_it){
		for (int i = f; i <= t; i++)
		{
			path.push_back(path_terminus[i]);
		}
	}
	else{
		for (int i = f; i >= t; i--)
		{
			path.push_back(path_terminus[i]);
		}
	}
	return path;
}


////////////////////////////////////////////////////////////////////////////////
map<string, map<string, Duration>> Network::getNetwork(){
	return network;
}

////////////////////////////////////////////////////////////////////////////////
int Network::getStationBlockID(string from, string to){
	auto it = blocks.find(make_pair(from, to));
	if (it != blocks.end())
		return it->second;
	else
		return -1;
}


double Network::getRevenue(uint r, uint t){
	double res = 0.0;
	if (t >= requests[r].ideal_dep)
	{
		res = requests[r].revenue * (requests[r].late_dep - t) / double(requests[r].late_dep - requests[r].ideal_dep);
	}
	else {
		res = requests[r].revenue * (t - requests[r].early_dep) / double(requests[r].ideal_dep - requests[r].early_dep);
	}
	return res;
}


uint Network::getCapacity(uint b){
	return capacities[b];
}

uint Network::getT(){
	return T;
}


uint Network::getB(){
	return B;
}

uint Network::getS(){
	return S;
}

////////////////////////////////////////////////////////////////////////////////
Network::~Network() {
}

