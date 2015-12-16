#ifndef TIMEPOS_H
#define TIMEPOS_H

#include <iostream>
#include <functional>

class TimePos  {
public:
    enum State {
        Fullspeed, Wait, Stop
    };
    
    TimePos(State state, int time, std::string position, int waitTimeRemaining, int path_id=0);
    
    State state_; // train state at a station
    int time_; // clock time
    std::string position_; // train position 
    int waitTimeRemaining_; // waiting time remained
	int path_id_; // the path id
    
	// equality comparison
    virtual bool operator == (const TimePos& o) const;
    
    //  friends
    friend std::ostream& operator << (std::ostream& out, const TimePos& node);
};


namespace std
{
    template<>
    struct hash<TimePos> {
        size_t operator()(const TimePos& tp) const {
            size_t hash = 7;
            hash = 61 * hash + tp.state_;
            hash = 61 * hash + tp.time_;
            hash = 61 * hash + std::hash<std::string>()(tp.position_);
            hash = 61 * hash + tp.waitTimeRemaining_;
            return hash;
        }
    };
}

#endif