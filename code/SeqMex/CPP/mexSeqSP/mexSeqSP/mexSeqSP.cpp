#include <math.h>
#include <matrix.h>
#include <mex.h>
#include <string>

#include <iostream>
#include <cassert>
#include <functional>
#include <unordered_set>


#include "graph.h"
#include "path.h"
#include "matrix.h"
#include "timer.h"
#include "ObjectHandle.h"




/*
***** OUTPUTS
- nlhs: number of output arguments (here 4)
- plhs: output arguments
[0] totalRev	total departure revenue (without the penalities)
[1] capCons		Capacity consumption
[2] SP_id		the path identifier
[3] Phi_SP		the total revenue with penalities

***** INPUTS
- nrhs: number of input arguments (here 5)
- prhs: input arguments
[0] network		pointer to the network object (describes the general network)
[1] graphs		pointer to the graph object (describes graphs per request)
[2]	genPaths	pointer to the generated paths
[3]	mu			the matrix of costs (multipliers)	

*/

using namespace std;

// for debugging mode, set to 1 (0 otherwise)
#define DEBUG 0



void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{

#pragma region arguments_check
	// check the number of arguments
	if (nrhs != 4)
		mexErrMsgTxt("Number of input arguments is incorrect!");

	if (nlhs != 4)
		mexErrMsgTxt("Number of output arguments is incorrect!");
#pragma endregion

#pragma region read_data
	// get the input data
	if (DEBUG)
		mexEvalString("disp('-> get the input data from handles ...') ");

	// get the c++ reference to the network
	//Network &network = get_object<Network>(prhs[0]);
	Network *network = (Network*)mxGetPr(prhs[0]);

	// get the c++ reference to the graphs
	//vector<Graph*> &graphs = get_object< vector<Graph*> >(prhs[1]);
	vector<Graph*> *graphs = (vector<Graph*> *)mxGetPr(prhs[1]);

	// get the c++ reference to the generated paths
	//vector<Path*> &generated_paths = get_object< vector<Path*> >(prhs[2]);
	vector<Path*> *generated_paths = (vector<Path*> *)mxGetPr(prhs[2]);


	if (DEBUG)
		mexEvalString("disp('OK')");

	// get the track costs
	if (DEBUG)
		mexEvalString("disp('-> get the costs ...') ");
	uint R = graphs->size();
	uint B = mxGetM(prhs[3]);
	uint T = mxGetN(prhs[3]);
	matd mu(B, T);
	for (uint b = 0; b < B; b++)
		for (uint t = 0; t < T; t++)
			mu.at(b, t) = *(mxGetPr(prhs[3]) + t*B + b);
	if (DEBUG)
		mexEvalString("disp('OK')");
#pragma endregion

#pragma region path_computation	
	if (DEBUG)
		mexEvalString("disp('-> Compute the shortest paths ...') ");

	// for the departure revenues (penalities excluded)
	plhs[0] = mxCreateDoubleMatrix(R, 1, mxREAL);
	double *Rev = mxGetPr(plhs[0]);
	// for the capacity consumption of each path
	size_t gDims[] = { B, T, R };
	plhs[1] = mxCreateNumericArray(3, gDims, mxINT32_CLASS, mxREAL);
	int *capCons = (int*)mxGetPr(plhs[1]);
	// for the optimal path identifier
	plhs[2] = mxCreateNumericMatrix(R, 1, mxINT32_CLASS, mxREAL);
	int *p_id = (int*)mxGetPr(plhs[2]);
	// for the dual objective
	plhs[3] = mxCreateNumericMatrix(R, 1, mxDOUBLE_CLASS, mxREAL);
	double *Phi = mxGetPr(plhs[3]);
	// compute the shortest path for each train request
	for (int r = 0; r < R; r++){
		// compute the shortest path
		(*graphs)[r]->computeSP(mu, *network, (*generated_paths)[r]);
		// add the path to the stored paths
		p_id[r] = (*graphs)[r]->AddPath(*((*generated_paths)[r]), *network);
		// assign the result values to the output parameters
		(*generated_paths)[r]->assignOutput(Rev + r, Phi + r, capCons + r*B*T, p_id[r] - 1);
	}
#pragma endregion


	// OK
	if (DEBUG)
		mexPrintf("Mex function for SP executed successfully!\n");

	return;
}