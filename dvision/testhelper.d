module testhelper;

import std.stdio;
import std.conv : to;

int testCount;
int moduleTestCount;
bool testInProgress;

private string lastTestedModuleName;

void test(string name, void function() testFunc, string fileName = __FILE__) {
	if (lastTestedModuleName != null && lastTestedModuleName != fileName) {
		writeModuleSummary();
		moduleTestCount = 0;
		lastTestedModuleName = fileName;
	} else {
		lastTestedModuleName = fileName;
	}
	write(fileName ~ ": " ~ name);
	scope(success) writeln(" [OK]");
	scope(failure) writeln(" [FAIL]");
	testInProgress = true;
	testFunc();
	testInProgress = false;
	++moduleTestCount;
	++testCount;
}

void writeModuleSummary() {
	writeln("[" ~ to!string(moduleTestCount) ~ "] " ~ lastTestedModuleName);
}