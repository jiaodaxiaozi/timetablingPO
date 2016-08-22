#include <iostream>
#include <cassert>
#include <functional>
#include <unordered_set>

#include "common.h"
#include "graph.h"
#include "csvreader.h"
#include "matrix.h"
#include "pathsearch.h"
#include "unroll.h"
#include "timer.h"
#include "dagsp.h"

using namespace std;

#define DEBUG 1

////////////////////////////////////////////////////////////////////////////////
int main(int argc, char* argv[]) 
{
	Timer timer;

    cout << "read data from files ... ";
    timer.tic();

    //  read duration table
    bool succ = false;
    DurationTable durations;
    succ = readDurationTable("../../../../data/type_train2.csv", durations);
    assert(succ);
	if (DEBUG)
		cout << " --- Duration" << endl << durations << endl << endl;

    //  read StationTable
    StationTable stations;
	unordered_map<string, size_t> ids;
    succ = readStationTypes("../../../../data/stations.csv", stations, ids);
    assert(succ);
	if (DEBUG)
		cout << " --- Stations" << endl << stations << endl << endl;

	//  read track graph
    Graph<string, int> track;
    succ = readTrackGraph("../../../../data/tracks.csv", track);
    assert(succ);
	if (DEBUG)
		cout << " --- Tracks" << endl << track << endl << endl;

	//  read sample request
    vector<TrainRequest> requests;
    succ = readTrainRequests("../../../../data/sample_input.csv", requests);
    assert(succ);


    // unroll
    cout << "unroll graph ...\n";
    timer.tic();

	int nbRequests = requests.size();
    vector<Graph<TimePos, float>> network(nbRequests);
    vector<vector<const Node<TimePos, float>*>> ordering(nbRequests);
	vector<unordered_map<int, int>> path_ids(nbRequests);
	for (int i = 0; i < nbRequests; ++i){
		cout << "Unroll for request = " << i+1 << endl;
		unroll(requests[i], track, durations, network[i], ordering[i], path_ids[i]);
	}   
	cout << " OK [" << timer.tac() << "s]" << endl;

    //  assign costs
    cout << "assign edge costs ...";
    timer.tic();
	//  generate cost matrix
	matf costs = matf::rnd(7, 24 * 60 * 2, 0, 0);
	for (int i = 0; i < nbRequests; ++i)
		assignEdgeCosts(costs, ids, requests[i], network[i]);
    
    cout << " OK [" << timer.tac() << "s]" << endl;

    //  shortest path
    cout << "compute shortest paths ...";
    timer.tic();

    vector<unordered_map<const Node<TimePos, float>*, const Node<TimePos, float>*>> paths(nbRequests);
	vector<float> Phi(nbRequests);
	for (int i = 0; i < nbRequests; ++i)
	{
		dagsp(network[i], ordering[i], paths[i]);
	}
    cout << "OK [" << timer.tac() << "s]" << endl;

	if (DEBUG){
		cout << "Output the shortest paths into a file ...";
		for (int i = 0; i < nbRequests; ++i){
			ofstream myfile;
			myfile.open("SP_req" + to_string(i) + ".txt");
			const Node<TimePos, float>* sink = ordering[i][ordering[i].size() - 1];
			const Node<TimePos, float>* start = ordering[i][0];
			const Node<TimePos, float>* currNode = paths[i].at(sink);
			while (currNode != start){
				int time = currNode->label().time_;
				myfile << time;
				myfile << ",";
				string position = currNode->label().position_;
				myfile << ids.at(position);
				myfile << endl;
				currNode = paths[i].at(currNode);
			}
			myfile.close();
		}
	}


    //  info
    cout << endl;
	for (size_t i = 0; i < nbRequests; i++)
	{
		cout << "network size: " << network[i].numNodes() << endl;
	}

	// ok
	cout << "Program successfully executed!" << endl;
	cout << "Press Enter to quit!" << endl;
	getchar();

    return EXIT_SUCCESS;
}