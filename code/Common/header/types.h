#ifndef _TYPES_H
#define _TYPES_H

#include<sstream> //istringstream
#include<vector> //vector
#include<map> //map

using namespace std;

// time step
#define T_STEP 30

// commercial waiting time
#define T_STOP 120

// approximation of the blocking time
#define BLOCK_RULE 180

// maximum number of generated paths
//#define MAX_GEN_P 100


// Scenario of train in blocks
enum Scenario {
	StopStop,
	StopFull,
	FullStop,
	FullFull,
};

// state of train in a point
enum State {
	Stop,//train stopped (compulsory)
	Wait,//train waiting (voluntary)
	Move,//train moving
};

typedef unsigned int uint;

const double infd = std::numeric_limits<double>::infinity();

//type definition for the durations tableW
typedef map<Scenario, uint> Duration;

// Request
struct Request
{
	string from; // starting station
	string to; // terminal station

	uint early_dep; // earliest departure time
	uint late_dep; // latest departure time
	uint ideal_dep; // ideal departure time
	double revenue; // revenue
	uint late_arr; // latest arrival time
	vector<string> stops; // intermediate stops

	Request(){};

	Request(string from_, string to_, string early_dep_, string late_dep_, string ideal_dep_,
		string revenue_, string late_arr_, string stops_){
		from = from_;
		to = to_;
		early_dep = stoi(early_dep_);
		late_dep = stoi(late_dep_);
		ideal_dep = stoi(ideal_dep_);
		revenue = stoi(revenue_);
		late_arr = stoi(late_arr_);
		// stops
		istringstream sstops(stops_);
		string stop;
		while (sstops >> stop)
		{
			stops.push_back(stop);
		}
	}
};

////////////////////////////////////////////////////////////////////////////////
inline uint nextStep(const uint t, const uint step = T_STEP) {
	return uint(ceilf((float)t / step) * step);
}

////////////////////////////////////////////////////////////////////////////////
inline uint currStep(const uint t, const uint step = T_STEP) {
	return uint(floor(t / (float)step));
}



#endif