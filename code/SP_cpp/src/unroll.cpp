#include <iostream>
#include <vector>
#include <algorithm>
#include <cmath>
#include <deque>
#include <mex.h>
#include <string>

#include "unroll.h"
#include "pathsearch.h"

using namespace std;



////////////////////////////////////////////////////////////////////////////////
void recursive_unroll(
    const TrainRequest& request,
    const TimePos& sink,
    const Graph<string, int>& path,
    const DurationTable& durations,
    const unordered_map<string, int>& windows,
    Graph<TimePos, float>& network,
    vector<const Node<TimePos, float>*>& ordering,
    deque<const Node<TimePos, float>*>& actives) 
{

    //  nothing to do if there is no node left
    if (actives.empty())
        return;

    //  get first active node
    const Node<TimePos, float>* currNode = actives.front();
    actives.pop_front();

    //  dead node if time limit is reached
    const TimePos& currTimePos = currNode->label();
    const string& currStation = currTimePos.position_;
    const int currWindow = windows.at(currStation);

    if (currTimePos.time_ > currWindow)
        return;

    //  remember node order
    ordering.push_back(currNode);

    //  when reached destination, add free edge to sink and return
    if (currStation == request.to) {
        network.addEdge(currTimePos, sink); // no cost in the ending node (will be added in cost assignment)
        return;
    }

    //  should stop if next station is destination or requested
    //    assumes existence of currStation key
    const string& nextStation = path.node(currStation)->firstLabelTo();

    bool stopRequested = (   
        (request.to == nextStation) || 
        (find(   // O(n) time
            request.intermediate_stops.begin(),
            request.intermediate_stops.end(),
            nextStation
        ) != request.intermediate_stops.end())
    );

    //  wait (don't wait in first layer. it is constructed according to profit beforehand)
    if (currStation != request.from && 
        currTimePos.state_ == TimePos::State::Wait) 
    {
		int t = currTimePos.time_ + TIME_STEP;  // randomly wait

        if (t <= currWindow)
        {
			TimePos nextStay(TimePos::State::Wait, t, currStation, 0);
            bool existed = network.hasNode(nextStay);
            const auto nextNode = network.addNode(nextStay);
            network.addEdge(currTimePos, nextStay); // the cost is to be set just before the SP computation (see. assignEdgeCosts)

			if (!existed){
				actives.push_front(nextNode);
			}        
        }
    }

	//  Intermediate compulsory stop
	if (currStation != request.from &&
		currTimePos.state_ == TimePos::State::Stop)
	{
		int t = currTimePos.time_ + 6*TIME_STEP;  // minimal stop time (e.g. 3min)

		if (t <= currWindow)
		{
			TimePos nextStay(TimePos::State::Wait, t, currStation, 0);
			bool existed = network.hasNode(nextStay);
			const auto nextNode = network.addNode(nextStay);
			network.addEdge(currTimePos, nextStay); // the cost is to be set just before the SP computation (see. assignEdgeCosts)

			if (!existed){
				actives.push_front(nextNode);
			}
		}
	}


    //  get duration table
    //  NOTE:
    //    segfault if nextStation (or currStation for that matter) is empty 
    //    string, which is prevented by earlier 
    //      currStation == request.to 
    //    exit
    const auto& currDurations = durations.at(currStation).at(nextStation);

    //  *-stop
	/// !!! With this we can stop in block signals even though we do not request it
	// for this add if(stopRequested)
	if (stopRequested)
	{
        int t = currTimePos.time_;

        //  full-stop
        if (currTimePos.state_ == TimePos::State::Fullspeed)
            t += currDurations.at(BlockType::FullStop);
        //  stop-stop
        else 
            t += currDurations.at(BlockType::StopStop);
        
        const int nextWindow = windows.at(nextStation);

        if (t <= nextWindow)
        {
			TimePos nextFullStop(TimePos::State::Stop, t, nextStation, 0);

            bool existed = network.hasNode(nextFullStop);
            const auto nextNode = network.addNode(nextFullStop);
            network.addEdge(currTimePos, nextFullStop); // cost is assigned in costAssignment

			if (!existed) {
				actives.push_front(nextNode);	
			}
                
        }
    }

    //  *-full
    //  only applicable if no stop is requested
    if (!stopRequested)
    {
        if (currTimePos.state_ == TimePos::State::Wait ||
            currTimePos.state_ == TimePos::State::Fullspeed) 
        {
            int t = currTimePos.time_;

            //  full-full
            if (currTimePos.state_ == TimePos::State::Fullspeed)
                t += currDurations.at(BlockType::FullFull);
            //  stop-full
            else
                t += currDurations.at(BlockType::StopFull);

            const float nextWindow = windows.at(nextStation);

            if (t <= nextWindow)
            {    
                TimePos nextStopFull(TimePos::State::Fullspeed, t, nextStation, 0);
                bool existed = network.hasNode(nextStopFull);
                const auto nextNode = network.addNode(nextStopFull);
                network.addEdge(currTimePos, nextStopFull); // cost in cost assignment
        
                if (!existed)
                    actives.push_back(nextNode);
            }
        }
    }
}


////////////////////////////////////////////////////////////////////////////////
int unroll(
    const TrainRequest& request,
    const Graph<string, int>& track,
    const DurationTable& durations,
    Graph<TimePos, float>& network,
	vector<const Node<TimePos, float>*>& ordering, 
	unordered_map<int, int>& path_ids)
{
    //  find path from start to goal
    Graph<string, int> path;
	exctractPath(track, request.from, request.to, path);

    //  get upper time bounds
    unordered_map<string, int> windows;
	stationWindows(request, path, durations, windows);	
	
    //  add source and sink nodes
    TimePos source(TimePos::State::Wait, 0, "START", 0);
    network.addNode(source);

    TimePos sink(TimePos::State::Wait, 0, "END", 0);
    network.addNode(sink);

    //  spawn initial layer in from-station according to profit function
    deque<const Node<TimePos, float>*> actives;

    for (int t = request.triangle_t1; t <= request.triangle_t3; t += TIME_STEP) 
    {
        TimePos node(TimePos::State::Wait, t, request.from, 0);
        const auto nodePtr = network.addNode(node);
        network.addEdge(source, node); // no cost in the starting node (will be added in cost assignment)

        actives.push_front(nodePtr);
    }

    //  iteratively (unrolled recursion using deque) explore possible routes
    ordering.push_back(network.node(source));

    while (!actives.empty()) 
    {
        recursive_unroll(
            request,
            sink,
            path,
            durations,
            windows,
            network,
            ordering,
            actives
        );
    }

    auto sinkNode = network.node(sink);
    ordering.push_back(sinkNode);

	// TODO: This is not correctly accounting and identifying the paths
	int val = 1;
	for (auto it : sinkNode->inEdges())
	{
		path_ids[it.first->id()] = val;
		val += 1;
	}


    if (sinkNode->inEdges().size() == 0) 
		cerr << "[warning] unroll: no valid path for request " << request.train_id << endl;

	// TODO: not really returning the number of possible paths for this request
	return sinkNode->inEdges().size();
}


////////////////////////////////////////////////////////////////////////////////
// Maps the blocks with cost matrix linearly
void linearBlockMatrixMapping(
    const Graph<string, int>& track,
//	const StationTable& stations,
	unordered_map<string, size_t>& ids)
{
	for (const auto& node : track.nodes()){
		ids[node.first] = node.second.id();
	}
        
}


////////////////////////////////////////////////////////////////////////////////
//  assignEdgeCosts
//   this is being separated from unroll as costs change each iteration, while
//   the graph from unroll is fix
void assignEdgeCosts(
    const matf& costs,                          //  (block x steps) cost matrix
	const map<set<string>, pair<int, int>> &ids_cap, //  block -> cost matrix row
    const TrainRequest& request,
    Graph<TimePos, float>& network)
{
    //  assign each edges' cost
    for (auto& fromkv : network.nodes()) 
    {
        auto from = &fromkv.second;

        for (auto& edge: from->outEdges()) 
        {
            auto to = edge.first;

            const int t1 = nextStep(from->label().time_, TIME_STEP);
            const int t2 = nextStep(to->label().time_, TIME_STEP);

            const int col1 = t1 / TIME_STEP;
            const int col2 = t2 / TIME_STEP;

            string from_pos = from->label().position_;
			string to_pos = to->label().position_;
			
            //  normal nodes get costs from matrix
            if (from_pos != "START" && to_pos != "END") 
            {
				// find the arc
				set<string> arc;
				arc.insert(from_pos);
				arc.insert(to_pos);
				const auto& it = ids_cap.find(arc);
				// check the existence
				assert(it != ids_cap.end());
				// get the block identifier
				const size_t row = it->second.first-1;
				// capacity usage cost minus capacity
				edge.second = costs.colSum(row, col1, col2)-it->second.second; // here we can add blocking rules				

            } 

			//  first layer nodes get assigned negative profit			
			if (from_pos == "START") { // if Source Node
                edge.second = -request.profit(t2);
            }

            //  edges to the virtual end node have no costs for now
			// but here we append the constant cost 
			if (to_pos == "END"){
				edge.second = 0;
				for (auto it : ids_cap) {
					int cap = it.second.second;
					int row = it.second.first-1;
					edge.second -= cap*costs.colSum(row, 0, costs.cols() - 1);
				}

			}
                
        }
    }
}


////////////////////////////////////////////////////////////////////////////////
void stationWindows(
    const TrainRequest& request,
    const Graph<string, int>& path,
    const DurationTable& durations,
    unordered_map<string, int>& windows)
{
    const Node<string, int>* curr = path.node(request.to);
    assert(curr != nullptr);
    const Node<string, int>* prev = curr->firstFrom();

    int t = request.window_t2;
    windows[curr->label()] = t;

    while (curr != nullptr && prev != nullptr) 
    {
        const auto& durs = durations.at(curr->label()).at(prev->label());
        float dt = 0.0f;

        if (curr->label() == request.to)
            dt = durs.at(BlockType::FullStop);
        else // here we could optimize this by considering intermediate stops as well
            dt = durs.at(BlockType::FullFull);

        t -= dt;

        windows[prev->label()] = t;

        curr = prev;
        prev = curr->firstFrom();
    }

    // cout << "START, " << request.triangle_t2 << endl;
    // const Node<string, int>* node = path.node(request.from);

    // while (node != nullptr) {
    //     cout << node->label() << ", " << windows[node->label()] << endl;
    //     node = node->firstTo();
    // }
}





























