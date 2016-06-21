#include "network.h"
#include "timer.h"
#include "graph.h"
#include "path.h"

#include <iostream>
#include <stdlib.h> 


using namespace std;

#define DEBUG 1

////////////////////////////////////////////////////////////////////////////////
int main(int argc, char* argv[]) 
{
	// Read data and create network
	Network network("../../../Common/data/test.csv");

	// create network
	uint R = network.getNbRequests();
	vector<Graph*> graphs;
	for (size_t i = 0; i < R; i++)
	{
		graphs.push_back(new Graph(network, i));
	}

	// Compute the SP
	uint B = network.getB();
	uint T = network.getT();
	vector<Path> paths(R, Path(B,T,network.getS()));
	int * g = (int*)calloc(R*B*T, sizeof(int));
	double * phi = (double*)calloc(R, sizeof(double));
	matd mu = matd::rnd(B, T, 0.0, 0.0);
	for (int j = 1; j < 100; j++)
	{
		cout << j << endl;
		for (int i = 0; i < R; i++)
		{
			(*graphs[i]).computeSP(mu, network, &paths[i]);
			auto id = graphs[i]->AddPath(paths[i], network);
			cout << *(phi + i) << j << endl;

		}
	}

	cin.get();
	return 0;
}