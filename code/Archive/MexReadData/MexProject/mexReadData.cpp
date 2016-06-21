#include <math.h>
#include <matrix.h>
#include <mex.h>

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
#include "ObjectHandle.h"


/*
***** OUTPUTS
- nlhs: number of output arguments (here 9)
- plhs: output arguments
[0] ids			pointer to the ids mapping table
[1] cap         pointer to the blocks capacity
[1] requests    pointer to the train requests
[2] network		pointer to the graph network
[3] ordering	pointer to the ordering table
[4] path_ids	pointer to the ordering table
[5] P			number of possible paths for each request (generated paths)
[6] R			number of train requests
[7] T			number of time slots
[8] B			number of blocks
[9] Cap			capacity of each station	
[10] Rev		Revnue functions for each request

***** INPUTS
- nrhs: number of input arguments (here 1)
- prhs: input arguments
[0] The absolute path to the data folder

*/

// for debugging mode, set to 1 (0 otherwise)
#define DEBUG 0

using namespace std;

/*
ObjectHandle<pair< string,  string>> *handle_ids;
ObjectHandle<unordered_map<string, int>> *handle_cap;
ObjectHandle<vector<TrainRequest>> *handle_requests;
ObjectHandle<Graph<TimePos, float>> *handle_network;
ObjectHandle<vector<const Node<TimePos, float>*>> *handle_ordering;
*/


void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{

#pragma region arguments_check
	// check the function input arguments
	if (nrhs != 1)
		mexErrMsgTxt("Number of arguments is incorrect!");
	if (!mxIsChar(prhs[0]))
		mexErrMsgTxt("Argument type is incorrect!");

	// check the function output arguments
	if (nlhs != 12)
		mexErrMsgTxt("Number of output arguments is incorrect!");

#pragma endregion 


#pragma region read_data
	// get the path to the input data
	string dataPath = mxArrayToString(prhs[0]);

	//  read duration table
	if (DEBUG)
		mexEvalString("disp('-> read duration data from file ...') ");
	bool succ = false;
	DurationTable durations;
	succ = readDurationTable(dataPath + "/type_train2.csv", durations);
	assert(succ);
	if (DEBUG)
		mexEvalString("disp('OK')");
	cout << durations << endl;

	//  read track graph
	if (DEBUG)
		mexEvalString("disp('-> read stations data from file ...') ");
	unordered_map<string, int> stations;
	succ = readStations(dataPath + "/stations.csv", stations);
	assert(succ);
	if (DEBUG)
		mexEvalString("disp('OK')");

	//  read track graph
	if (DEBUG)
		mexEvalString("disp('-> read tracks data from file ...') ");
	Graph<string, int> track;
	map<set<string>, pair<int, int>> *ids_cap = new map<set<string>, pair<int, int>>();
	succ = readTrackGraph(dataPath + "/tracks.csv", track, stations, *ids_cap);
	assert(succ);
	if (DEBUG)
		mexEvalString("disp('OK')");

	//  read sample request
	if (DEBUG)
		mexEvalString("disp('-> read requests data from file ...') ");
	vector<TrainRequest>* requests = new vector<TrainRequest>();
	succ = readTrainRequests(dataPath + "/sample_input.csv", *requests);
	assert(succ);
	if (DEBUG)
		mexEvalString("disp('OK')");

#pragma endregion


#pragma region network_construction
	// Graph unrolling
	if (DEBUG)
		mexEvalString("disp('-> Graph unrolling  ...') ");
	size_t nbRequests = requests->size();
	vector<Graph<TimePos, float>>* network = new vector<Graph<TimePos, float>>(nbRequests);
	vector<vector<const Node<TimePos, float>*>>* ordering = new vector<vector<const Node<TimePos, float>*>>(nbRequests);
	plhs[6] = mxCreateNumericMatrix(nbRequests, 1, mxINT32_CLASS, mxREAL);
	int *p = (int*)mxGetData(plhs[6]);
	int P_min = INT_MAX;
	for (size_t i = 0; i < nbRequests; ++i){
		p[i] = unroll((*requests)[i], track, durations, (*network)[i], (*ordering)[i]);
		if (p[i] < P_min)
			P_min = p[i];
	}

	if (DEBUG)
		mexEvalString("disp('OK')");
#pragma endregion


#pragma region build_output
	// Output the data and the unrolled graph to the caller in Matlab
	// ids - requests - network - ordering
	plhs[0] = create_handle(ids_cap);
	plhs[2] = create_handle(requests);
	plhs[3] = create_handle(network);
	plhs[4] = create_handle(ordering);

	// Create the structure to save the generated paths
	vector<unordered_map<const Node<TimePos, float>*, const Node<TimePos, float>*>>* path_ids = 
		new vector<unordered_map<const Node<TimePos, float>*, const Node<TimePos, float>*>>(nbRequests*P_min);
	plhs[5] = create_handle(path_ids);

	// main stations (essentially for timetable outputting)
	int nbreStations = stations.size();
	plhs[1] = mxCreateNumericMatrix(nbreStations, 1, mxUINT32_CLASS, mxREAL);
	int32_T *st = (int32_T*)mxGetPr(plhs[1]);
	int i = 0;
	for (auto it : stations){
		set<string> key;
		key.insert(it.first);
		auto it_st = (*ids_cap).find(key);
		assert(it_st != (*ids_cap).end());
		st[i] = it_st->second.first;
		i++;
	}
		

	// additional information: number of requests (R), time steps (T), blocks (B)
	plhs[7] = mxCreateNumericMatrix(1, 1, mxINT32_CLASS, mxREAL);
	int32_T *R = (int32_T*)mxGetPr(plhs[7]);
	R[0] = nbRequests;

	plhs[8] = mxCreateNumericMatrix(1, 1, mxUINT32_CLASS, mxREAL);
	int32_T *T = (int32_T*)mxGetPr(plhs[8]);
	T[0] = 24 * 60 * 2;

	plhs[9] = mxCreateNumericMatrix(1, 1, mxUINT32_CLASS, mxREAL);
	int32_T *B = (int32_T*)mxGetPr(plhs[9]);
	B[0] = (*ids_cap).size(); 

	// Capacity of each space block
	plhs[10] = mxCreateNumericMatrix(B[0], 1, mxUINT32_CLASS, mxREAL);
	int32_T *Cap = (int32_T*)mxGetPr(plhs[10]);
	for (auto it : (*ids_cap))
		Cap[it.second.first-1] = it.second.second;

	// Revenue function
	plhs[11] = mxCreateNumericMatrix(nbRequests, 4, mxUINT32_CLASS, mxREAL);
	int32_T *Rev = (int32_T*)mxGetPr(plhs[11]);
	for (int i = 0; i < nbRequests; i++){ 
		Rev[i] = (*requests)[i].triangle_t1;// t1 = t_min
		Rev[i+nbRequests] = (*requests)[i].triangle_t2;// t2 = t_max
		Rev[i+2*nbRequests] = (*requests)[i].triangle_t3;// t3 = t_ideal
		Rev[i+3*nbRequests] = (*requests)[i].triangle_v;// v = ideal revenue value
	}
		

#pragma endregion



	ofstream myfile;
	myfile.open("network.txt");
	for (int i = 0; i < nbRequests; i++){
		myfile << (*network)[i];
		myfile << "\n \n \n";

	}
	myfile.close();


	if (DEBUG)
		mexPrintf("mexReadData executed successfully!\n");

}