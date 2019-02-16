#ifndef KOMPILATOR_TYPES_H
#define KOMPILATOR_TYPES_H

#include <string>
#include <cln/cln.h>

struct Variable {
    std::string name = "";
    long long value = -1;
    long long index = -1;
	long long indexFirst = -1;
	long long indexSecond = -1;
    bool isArray = false;
    long long arrayLength = 0;
    long long arrayIndex = -1;
    bool isIndexAVariable = false;
    bool isTemporary = false;
	std::string rejestr = "";
	bool isRegister = false;
	long long valueRegister = -1;
	std::string isIndexAVariableName = "";
};

#endif
