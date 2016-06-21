--------------------------------------------------------------
-		README - TIMETABLING
--------------------------------------------------------------

* Compilation:

* Data:
	- General:
		*** The input data consists of one cvs files
		*** The data reader is case sensitive 
		(i.e. pay attention to capital letters)
		*** The data reader is also senstive to spaces
		*** The data should be given in the following order
		(durations >> stations >> requests >> terminus)
		*** The capacity can be either one or more.
		*** Specifies the duration of the train to cross the block
		*** The duration value has to be an integer
		*** The duration is in seconds
		*** Specifies the blocks by giving the name of the two edges
		*** The tracks should be linked and form one line 
		(one line single track assumption)
		*** The tracks should be given from one terminus to the other
		*** The name of the destination and orgine station should be 
		already given in Stations.
		*** The times are integers and in seconds
