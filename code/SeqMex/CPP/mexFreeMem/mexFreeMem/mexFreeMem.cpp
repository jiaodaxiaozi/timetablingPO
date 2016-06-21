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




using namespace std;

// for debugging mode, set to 1 (0 otherwise)
#define DEBUG 0



void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{

#pragma region arguments_check
	// check the number of arguments
	if (nrhs != 3)
		mexErrMsgTxt("Number of input arguments is incorrect!");

	if (nlhs != 0)
		mexErrMsgTxt("Number of output arguments is incorrect!");
#pragma endregion

#pragma region path_computation	
	//  shortest path
	if (DEBUG)
		mexEvalString("disp('-> Free allocated memory') ");

	// get the c++ reference to the network
	//destroy_object<Network>(prhs[0]);

	// get the c++ reference to the graphs
	vector<Graph*>&  graphs = get_object< vector<Graph*> >(prhs[1]);
	for (size_t i = 0; i < graphs.size(); i++)
	{
		delete graphs.at(i);
	}
	graphs.clear();
	//destroy_object<vector<Graph*>>(prhs[1]);

	// get the c++ reference to the generated paths
	vector<Path*> &generated_paths = get_object< vector<Path*> >(prhs[2]);
	for (size_t i = 0; i < generated_paths.size(); i++)
	{
		delete generated_paths.at(i);
	}
	generated_paths.clear();
	//destroy_object<vector<Path*>>(prhs[2]);

	if (DEBUG)
		mexEvalString("disp('OK')");
#pragma endregion

	return;
}