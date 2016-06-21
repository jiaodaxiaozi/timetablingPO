#include <math.h>
#include <matrix.h>
#include <mex.h>

#include "graph.h"
#include "path.h"
#include "ObjectHandle.h"


/*
***** OUTPUTS
- nlhs: number of output arguments (here 9)
- plhs: output arguments
[0] network		pointer to the network
[1] graphs		pointer to the vector of graph requests
[2] R			number of train requests
[3] Cap         capacity of network blocks
[4] T			number of time slots
[5] genPaths	pointer to the generated paths

***** INPUTS
- nrhs: number of input arguments (here 1)
- prhs: input arguments
[0] The absolute path to the input data folder

*/

// for debugging mode, set to 1 (0 otherwise)
#define DEBUG 1


void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{

#pragma region arguments_check
	// check the function input arguments
	if (nrhs != 1)
		mexErrMsgTxt("Number of arguments is incorrect!");

	// check the function output arguments
	if (nlhs != 6)
		mexErrMsgTxt("Number of output arguments is incorrect!");

#pragma endregion 


#pragma region read_data
	// get the path to the input data
	string dataPath = mxArrayToString(prhs[0]);

	// Read data and create network
	if (DEBUG)
		mexEvalString("disp('-> Network data reading  ...') ");
	Network *network = new Network(dataPath);

	if (DEBUG)
		mexEvalString("disp('OK')");

#pragma endregion


#pragma region network_construction
	// Graph unrolling
	if (DEBUG)
		mexEvalString("disp('-> Graph unrolling  ...') ");

	// create network
	uint R = network->getNbRequests();
	vector<Graph*>* graphs = new vector<Graph*>();
	// create set of generated paths
	vector<Path*> *generated_paths = new vector<Path*>(R);
	for (size_t i = 0; i < R; i++)
	{
		(*graphs).push_back(new Graph(*network, i));
		(*generated_paths)[i] = new Path(network->getB(), network->getT(), network->getS());
	}

	if (DEBUG)
		mexEvalString("disp('OK')");
#pragma endregion


#pragma region build_output
	if (DEBUG)
		mexEvalString("disp('-> Outputting  ...') ");

	// c++ pointer to the network
	plhs[0] = create_handle(network);

	// c++ pointer to the graphs
	plhs[1] = create_handle(graphs);

	// c++ pointer to the paths
	plhs[5] = create_handle(generated_paths);

	// number of requests R
	plhs[2] = mxCreateNumericMatrix(1, 1, mxINT32_CLASS, mxREAL);
	int *p_R = (int*)mxGetData(plhs[2]);
	p_R[0] = R;

	// block capacities
	int B = network->getB();
	plhs[3] = mxCreateNumericMatrix(B, 1, mxINT32_CLASS, mxREAL);
	int *cap = (int*)mxGetData(plhs[3]);
	int cp;
	for (int i = 0; i < B; i++)
	{
		cp = network->getCapacity(i);
		cap[i] = cp;
	}
		
	// number of time steps (T)
	plhs[4] = mxCreateNumericMatrix(1, 1, mxINT32_CLASS, mxREAL);
	int *T = (int*)mxGetPr(plhs[4]);
	T[0] = network->getT();

	if (DEBUG)
		mexEvalString("disp('OK')");
#pragma endregion


}