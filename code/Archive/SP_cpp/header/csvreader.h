#ifndef CSV_READER_H
#define CSV_READER_H

#include <map>
#include <vector>
#include <iostream>
#include <set>

#include "trainrequest.h"
#include "graph.h"

using namespace std;

// Types of blocks
enum BlockType {
    StopStop,
    StopFull,
    FullStop,
    FullFull
};

// ???
enum LocationType {
    None,
    DP,
    MBLSI,
};

// Type definition for train durations data
typedef map<BlockType, int> bi; // motion type and travel time (duration)
typedef map<string, bi> sbi; // destination station and above
typedef map<string, sbi> ssbi; // starting station and above
typedef ssbi DurationTable; // all train motion duration info


// Type definition for stations data
typedef unordered_map<string, int> sl; // station and capacity
typedef sl StationTable; // all station info


// Reads the data table with duration of (SS, SF, FS, FF)
bool readDurationTable(
    const string& filename,
    DurationTable& table
);

// Reads the stations data (name, capacity, location type)
bool readStations(
    const string& filename,
    unordered_map<string,int>& stations
);

// Reads the requests data (trainId, type, from, to, triangle, window)
bool readTrainRequests(
    const string& filename,
    vector<TrainRequest> &result
);

// Reads the tracks data (track id, start, end, line, distance)
bool readTrackGraph(
    const string& filename,
    Graph<string, int>& graph,
	unordered_map<string, int>& stations,
	map<set<string>, pair<int, int>> &ids_cap
);


//  outputs
ostream& operator << (ostream& out, const DurationTable& table);
//ostream& operator << (ostream& out, const StationTable& table);


#endif