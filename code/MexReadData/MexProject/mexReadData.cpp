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
[1] requests    pointer to the train requests
[2] network		pointer to the graph network
[3] ordering	pointer to the ordering table
[4] path_ids	pointer to the ordering table
[5] P			number of possible paths for each request (generated paths)
[6] R			number of train requests
[7] T			number of time slots
[8] B			number of blocks
[9] Cap			capacity of each station	

***** INPUTS
- nrhs: number of input arguments (here 1)
- prhs: input arguments
[0] The absolute path to the data folder

*/

// for debugging mode, set to 1 (0 otherwise)
#define DEBUG 1

using namespace std;

ObjectHandle<unordered_map<string, size_t>> *handle_ids;
ObjectHandle<vector<TrainRequest>> *handle_requests;
ObjectHandle<Graph<TimePos, float>> *handle_network;
ObjectHandle<vector<const Node<TimePos, float>*>> *handle_ordering;


void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{

#pragma region arguments_check
	// check the function input arguments
	if (nrhs != 1)
		mexErrMsgTxt("Number of arguments is incorrect!");
	if (!mxIsChar(prhs[0]))
		mexErrMsgTxt("Argument type is incorrect!");

	// check the function output arguments
	if (nlhs != 10)
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

	//  read Station Table
	if (DEBUG)
		mexEvalString("disp('-> read stations data from file ...')");
	unordered_map<string, size_t> *ids = new unordered_map<string, size_t>();
	unordered_map<string, int> stations;
	succ = readStationTypes(dataPath + "/stations.csv", stations, *ids);
	assert(succ);
	if (DEBUG)
		mexEvalString("disp('OK')");

	//  read track graph
	if (DEBUG)
		mexEvalString("disp('-> read tracks data from file ...') ");
	Graph<string, int> track;
	succ = readTrackGraph(dataPath + "/tracks.csv", track);
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
	vector<unordered_map<int, int>>* path_ids = new vector<unordered_map<int, int>>(nbRequests);
	plhs[5] = mxCreateNumericMatrix(nbRequests, 1, mxINT32_CLASS, mxREAL);
	int *p = (int*)mxGetData(plhs[5]);
	for (int i = 0; i < nbRequests; ++i)
		p[i] = unroll((*requests)[i], track, durations, (*network)[i], (*ordering)[i], (*path_ids)[i]);
	if (DEBUG)
		mexEvalString("disp('OK')");
#pragma endregion



#pragma region build_output
	// Output the data and the unrolled graph to the caller in Matlab
	// ids - requests - network - ordering
	plhs[0] = create_handle(ids);
	plhs[1] = create_handle(requests);
	plhs[2] = create_handle(network);
	plhs[3] = create_handle(ordering);
	plhs[4] = create_handle(path_ids);

	// additional information: number of requests (R), time steps (T), blocks (B)
	plhs[6] = mxCreateNumericMatrix(1, 1, mxUINT8_CLASS, mxREAL);
	int8_T *R = (int8_T*)mxGetPr(plhs[6]);
	R[0] = nbRequests;
 
	plhs[7] = mxCreateNumericMatrix(1, 1, mxUINT16_CLASS, mxREAL);
	INT16_T *T = (INT16_T*)mxGetPr(plhs[7]);
	T[0] = 24 * 60 * 2;

	plhs[8] = mxCreateNumericMatrix(1, 1, mxUINT8_CLASS, mxREAL);
	int8_T *B = (int8_T*)mxGetPr(plhs[8]);
	B[0] = (*ids).size(); 

	// Capacity of each space block
	plhs[9] = mxCreateNumericMatrix(B[0], 1, mxUINT8_CLASS, mxREAL);
	int8_T *Cap = (int8_T*)mxGetPr(plhs[9]);
	for (const auto& st : stations)
		Cap[(*ids).at(st.first)-1] = st.second;

#pragma endregion

	if (DEBUG)
		mexPrintf("mexReadData executed successfully!\n");

}