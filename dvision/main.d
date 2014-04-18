import std.stdio;

import std.conv : to;

import testhelper;
import rect;

int main(string[] argv)
{
	version(unittest) {
		writeModuleSummary();
		writeln("["~ to!string(testCount) ~"] All tests are succeed! ");
	} else {

	}
    
    return 0;
}