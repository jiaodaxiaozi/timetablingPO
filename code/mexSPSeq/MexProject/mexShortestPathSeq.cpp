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

/*
- nlhs: number of output arguments (here 3)
- plhs: output arguments
	[0] objective values Phi_r
	[1] subgradients g_btr
	[2] shortest paths index p_r
- nrhs: number of input arguments (here 5)
- prhs: input arguments
	[0] ids
	[1]	requests
	[2]	network
	[3]	ordering
	[4]	paths indices
	[5]	costs

*/


void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{

    Node<TimePos, float>::printCosts = true;
    Node<TimePos, float>::printLabels = false;
    Node<TimePos, float>::printInEdges = false;
    Node<TimePos, float>::printOutEdges = true;

	// check the number of arguments
	if (nrhs != 6)
		mexErrMsgTxt("Number of input arguments is incorrect!");

	if (nlhs != 3)
		mexErrMsgTxt("Number of output arguments is incorrect!");

	// get the input data
	mexEvalString("disp('-> get the input data from handles ...') ");

	unordered_map<string, pair<size_t, size_t>> &ids = get_object<unordered_map<string, pair<size_t, size_t>>>(prhs[0]);
	vector<TrainRequest> &requests = get_object<vector<TrainRequest>>(prhs[1]);
	vector<Graph<TimePos, float>> &network = get_object<vector<Graph<TimePos, float>>>(prhs[2]);
	vector<vector<const Node<TimePos, float>*>> &ordering = get_object<vector<vector<const Node<TimePos, float>*>>>(prhs[3]);
	vector<unordered_map<int, int>> &path_ids = get_object<vector<unordered_map<int, int>>>(prhs[4]);
	mexEvalString("disp('OK')");

	// get the track costs
	mexEvalString("disp('-> get the costs ...') ");
	int B = mxGetM(prhs[5]);
	int T = mxGetN(prhs[5]);
	matf mu(B,T);
	for (int r = 0; r < B; r++)
		for (int c = 0; c < T; c++)
			mu.at(r, c) = *(mxGetPr(prhs[5])+r*T+c);
	mexEvalString("disp('OK')");
	
	//  assign costs
	mexEvalString("disp('-> Assign edge costs ...') ");
	size_t nbRequests = requests.size();
	for (int i = 0; i < nbRequests; ++i)
		assignEdgeCosts(mu, ids, requests[i], network[i]);
	mexEvalString("disp('OK')");

	//  shortest path
	mexEvalString("disp('-> Compute the shortest paths ...') ");
	vector<unordered_map<const Node<TimePos, float>*, const Node<TimePos, float>*>> path(nbRequests);
	plhs[0] = mxCreateDoubleMatrix(nbRequests, 1, mxREAL);
	double *Phi = (double*)mxGetPr(plhs[0]);
	for (int i = 0; i < nbRequests; ++i){
		Phi[i] = -dagsp(network[i], ordering[i], path[i]);
	}
	mexEvalString("disp('OK')");

	// evaluate the path (Phi & subgradient)
	mexEvalString("disp('-> Allocate the subgradient matrix ...') ");
	size_t pDims[] = {B, T, nbRequests};
	plhs[1] = mxCreateNumericArray(3, pDims, mxINT8_CLASS, mxREAL);
	int8_T *g = (int8_T*)mxGetPr(plhs[1]);
	//g = (int8_T*)mxCalloc(B*T*nbRequests, 8);
	mexEvalString("disp('OK')");

	plhs[2] = mxCreateNumericMatrix(nbRequests, 1, mxINT8_CLASS, mxREAL);
	int8_T *sp_index = (int8_T*)mxGetPr(plhs[2]);
	//sp_index = (int8_T*)mxCalloc(nbRequests, 8);

	mexEvalString("disp('-> Evaluate the subgradient of the shortest path ...') ");
	for (int i = 0; i < nbRequests; ++i){
		evaluatePath(
			ordering[i].back(),
			path[i],
			ids, 
			T,
			g+i*B*T
			);
	}	
	mexEvalString("disp('OK')");

	mexEvalString("disp('-> Get the shortest paths indices ...') ");
	for (int i = 0; i < nbRequests; ++i){
		auto sinkNode = ordering[i][ordering[i].size()-1];
		auto id = path[i].at(sinkNode)->id();
		sp_index[i] = (path_ids[i]).at(id);
	}
	mexEvalString("disp('OK')");

	// OK
	mexPrintf("mexShortestPathSeq executed successfully!\n");
	return;

}




