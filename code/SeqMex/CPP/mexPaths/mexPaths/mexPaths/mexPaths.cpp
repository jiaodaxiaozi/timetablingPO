#include <mex.h>


#include "path.h"
#include "ObjectHandle.h"


// for debugging mode, set to 1 (0 otherwise)
#define DEBUG 0

using namespace std;



void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{

#pragma region arguments_check
	// check the function input arguments
	if (nrhs != 2)
		mexErrMsgTxt("Number of arguments is incorrect!");

	// check the function output arguments
	if (nlhs != 3)
		mexErrMsgTxt("Number of output arguments is incorrect!");

#pragma endregion 


#pragma region read_data

	// Read data and create network
	if (DEBUG)
		mexEvalString("disp('-> Generated paths reading  ...') ");

	// get the c++ reference to the generated paths
	vector<Path*> &generated_paths = get_object< vector<Path*> >(prhs[0]);
	uint P = *(mxGetPr(prhs[1]));
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
	size_t dims[] = { S, 2, P, R};
	plhs[0] = mxCreateNumericArray(4, dims, mxINT32_CLASS, mxREAL);
	int* p_ptr = (int*)mxGetData(plhs[0]);
	for (uint r = 0; r < R; r++)
	{
		for (uint p = 1; p < P && p < generated_paths[r]->getNbPaths(); p++)// p=1, skip the null path
		{
			for (uint s = 0; s < S; s++)
			{
				p_ptr[r*S * 2 * P + p * S * 2+ s] = generated_paths[r]->getDeparture(p, s);
				p_ptr[r*S * 2 * P + p * S * 2+ S+ s] = generated_paths[r]->getArrival(p, s);
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
	size_t occDims[] = {B, T, P, R};
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

		mexEvalString("disp('OK')");

#pragma endregion


	if (DEBUG)
		mexPrintf("mexReadData executed successfully!\n");

}