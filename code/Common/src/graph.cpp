#include "graph.h"

#include <algorithm> 

////////////////////////////////////////////////////////////////////////////////
Graph::Graph() {}

////////////////////////////////////////////////////////////////////////////////
Graph::Graph(Network &n, uint r) {
	// create the source and sink nodes
	sink = Node("SINK", 0, State::Stop);
	source = Node("SOURCE", 0, State::Stop);

	// add to the list of nodes
	//nodes[sink.getPosition()][sink.getTime()][sink.getState()] = &sink;
	//nodes[source.getPosition()][sink.getTime()][sink.getState()] = &source;

	// compulsory stops
	stops = n.getRequest(r).stops;

	// get the path
	path = n.getPath(n.getRequest(r).from, n.getRequest(r).to);

	// get the latest departure
	LatestDep = n.getRequest(r).late_arr;
	latestDep_v[path[path.size() - 1]] = LatestDep;
	bool stopping = true;
	for (int i = path.size() - 2; i >= 0; i--)
	{
		if (LatestDep < n.getRequest(r).early_dep){
			latestDep_v[path[0]] = 0;
			break; // WARNING: no path is feasible
		}
		else{
			if (stopping){
				if (find(stops.begin(), stops.end(), path[i]) != stops.end()){
					stopping = true;
					LatestDep -= n.getNetwork()[path[i]][path[i + 1]][StopStop] + T_STOP;
				}
				else {
					stopping = false;
					LatestDep -= n.getNetwork()[path[i]][path[i + 1]][StopFull];
				}
			}
			else {
				if (find(stops.begin(), stops.end(), path[i]) != stops.end()){
					stopping = true;
					LatestDep -= n.getNetwork()[path[i]][path[i + 1]][FullStop] + T_STOP;
				}
				else {
					stopping = false;
					LatestDep -= n.getNetwork()[path[i]][path[i + 1]][FullFull];
				}
			}
		}
		latestDep_v[path[i]] = LatestDep;
	}

	// number of possible departures
	nbDep = 0;
	// create the first nodes
	uint ideal_t = n.getRequest(r).ideal_dep;
	deque<Node*> active;
	for (int t = ideal_t - T_STEP; t > n.getRequest(r).early_dep; t -= T_STEP)
	{
		// if t is after the latest departure, then skip it
		if (t > latestDep_v[path[0]])
			continue;
		// add the node to the graph
		Node* start = new Node(path[0], t, State::Ready);
		start->addInNode(&source);
		source.addOutNode(start);
		nodes[start->getPosition()][start->getTime()][start->getState()] = start;
		active.push_front(start);
		ordering.insert(ordering.begin(), start);
		// add the departure revenue
		revDep[start] = n.getRevenue(r, t);
		// next departure
		nbDep++;
	}
	for (int t = ideal_t; t < n.getRequest(r).late_dep; t += T_STEP)
	{
		// add the node to the graph
		Node* start = new Node(path[0], t, State::Ready);
		start->addInNode(&source);
		source.addOutNode(start);
		nodes[start->getPosition()][start->getTime()][start->getState()] = start;
		active.push_back(start);
		ordering.push_back(start);
		// add the departure revenue
		revDep[start] = n.getRevenue(r, t);
		// next departure
		nbDep++;
	}
	ordering.insert(ordering.begin(), &source);
	// unroll the rest of the nodes (recursively)
	while (!active.empty())
	{
		this->unroll(active, n);
	}
	ordering.push_back(&sink);
}


////////////////////////////////////////////////////////////////////////////////
void Graph::unroll(deque<Node*> &active, Network &network){

	// get the first active node
	Node* node = active.front();
	ordering.push_back(node);
	active.pop_front();

	// if the final station is reached
	string curr_pos = node->getPosition();
	uint curr_time = node->getTime();
	if (curr_pos == path[path.size() - 1]){
		// link to the virtual sink
		if (curr_time <= latestDep_v[path[path.size() - 1]]){
			node->addOutNode(&sink);
			sink.addInNode(node);
		}
		// continue unrolling
		return;
	}

	string next_pos = *(find(path.begin(), path.end(), curr_pos) + 1);
	bool stopRequested = (find(stops.begin(), stops.end(), next_pos) != stops.end()) || (next_pos == path[path.size() - 1]);

	// the train is stopping for commercial waiting time
	// Scenario 1) wait the commercial waiting time
	State state = node->getState();
	if (state == State::Stop){
		// check if the time is not beyond the latest arrival
		if (latestDep_v[curr_pos] > curr_time + T_STOP){
			for (State var : {State::Wait, State::Ready})
			{
				Node *newNode;
				// check if the node was not already created 
				if (nodes[curr_pos].empty() ||
					nodes[curr_pos][curr_time + T_STOP].empty() ||
					nodes[curr_pos][curr_time + T_STOP].find(var) ==
					nodes[curr_pos][curr_time + T_STOP].end()
					)
				{
					// if the node was not created, create one
					newNode = new Node(curr_pos, curr_time + T_STOP, var);
					// link with the curr node
					node->addOutNode(newNode);
					newNode->addInNode(node);
					active.push_back(newNode);
					nodes[curr_pos][node->getTime() + T_STOP][var] = newNode;
				}
				else
				{
					// if the node was already created, just create the edge
					newNode = nodes[curr_pos][curr_time + T_STOP][var];
					// link with the curr node
					node->addOutNode(newNode);
					newNode->addInNode(node);
				}
			}
		}
	}

	// the train is waiting for departure --> 
	// Scenario 1) continue waiting if it is not in the first station
	// Scenario 2) move to the next station -->
	//				21) arrive and stop if there is a compulsory stop
	//				22) arrive and pass full speed
	//				23) arrive and wait for departure
	else if (state == State::Wait){
		// check if the time is not beyond the latest arrival
		if (latestDep_v[curr_pos] > curr_time + T_STEP){
			for (State var : {State::Wait, State::Ready})
			{
				// 1) continue waiting if this is not the first station
				if (node->getPosition() != path[0]){
					Node *newNode;
					if (!nodes[curr_pos].empty() &&
						!nodes[curr_pos][curr_time + T_STEP].empty() &&
						nodes[curr_pos][curr_time + T_STEP].find(var) !=
						nodes[curr_pos][curr_time + T_STEP].end()
						)
					{
						newNode = nodes[curr_pos][curr_time + T_STEP][var];
						// link with the curr node
						node->addOutNode(newNode);
						newNode->addInNode(node);
					}
					else
					{
						newNode = new Node(curr_pos, curr_time + T_STEP, var);
						// link with the curr node
						node->addOutNode(newNode);
						newNode->addInNode(node);
						active.push_back(newNode);
						nodes[curr_pos][curr_time + T_STEP][var] = newNode;
					}
				}
			}
		}
	}
	else if (state == State::Ready){
		// 2) next station
		// 21) stop at the next station if there is a compulsory stop
		if (stopRequested){
			uint moving_time = network.getNetwork()[curr_pos][next_pos][Scenario::StopStop];
			// check if the time is not beyond the latest arrival
			if (latestDep_v[next_pos] > curr_time + moving_time + T_STOP){
				Node *newNode;
				if (!nodes[next_pos].empty() &&
					!nodes[next_pos][curr_time + moving_time].empty() &&
					nodes[next_pos][curr_time + moving_time].find(State::Stop) !=
					nodes[next_pos][curr_time + moving_time].end()
					)
				{
					newNode = nodes[next_pos][curr_time + moving_time][State::Stop];
					// link with the curr node
					node->addOutNode(newNode);
					newNode->addInNode(node);
				}
				else {
					// create the new node
					newNode = new Node(next_pos, curr_time + moving_time, State::Stop);
					// link with the curr node
					node->addOutNode(newNode);
					newNode->addInNode(node);
					active.push_back(newNode);
					nodes[next_pos][curr_time + moving_time][State::Stop] = newNode;
				}

			}
		}
		else // if there is no compulsory stop in the next station
		{
			// 22) move and pass full speed
			{
				uint moving_time = network.getNetwork()[curr_pos][next_pos][Scenario::StopFull];
				// check if the time is not beyond the latest arrival
				if (latestDep_v[next_pos] > curr_time + moving_time){
					Node *newNode;
					if (!nodes[next_pos].empty() &&
						!nodes[next_pos][curr_time + moving_time].empty() &&
						nodes[next_pos][curr_time + moving_time].find(State::Move) !=
						nodes[next_pos][curr_time + moving_time].end()
						)
					{
						newNode = nodes[next_pos][curr_time + moving_time][State::Move];
						// link with the curr node
						node->addOutNode(newNode);
						newNode->addInNode(node);
					}
					else {
						// create the new node
						newNode = new Node(next_pos, curr_time + moving_time, State::Move);
						// link with the curr node
						node->addOutNode(newNode);
						newNode->addInNode(node);
						active.push_back(newNode);
						nodes[next_pos][curr_time + moving_time][State::Move] = newNode;
					}

				}
			}
			// 22) wait at the next station if it is a station
			if (network.getStationBlockID(next_pos, next_pos) != -1){
				uint moving_time = network.getNetwork()[curr_pos][next_pos][Scenario::StopStop];
				// check if the time is not beyond the latest arrival
				if (latestDep_v[next_pos] > curr_time + moving_time + T_STOP){
					Node *newNode;
					if (!nodes[next_pos].empty() &&
						!nodes[next_pos][curr_time + moving_time].empty() &&
						nodes[next_pos][curr_time + moving_time].find(State::Wait) !=
						nodes[next_pos][curr_time + moving_time].end()
						)
					{
						newNode = nodes[next_pos][curr_time + moving_time][State::Wait];
						// link with the curr node
						node->addOutNode(newNode);
						newNode->addInNode(node);
					}
					else {
						// create the new node
						newNode = new Node(next_pos, curr_time + moving_time, State::Wait);
						// link with the curr node
						node->addOutNode(newNode);
						newNode->addInNode(node);
						active.push_back(newNode);
						nodes[next_pos][curr_time + moving_time][State::Wait] = newNode;
					}

				}
			}
		}
	}

	// the train is moving full speed --> 
	// Scenario 1) continue moving full speed if there is no stop
	// Scenario 2) move and stop if there is a stop
	else if (state == State::Move){
		// 2) move and stop if there is a stop
		if (stopRequested)	{
			uint moving_time = network.getNetwork()[curr_pos][next_pos][Scenario::FullStop];
			// check if the time is not beyond the latest arrival
			if (latestDep_v[next_pos] > curr_time + moving_time + T_STOP){
				Node *newNode;
				if (!nodes[next_pos].empty() &&
					!nodes[next_pos][curr_time + moving_time].empty() &&
					nodes[next_pos][curr_time + moving_time].find(State::Stop) !=
					nodes[next_pos][curr_time + moving_time].end()
					)
				{
					newNode = nodes[next_pos][curr_time + moving_time][State::Stop];
					// link with the curr node
					node->addOutNode(newNode);
					newNode->addInNode(node);
				}
				else {
					// create the new node
					newNode = new Node(next_pos, curr_time + moving_time, State::Stop);
					// link with the curr node
					node->addOutNode(newNode);
					newNode->addInNode(node);
					active.push_back(newNode);
					nodes[next_pos][curr_time + moving_time][State::Stop] = newNode;
				}

			}
		}
		else // if there is no compulsory stop in the next station
		{
			// 1) continue moving full speed
			{
				uint moving_time = network.getNetwork()[curr_pos][next_pos][Scenario::FullFull];
				// check if the time is not beyond the latest arrival
				if (latestDep_v[next_pos] > curr_time + moving_time){
					Node *newNode;
					if (!nodes[next_pos].empty() &&
						!nodes[next_pos][curr_time + moving_time].empty() &&
						nodes[next_pos][curr_time + moving_time].find(State::Move) !=
						nodes[next_pos][curr_time + moving_time].end()
						)
					{
						newNode = nodes[next_pos][curr_time + moving_time][State::Move];
						// link with the curr node
						node->addOutNode(newNode);
						newNode->addInNode(node);
					}
					else {
						// create the new node
						newNode = new Node(next_pos, curr_time + moving_time, State::Move);
						// link with the curr node
						node->addOutNode(newNode);
						newNode->addInNode(node);
						active.push_back(newNode);
						nodes[next_pos][curr_time + moving_time][State::Move] = newNode;
					}

				}
			}
			// 22) wait at the next station if it is a station
			if (network.getStationBlockID(next_pos, next_pos) != -1){
				uint moving_time = network.getNetwork()[curr_pos][next_pos][Scenario::FullStop];

				// check if the time is not beyond the latest arrival
				if (latestDep_v[next_pos] > curr_time + moving_time){
					Node *newNode;
					if (!nodes[next_pos].empty() &&
						!nodes[next_pos][curr_time + moving_time].empty() &&
						nodes[next_pos][curr_time + moving_time].find(State::Wait) !=
						nodes[next_pos][curr_time + moving_time].end()
						)
					{
						newNode = nodes[next_pos][curr_time + moving_time][State::Wait];
						// link with the curr node
						node->addOutNode(newNode);
						newNode->addInNode(node);
					}
					else {
						// create the new node
						newNode = new Node(next_pos, curr_time + moving_time, State::Wait);
						// link with the curr node
						node->addOutNode(newNode);
						newNode->addInNode(node);
						active.push_back(newNode);
						nodes[next_pos][curr_time + moving_time][State::Wait] = newNode;
					}

				}
			}
		}
	}
}


////////////////////////////////////////////////////////////////////////////////
void Graph::computeSP(matd &costs, Network &n, Path *genPaths){
	// declaration of the precedency list for storing the optimal path
	pred.clear();

	// if there is no feasible path
	if (sink.inNodes_.size() == 0)
		return;

	// initialize the revenues with very small values
	map<Node*, double> rev;
	for (auto it : ordering)
		rev[it] = -infd;

	// initialize the revenue of the source and first nodes
	rev[ordering[0]] = 0;
	for (auto it : ordering[0]->getOutNode()){
		rev[it] = revDep[it];
		pred[it] = ordering[0];
	}

	// update distances in topological order and construct the otimal path
	for (size_t i = 1; i < ordering.size() - 1; i++){ // go through all the nodes in topological order
		// start from i=1, to skip the first nodes which are already initialized
		// and also the last nodes
		if (ordering[i]->getPosition() == path[path.size() - 1]){
			if (rev[ordering[i]] > rev[&sink])
			{
				rev[&sink] = rev[ordering[i]];
				pred[&sink] = ordering[i];
			}
			continue;
		}
		for (auto it : ordering[i]->getOutNode()){ // explore the outgoing edges
			{
				// BLOCK PRICES
				// block the current block [AB] between t_A and t_B (excluded)
				double edge_rev = 0.0;
				uint b = n.getStationBlockID(ordering[i]->getPosition(), it->getPosition());
				uint t_A = ordering[i]->getTime();
				uint t_B = it->getTime();
				edge_rev = -costs.colSum(b,currStep(t_A),currStep(t_B));

				// block the current block [AB] before t_A 
				// if the train is coming to A in fullspeed
				State state_A = ordering[i]->getState();
				if (state_A == State::Move){
					edge_rev -= costs.colSum(b, currStep(t_A - BLOCK_RULE), currStep(t_A));
				}

				// block the current block [AB] after t_B
				// if the train is ready to move to the next block slowly (not full speed)
				State state_B = it->getState();
				if (state_B == State::Ready){
					edge_rev -= costs.colSum(b, currStep(t_B), currStep(t_B + BLOCK_RULE));
				}
				else if (state_B == State::Move) // if we are passing full speed at B
				{
					// check if B is a stopping station
					string pos = it->getPosition();
					int b_station = n.getStationBlockID(pos, pos);
					if (b_station != -1){ // if B is a stopping station, block the station before t_B
						edge_rev -= costs.colSum(b_station, currStep(t_B - BLOCK_RULE), currStep(t_B));
					}
				}
				// update the precedency list if taking the current edge gives a higher revenue
				if (rev[ordering[i]] + edge_rev > rev[it])
				{
					rev[it] = rev[ordering[i]] + edge_rev;
					pred[it] = ordering[i];
				}
			}
		}
	}
	phi = rev[ordering[ordering.size() - 1]];
	if (phi <= 0){ // in case the null path is better
		phi = 0;
		pred.clear();
	}
}

uint Graph::AddPath(Path &p, Network &n) {

	// get the network sizes
	uint S = n.getS();
	uint T = n.getT();
	uint B = n.getB();

	// init departures and arrivals
	vector<int> departures_ = vector<int>(S, -1);
	vector<int> arrivals_ = vector<int>(S, -1);

	// initialize subgradient with capacity
	mati capCons_ = mati(B, T);

	// go through all the stations until the start station
	auto it = pred.find(&sink);
	if (it != pred.end()){
		while (true)
		{
			it = pred.find(it->second);
			// get the station index
			uint s = find(n.path_terminus.begin(), n.path_terminus.end(), it->first->getPosition()) - n.path_terminus.begin();

			// get the time at the station
			uint t = it->first->getTime();

			// departure time from the station
			if (departures_[s] == -1)
				departures_[s] = currStep(t);

			// arrival to the station
			arrivals_[s] = currStep(t);

			if (it->second == &source)
				break;

			// get the block index
			uint b = n.getStationBlockID(it->second->getPosition(), it->first->getPosition());
			uint t_A = it->second->getTime();
			uint t_B = it->first->getTime();

			/////// BLOCKING RULES
			// Blocking the current block [AB] between t_A and t_B
			for (int dt = currStep(t_A); dt < currStep(t_B); dt++)
			{
				capCons_.at(b, dt) = 1;

			}
			// block the current block [AB] before t_A 
			// if the train is coming to A in fullspeed
			State state_A = it->second->getState();
			if (state_A == State::Move){
				for (int dt = currStep(t_A - BLOCK_RULE); dt < currStep(t_A); dt++)
				{
					capCons_.at(b, dt) = 1;

				}
			}

			// block the current block [AB] after t_B
			// if the train is ready to move to the next block slowly (not full speed)
			State state_B = it->first->getState();
			if (state_B == State::Ready){
				for (int dt = currStep(t_B); dt < currStep(t_B + BLOCK_RULE); dt++)
				{
					capCons_.at(b, dt) = 1;

				}
			}
			else if (state_B == State::Move) // if we are passing full speed at B
			{
				// check if B is a stopping station
				string pos = it->first->getPosition();
				int b_station = n.getStationBlockID(pos, pos);
				if (b_station != -1){ // if B is a stopping station, block the station before t_B
					for (int dt = currStep(t_B - BLOCK_RULE); dt < currStep(t_B); dt++)
					{
						capCons_.at(b_station, dt) = 1;

					}
				}
			}
		}
	}

	// get the departure revenue & dual obj
	double revenue_ = 0.0;
	double phi_ = 0.0;
	if (it != pred.end()){
		// the departure revenue
		revenue_ = revDep[it->first];
		// set the objective value
		phi_ = phi;
	}

	// check if the path already exist
	int pathID = p.findPathID(departures_, arrivals_);

	if (pathID != -1){ // already generated 
		int ind = pathID;
		// update the dual obj
		p.setPhi(phi_, ind);
		// latest id
		p.setLatestID(ind);
	}
	else // new path to be added
	{
		// add the newly generated path
		p.addNewPath(departures_, arrivals_, phi_, revenue_, capCons_);
	}
	return p.getLatestID() + 1;
}


////////////////////////////////////////////////////////////////////////////////
Graph::~Graph() {

	// free all the dynamically allocated nodes
	for (auto n : nodes)
		for (auto ns : n.second)
			for (auto it : ns.second)
				delete it.second;
	nodes.clear();	


}