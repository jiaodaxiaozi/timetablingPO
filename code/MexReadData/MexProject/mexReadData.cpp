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


using namespace std;

ObjectHandle<unordered_map<string, size_t>> *handle_ids;
ObjectHandle<vector<TrainRequest>> *handle_requests;
ObjectHandle<Graph<TimePos, float>> *handle_network;
ObjectHandle<vector<const Node<TimePos, float>*>> *handle_ordering;



void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{

	Node<TimePos, float>::printCosts = true;
	Node<TimePos, float>::printLabels = false;
	Node<TimePos, float>::printInEdges = false;
	Node<TimePos, float>::printOutEdges = true;

	// check the function input arguments
	if (nrhs != 1)
		mexErrMsgTxt("Number of arguments is incorrect!");
	if (!mxIsChar(prhs[0]))
		mexErrMsgTxt("Argument type is incorrect!");

	// check the function output arguments
	if (nlhs != 6)
		mexErrMsgTxt("Number of output arguments is incorrect!");

	// get the path to the input data
	string dataPath = mxArrayToString(prhs[0]);

	//  read duration table
	mexEvalString("disp('-> read duration data from file ...') ");
	bool succ = false;
	DurationTable durations;
	succ = readDurationTable(dataPath + "/type_train2.csv", durations);
	assert(succ);
	mexEvalString("disp('OK')");

	//  read Station Table
	mexEvalString("disp('-> read stations data from file ...')");
	StationTable stations;
	succ = readStationTypes(dataPath + "/stations.csv", stations);
	assert(succ);
	mexEvalString("disp('OK')");

	//  read track graph
	mexEvalString("disp('-> read tracks data from file ...') ");
	Graph<string, int> track;
	succ = readTrackGraph(dataPath + "/tracks.csv", track);
	assert(succ);
	mexEvalString("disp('OK')");

	//  read sample request
	mexEvalString("disp('-> read requests data from file ...') ");
	vector<TrainRequest>* requests = new vector<TrainRequest>();
	succ = readTrainRequests(dataPath + "/sample_input.csv", *requests);
	assert(succ);
	mexEvalString("disp('OK')");

	// Blocks-matrix mapping 
	mexEvalString("disp('-> blocks-matrix mapping  ...') ");
	unordered_map<string, pair<size_t, size_t>> *ids = new unordered_map<string, pair<size_t, size_t>>();
	linearBlockMatrixMapping(track, stations, *ids);
	mexEvalString("disp('OK')");

	// Graph unrolling
	mexEvalString("disp('-> Graph unrolling  ...') ");
	size_t nbRequests = requests->size();
	vector<Graph<TimePos, float>>* network = new vector<Graph<TimePos, float>>(nbRequests);
	vector<vector<const Node<TimePos, float>*>>* ordering = new vector<vector<const Node<TimePos, float>*>>(nbRequests);
	vector<unordered_map<int, int>>* path_ids = new vector<unordered_map<int, int>>(nbRequests);
	plhs[5] = mxCreateNumericMatrix(nbRequests, 1, mxINT32_CLASS, mxREAL);
	int *p = (int*)mxGetData(plhs[5]);
	for (int i = 0; i < nbRequests; ++i)
		p[i] = unroll((*requests)[i], track, stations, durations, (*network)[i], (*ordering)[i], (*path_ids)[i]);

	mexEvalString("disp('OK')");

	// Output the data and the unrolled graph to the caller in Matlab
	// ids - requests - network - ordering
	plhs[0] = create_handle(ids);
	plhs[1] = create_handle(requests);
	plhs[2] = create_handle(network);
	plhs[3] = create_handle(ordering);
	plhs[4] = create_handle(path_ids);
 
	mexPrintf("mexReadData executed successfully!\n");
	return;

}