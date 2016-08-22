#include <math.h>
#include <matrix.h>
#include <mex.h>
#include <string>

#include <iostream>
#include <cassert>
#include <unordered_set>


#include "graph.h"
#include "path.h"
#include "matrix.h"

using namespace std;

// for debugging mode, set to 1 (0 otherwise)
#define DEBUG 0


static Network network;
static vector<Graph*> graphs;
static vector<Path*> generated_paths;

void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
	// read the command parameter "cmd" (i.e. "read", "compute", "retrieve" or "clean")
	string cmd = mxArrayToString(prhs[0]);

	/*			READ			*/
	if (cmd == "read")
	{

#pragma region read_data
		// get the path to the input data
		string dataPath = mxArrayToString(prhs[1]);

		// Read data and create network
		if (DEBUG)
			mexEvalString("disp('-> Network data reading  ...') ");
		network = Network(dataPath);
#pragma endregion


#pragma region network_construction
		// Graph unrolling
		if (DEBUG)
			mexEvalString("disp('-> Graph unrolling  ...') ");

		// create graph
		uint R = network.getNbRequests();
		graphs = vector<Graph*>();
		// create set of generated paths
		generated_paths = vector<Path*>(R);
		for (size_t i = 0; i < R; i++)
		{
			graphs.push_back(new Graph(network, i));
			generated_paths[i] = new Path(network.getB(), network.getT(), network.getS());
		}
#pragma endregion


#pragma region build_output
		if (DEBUG)
			mexEvalString("disp('-> Outputting  ...') ");
		// number of requests R
		plhs[0] = mxCreateNumericMatrix(1, 1, mxINT32_CLASS, mxREAL);
		int *p_R = (int*)mxGetData(plhs[0]);
		p_R[0] = R;

		// block capacities
		int B = network.getB();
		plhs[1] = mxCreateNumericMatrix(B, 1, mxINT32_CLASS, mxREAL);
		int *cap = (int*)mxGetData(plhs[1]);
		int cp;
		for (int i = 0; i < B; i++)
		{
			cp = network.getCapacity(i);
			cap[i] = cp;
		}

		// number of time steps (T)
		plhs[2] = mxCreateNumericMatrix(1, 1, mxINT32_CLASS, mxREAL);
		int *T = (int*)mxGetPr(plhs[2]);
		T[0] = network.getT();
#pragma endregion

	}

	/*			COMPUTE			*/
	else if (cmd == "compute")
	{

#pragma region read_costs

		// get the track costs
		if (DEBUG)
			mexEvalString("disp('-> get the costs ...') ");
		uint R = graphs.size();
		uint B = mxGetM(prhs[1]);
		uint T = mxGetN(prhs[1]);
		matd mu(B, T);
		for (uint b = 0; b < B; b++)
			for (uint t = 0; t < T; t++)
				mu.at(b, t) = *(mxGetPr(prhs[1]) + t*B + b);
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
			graphs[r]->computeSP(mu, network);
			// add the path to the stored paths
			p_id[r] = graphs[r]->AddPath(*(generated_paths[r]), network);
			// assign the result values to the output parameters
			generated_paths[r]->assignOutput(Rev + r, Phi + r, capCons + r*B*T, p_id[r] - 1);
		}
#pragma endregion

	}
	/*			RETRIEVE		*/
	else if (cmd == "retrieve")
	{

#pragma region read_data
		uint P = (uint)*(mxGetPr(prhs[1]));
		if (DEBUG)
			mexEvalString("disp('OK')");

#pragma endregion


#pragma region build_output
		if (DEBUG)
			mexEvalString("disp('-> Outputting  ...') ");

		int R = generated_paths.size();
		uint S = generated_paths[0]->getS();

		uint B = generated_paths[0]->getB();
		uint T = generated_paths[0]->getT();

		// the generated timetables
		size_t dims[] = { S, 2, P, R };
		plhs[0] = mxCreateNumericArray(4, dims, mxINT32_CLASS, mxREAL);
		int* p_ptr = (int*)mxGetData(plhs[0]);
		for (uint r = 0; r < R; r++)
		{
			for (uint p = 1; p < P && p < generated_paths[r]->getNbPaths(); p++)// p=1, skip the null path
			{
				for (uint s = 0; s < S; s++)
				{
					p_ptr[r*S * 2 * P + p * S * 2 + s] = generated_paths[r]->getDeparture(p, s);
					p_ptr[r*S * 2 * P + p * S * 2 + S + s] = generated_paths[r]->getArrival(p, s);
				}
			}
		}

		// the revenue of each timetable
		plhs[1] = mxCreateNumericMatrix(P, R, mxDOUBLE_CLASS, mxREAL);
		double *rev_ptr = mxGetPr(plhs[1]);
		for (uint r = 0; r < R; r++)
		{
			for (uint p = 0; p < P && p < generated_paths[r]->getNbPaths(); p++)
			{
				rev_ptr[r*P + p] = generated_paths[r]->getRevenue(p);
			}

		}

		// the capacity consumption
		size_t occDims[] = { B, T, P, R };
		plhs[2] = mxCreateNumericArray(4, occDims, mxUINT32_CLASS, mxREAL);
		uint *occ = (uint*)mxGetData(plhs[2]);
		for (uint r = 0; r < R; r++)
		{
			for (uint p = 1; p < P && p < generated_paths[r]->getNbPaths(); p++)//skip null path
			{
				for (uint t = 0; t < T; t++)
				{
					for (uint b = 0; b < B; b++)
					{
						occ[r*B * T * P + p*B * T + t*B + b] = generated_paths[r]->getCapCons(p, b, t);
					}
				}
			}
		}



#pragma endregion

	}

	/*			CLEAN			*/
	else if (cmd == "clean")
	{

#pragma region freeing_memory	
		if (DEBUG)
			mexEvalString("disp('-> Freeing allocated memory...') ");

		// graphs
		for (size_t i = 0; i < graphs.size(); i++)
		{
			delete graphs.at(i);
		}
		graphs.clear();

		// paths
		for (size_t i = 0; i < generated_paths.size(); i++)
		{
			delete generated_paths.at(i);
		}
		generated_paths.clear();
#pragma endregion

	}

}
