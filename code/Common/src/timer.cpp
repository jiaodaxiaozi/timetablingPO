#include "timer.h"
#include <iostream>

////////////////////////////////////////////////////////////////////////////////
Timer::Timer() {
    tic();
}


////////////////////////////////////////////////////////////////////////////////
void Timer::tic() {
    then_ = chrono::high_resolution_clock::now();
}


////////////////////////////////////////////////////////////////////////////////
double Timer::toc() {
	// calculate the time difference
	auto now = chrono::high_resolution_clock::now();
	auto duration = now - then_;
	auto micros = std::chrono::duration_cast<std::chrono::microseconds>(duration).count();
	// convert from micro-sec to sec
	const double seconds = micros / (double)1e6;
	// print out
	cout << "tictoc: Elapsed time is " << seconds << "seconds" << endl;
	// return the time difference
	return seconds;
}
