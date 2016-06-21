#include "path.h"



Path::Path(){}

Path::Path(uint B_, uint T_, uint S_){
	// network size parameters
	B = B_;
	T = T_;
	S = S_;

	// decalre the path information
	departures = vector<vector<int>>();
	arrivals = vector<vector<int>>();
	phi = vector<double>();
	revenue = vector<double>();
	capCons = vector<mati>();

	// initialize with the null path
	latestid = 0;
	departures.push_back(vector<int>(S,-1));
	arrivals.push_back(vector<int>(S,-1));
	phi.push_back(0.0);
	revenue.push_back(0.0);
	capCons.push_back(mati());

	nbPaths = 1;

}


uint Path::getB(){
	return B;
}

uint Path::getS(){
	return S;
}

uint Path::getT(){
	return T;
}

uint Path::getCapCons(uint p, uint b, uint t){
	return capCons[p].at(b, t);
}

uint Path::getDeparture(uint id, uint s){
	return departures[id][s];
}

uint Path::getArrival(uint id, uint s){
	return arrivals[id][s];
}

uint Path::getNbPaths(){
	return nbPaths;
}

double Path::getRevenue(uint p){
	return revenue[p];
}

void Path::assignOutput(double *Rev, double *Phi, int *capCons_, int id)
{
	// assign the subgradient (if not null path)
	if (id != 0){
		for (int t = 0; t < T; t++)
		{
			{
				for (int b = 0; b < B; b++)
					capCons_[b + t*B] = capCons[id].at(b, t);
			}
		}
	}

	// assign the objective value
	*Phi = phi[id];

	// assign the revenues
	*Rev = revenue[id];
}


int Path::findPathID(vector<int> &dep, vector<int> &arr){
	for (size_t i = 0; i < nbPaths; i++)
	{
		if (dep == departures[i] && arr == arrivals[i]){
			return i;
		}
	}
	return -1;
}

int Path::getLatestID(){
	return latestid;
}

void Path::setPhi(double Phi_, uint id){
	phi[id] = Phi_;
}

void Path::setRevenues(double Revenues_, uint id){
	revenue[id] = Revenues_;
}

void Path::setCapCons(mati &capCons_, uint id){
	capCons[id] = capCons_;
}

void Path::setLatestID(uint ind){
	latestid = ind;
}


void Path::addNewPath(vector<int> &departures_, vector<int> &arrivals_, 
	double phi_, double revenue_, mati &capCons_){
	departures.push_back(vector<int>(departures_));
	arrivals.push_back(vector<int>(arrivals_));
	capCons.push_back(mati(capCons_));
	phi.push_back(phi_);
	revenue.push_back(revenue_);
	latestid = nbPaths;
	nbPaths++;
}