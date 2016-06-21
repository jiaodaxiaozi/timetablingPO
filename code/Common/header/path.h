#ifndef _PATH_H
#define _PATH_H



#include "node.h"
#include "network.h"
#include "matrix.h"

#include <iostream>


class Path
{
	
private:
	uint B, T, S;

	vector<vector<int>> departures;
	vector<vector<int>> arrivals;

	vector<double> phi;
	vector<double> revenue;
	vector<mati> capCons;

	int latestid;
	uint nbPaths;

public:
	
	int getLatestID();

	Path();
	Path(uint B_, uint T_, uint S_);



	// method
	void assignOutput(double *Rev, double* Phi, int *subg, int id);
	uint getNbPaths();
	uint getT();
	uint getB();
	uint getS();
	uint getCapCons(uint p, uint b, uint t);
	uint getDeparture(uint id, uint s);
	uint getArrival(uint id, uint s);
	double getRevenue(uint p);
	int findPathID(vector<int> &dep, vector<int> &arr);
	void setPhi(double Phi_, uint id);
	void setRevenues(double Revenues_, uint id);
	void setCapCons(mati &capCons_, uint id);
	void setLatestID(uint ind);
	void addNewPath(vector<int> &departures_, vector<int> &arrivals_, double phi_, double revenue_, mati &capCons_);

	//  Printing method (as friend)
	friend ostream& operator << (ostream& out, const Path& p);
};

#endif