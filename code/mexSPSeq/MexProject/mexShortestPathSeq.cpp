#include <math.h>
#include <matrix.h>
#include <mex.h>
#include <string>

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
- nlhs: number of output arguments (here 4)
- plhs: output arguments
	[0] objective values Phi_r
	[1] subgradients g_btr
	[2] shortest paths index p_r
	[3] shortest paths capacity consumption matrix

	***** INPUTS
- nrhs: number of input arguments (here 5)
- prhs: input arguments
	[0] ids
	[1] cap
	[2]	requests
	[3]	network
	[4]	ordering
	[5]	paths indices
	[6]	costs

*/

using namespace std;

// for debugging mode, set to 1 (0 otherwise)
#define DEBUG 1


void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{

#pragma region arguments_check
	// check the number of arguments
	if (nrhs != 6)
		mexErrMsgTxt("Number of input arguments is incorrect!");

	if (nlhs != 4)
		mexErrMsgTxt("Number of output arguments is incorrect!");
#pragma endregion

#pragma region read_data
	// get the input data
	if (DEBUG)
		mexEvalString("disp('-> get the input data from handles ...') ");

	map< set<string>, pair<int, int> > &ids = get_object< map<set<string>, pair<int, int>> >(prhs[0]);
	//unordered_map<string, int> &stations = get_object<unordered_map<string, int>>(prhs[1]);
	vector<TrainRequest> &requests = get_object<vector<TrainRequest>>(prhs[1]);
	vector<Graph<TimePos, float>> &network = get_object<vector<Graph<TimePos, float>>>(prhs[2]);
	vector<vector<const Node<TimePos, float>*>> &ordering = get_object<vector<vector<const Node<TimePos, float>*>>>(prhs[3]);
	vector<unordered_map<int, int>> &path_ids = get_object<vector<unordered_map<int, int>>>(prhs[4]);
	
	if (DEBUG)
		mexEvalString("disp('OK')");

	// get the track costs
	if (DEBUG)
		mexEvalString("disp('-> get the costs ...') ");
	int B = mxGetM(prhs[5]);
	int T = mxGetN(prhs[5]);
	matf mu(B, T);
	for (int b = 0; b < B; b++)
		for (int t = 0; t < T; t++)
			mu.at(b, t) = *(mxGetPr(prhs[5]) + b*T + t);
	if (DEBUG)
		mexEvalString("disp('OK')");

#pragma endregion

#pragma region cost_assignment
	//  assign the costs
	if (DEBUG)
		mexEvalString("disp('-> Assign edge costs ...') ");

	size_t nbRequests = requests.size();
	for (int i = 0; i < nbRequests; ++i)
		assignEdgeCosts(mu, ids, requests[i], network[i]);
	
	if (DEBUG)
		mexEvalString("disp('OK')");
#pragma endregion

#pragma region path_computation	
	//  shortest path
	if (DEBUG)
		mexEvalString("disp('-> Compute the shortest paths ...') ");
	vector<unordered_map<const Node<TimePos, float>*, const Node<TimePos, float>*>> path(nbRequests);
	plhs[0] = mxCreateDoubleMatrix(nbRequests, 1, mxREAL);
	double *Phi = (double*)mxGetPr(plhs[0]);
	for (int i = 0; i < nbRequests; ++i){
		Phi[i] = -dagsp(network[i], ordering[i], path[i]);
	}
	if (DEBUG)
		mexEvalString("disp('OK')");
#pragma endregion

#pragma region path_evaluation
	// evaluate the path (Phi & subgradient & capacity consumption matrix)
	if (DEBUG)
		mexEvalString("disp('-> Allocate the output variables ...') ");

	size_t pDims[] = {B, T, nbRequests};
	plhs[1] = mxCreateNumericArray(3, pDims, mxDOUBLE_CLASS, mxREAL);
	plhs[3] = mxCreateNumericArray(3, pDims, mxDOUBLE_CLASS, mxREAL);
	double *g = mxGetPr(plhs[1]);
	double *capMat = mxGetPr(plhs[3]);

	if (DEBUG)
		mexEvalString("disp('OK')");

	plhs[2] = mxCreateNumericMatrix(nbRequests, 1, mxDOUBLE_CLASS, mxREAL);
	double *sp_index = mxGetPr(plhs[2]);

	if (DEBUG)
		mexEvalString("disp('-> Evaluate the shortest path ...') ");
	for (int i = 0; i < nbRequests; ++i){
		evaluatePath(
			ordering[i].back(),
			path[i],
			ids,
			B,
			g+i*B*T,
			capMat+i*B*T
			);
	}	
	if (DEBUG)
		mexEvalString("disp('OK')");

	if (DEBUG)
		mexEvalString("disp('-> Get the shortest paths indices') ");
	for (int i = 0; i < nbRequests; ++i){
		auto sinkNode = ordering[i].back();
		auto id = path[i].at(sinkNode)->id();
		sp_index[i] = (path_ids[i]).at(id);
	}
	if (DEBUG)
		mexEvalString("disp('OK')");
#pragma endregion

	// OK
	if (DEBUG)
		mexPrintf("mexSPSeq executed successfully!\n");

	return;
}