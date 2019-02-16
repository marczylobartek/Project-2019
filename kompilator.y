%{
#include <string>
#include <iostream>
#include <sstream>
#include <vector>
#include <map>
#include <cmath>
#include <stack>
#include <algorithm>  
#include <fstream>

#include <cln/cln.h> // fprintbinary

#include "types.h"

extern int yylex();
int yyerror(const char*);
extern FILE *yyin, *yyout;
extern int yylineno;
extern char *yytext;

using namespace std;
using namespace cln;

Variable empty;
Variable accumulator[8];  
vector<string> commands;
map<string, Variable*> infiniteMemory;
stack<size_t> cond_start_ip;
stack<size_t> cond_endOf_ip;
stack<size_t> com_start_ip;
stack<size_t> com_endOf_ip;
stack<size_t> else_start_ips;
stack<long long> temp_vars;
map<string, Variable*> rejestry;
string r[] = {"D", "E", "F", "G", "H"};
bool done = false;
fstream * myOut;
string re;

 
long long varCounter = 10; 

size_t ip()
{
    return commands.size();
}

string findFreeRegister(){

   for(int i=0; i < 5; i++){
   
    if (rejestry.find(r[i]) == rejestry.end())    {
        return r[i];  
		}
   }
     return "";
}

 
Variable* put_new_variable(string name, long long arrayLength, long long arrayF, long long arrayS) {
    if (infiniteMemory.count(name) > 0) {
        return nullptr;
    }
    Variable *var = new Variable();
    var->name = name;
    var->isArray = (arrayLength > 0);
    var->value =  var->isArray ? 1 : -1;
    var->index = varCounter;
	var->indexFirst = arrayF;
	var->indexSecond = arrayS;
    var->arrayLength = var->isArray ? arrayLength : 0;
    var->arrayIndex = -1;
    var->isIndexAVariable = false;
    varCounter += var->isArray ? arrayLength + 1 : 1;
	re = findFreeRegister();
     
	if (re != "" && (arrayLength == 0) ){

	    var->isRegister = true;
		var->rejestr = re;
		var->valueRegister = -1;
		rejestry[re] = var;
	}
	
	
    infiniteMemory[name] = var;
    return infiniteMemory[name];
}


 

// zmienna tymczasowa do petli np FOR
Variable* put_new_temp_variable(string name) {
    if (infiniteMemory.count(name) > 0) {
        return nullptr;
    }
    Variable *var = new Variable();
    var->name = name;
    var->value = 1;
    var->isTemporary = true;
    var->index = varCounter + temp_vars.size();
    temp_vars.push(var->index);
	re = findFreeRegister();
	if (re != ""){
	    var->isRegister = true;
		var->rejestr = re;
		var->valueRegister = -1;
		rejestry[re] = var;
	}
	
    infiniteMemory[name] = var;
    return infiniteMemory[name];
}

 
Variable* get_variable(string name) {
    if (infiniteMemory.count(name) < 1) {
        return nullptr;
    }
    return infiniteMemory[name];
}

size_t delete_temp_variable(string name) {
    Variable *var = get_variable(name);
    if (var != nullptr) {
	if (var->rejestr != ""){
		rejestry.erase(var->rejestr);
	}  
        delete var;
        temp_vars.pop();
    }
    return infiniteMemory.erase(name);
}

string cln_to_string(long long n) {
    stringstream sstring1;
    sstring1 << n;
    return sstring1.str();
}

 

 void mr8_store(string X) {
    string R = "STORE ";
    commands.push_back(R.append(X));
}

void mr8_load(string X) {
        string R = "LOAD ";
        commands.push_back(R.append(X));
}

void mr8_get(string X) {
    string R = "GET ";
    commands.push_back(R.append(X));
}

void mr8_put(string X) {
	string R = "PUT ";
    commands.push_back(R.append(X));
}

void mr8_copy(string X, string Y) {
	string R = "COPY ";
    commands.push_back(R.append(X).append(" ").append(Y));
}

void mr8_add(string X, string Y) {
	string R = "ADD ";
    commands.push_back(R.append(X).append(" ").append(Y));
}

void mr8_sub(string X, string Y) {
	string R = "SUB ";
    commands.push_back(R.append(X).append(" ").append(Y));
}

void mr8_half(string X) {
	string R = "HALF ";
    commands.push_back(R.append(X));
}

void mr8_inc(string X) {
	string R = "INC ";
    commands.push_back(R.append(X));
}

void mr8_dec(string X) {
	string R = "DEC ";
    commands.push_back(R.append(X));
}

void mr8_jump(long long j) {
    string R = "JUMP ";
    commands.push_back(R.append(cln_to_string(j)));
}

void mr8_jzero(string X, long long j) {
	string R = "JZERO ";
     commands.push_back(R.append(X).append(" ").append(cln_to_string(j)));
}

void mr8_jodd(string X, long long j) {
    string R = "JODD ";
      commands.push_back(R.append(X).append(" ").append(cln_to_string(j)));
}

void mr8_halt() {
    commands.push_back("HALT");
}



 

 
void print_all_commands() {
    for (vector<string>::iterator iter1 = commands.begin(); iter1 != commands.end(); ++iter1) {
        cout << *iter1 << "\n";
    }
}


 
void print_all_commandsToFile() {
    for (vector<string>::iterator iter1 = commands.begin(); iter1 != commands.end(); ++iter1) {
        *myOut << *iter1 << "\n";
    }
	myOut->close();
}

 
bool same_memory_cell(Variable var1, Variable var2) {
    if (var1.index < 0 || var2.index < 0)
    {
        return false;
    }
    long long localIndex1 = var1.index;
    long long localIndex2 = var2.index;
    if (var1.isArray) {
        if (!var1.isIndexAVariable) {
            localIndex1 += 1 + var1.arrayIndex;
        } else {
            return (var1.name == var2.name && var2.isArray && var2.isIndexAVariable && var2.arrayIndex == var1.arrayIndex);
        }
    }
    if (var2.isArray) {
        if (!var2.isIndexAVariable) {
            localIndex2 += 1 + var2.arrayIndex;
        } else {
            return (var1.name == var2.name && var1.isArray && var1.isIndexAVariable && var1.arrayIndex == var2.arrayIndex);
        }
    }
    return localIndex1 == localIndex2;
}


long long get_real_index(Variable var1) {
    long long retValue = var1.index;
    if (var1.isArray) {
        if (!var1.isIndexAVariable) {
            retValue +=   1 +  var1.arrayIndex;
        } else {
            retValue = var1.arrayIndex;
        }
    }
    return retValue;
}

 
void calculate_num_to_acc(long long number1)
{
      mr8_sub("B", "B");
    if (number1 > 0)
    {
        stringstream sstring1;
        fprintbinary(sstring1, number1);
        string bin_ = sstring1.str();
        mr8_inc("B");
        for (size_t i = 1; i < bin_.size(); ++i)
        {
            mr8_add("B", "B");
            if (bin_[i] == '1')
            {
                mr8_inc("B");
            }
        }
    }
}

 
void calculate_index_i(long long number1)
{
    mr8_sub("A", "A");
    if (number1 > 0)
    {
        stringstream sstring1;
        fprintbinary(sstring1, number1);
        string bin_ = sstring1.str();
        mr8_inc("A");
        for (size_t i = 1; i < bin_.size(); ++i)
        {
            mr8_add("A", "A");
            if (bin_[i] == '1')
            {
               mr8_inc("A");
            }
        }
    }
}

 
void calculate_array_index(Variable &v)
{
	calculate_index_i(get_real_index(v));
    mr8_load("B");
	calculate_index_i(v.index);
	mr8_load("A");
    mr8_add("B", "A");
}

void calculate_array_indexRegister(Variable &v)
{
 
    mr8_copy("B", v.isIndexAVariableName);
	calculate_index_i(v.index);
	mr8_load("A");
    mr8_add("B", "A");
}

// 0, 1
void store_accumulator_in_variable(Variable &var1)
{
    if (var1.isTemporary)
    {
        string errorHandler = "modyfikacja zmiennej iterujacej " + var1.name.substr(1);
        yyerror(errorHandler.c_str());
        return;
    }

    if (!var1.isArray)
    {
	    calculate_index_i(var1.index);
        mr8_store("B");
    }
    else
    {
        if (!var1.isIndexAVariable) // isIndexAVariable to zmienna ktora okresla czy index w tablicy jest zmienna( pidentifier) czy liczbą(num)
        {
		 
		    calculate_index_i(get_real_index(var1));
            mr8_store("B");
			  
        }
        else
        {
		  	if(var1.isIndexAVariableName != ""){
			   
   
			
			  calculate_index_i(0);
            mr8_store("B");
           calculate_array_indexRegister(var1);
            calculate_index_i(1);
            mr8_store("B");
            calculate_index_i(0);
            mr8_load("B");
			calculate_index_i(1);
            mr8_load("A");
			mr8_store("B");
          
		   
		 
		}else{		
		    calculate_index_i(0);
            mr8_store("B");
            calculate_array_index(var1);
            calculate_index_i(1);
            mr8_store("B");
            calculate_index_i(0);
            mr8_load("B");
			calculate_index_i(1);
            mr8_load("A");
			mr8_store("B");
		}
		
             
        }
    }

    if (var1.value < 0)
    {
        var1.value = 1;  
    }
    accumulator[0] = var1;
}

void store_accumulator_in_register(Variable &var1)
{
    if (var1.isTemporary)
    {
        string errorHandler = "modyfikacja zmiennej iterujacej " + var1.name.substr(1);
        yyerror(errorHandler.c_str());
        return;
    }

    if (!var1.isArray)
    {
	
	 mr8_copy(var1.rejestr, "B");

    }
    

    if (var1.value < 0)
    {
        var1.value = 1;  
    }
    accumulator[0] = var1;
}


void load_variable_to_accumulator(Variable var1)
{

 
    if (var1.value < 0) {
        string errorHandler = "niezainicjalizowana zmienna " + var1.name;
        yyerror(errorHandler.c_str());
    }

    if (same_memory_cell(accumulator[0], var1))
    {
	
	
 
	if(done)	{
		done = false;
	}else	{ 
		return;
	}
       
    }

    accumulator[0] = var1;

    if (var1.name == "@")
    {
        calculate_num_to_acc(var1.value);
    }
    else if (!var1.isArray)
    {
	calculate_index_i(var1.index);
    mr8_load("B");
 
    }
    else
    {
        if (!var1.isIndexAVariable)
        {
      
 	      
			calculate_index_i(get_real_index(var1));
            mr8_load("B");
        }
        else
        {
 
 if(var1.isIndexAVariableName != ""){
			
       
			
            calculate_array_indexRegister(var1);
            calculate_index_i(1);
			mr8_store("B");
            calculate_index_i(1);
            mr8_load("A");
			mr8_load("B");
		 
		 
		}else{
	 
	 
            calculate_array_index(var1);
            calculate_index_i(1);
			mr8_store("B");
            calculate_index_i(1);
            mr8_load("A");
			mr8_load("B");
			}
        }
    }
}


void load_register_to_accumulator(Variable var1)
{

 
    if (var1.value < 0) {
        string errorHandler = "niezainicjalizowana zmienna " + var1.name;
        yyerror(errorHandler.c_str());
    }

    if (same_memory_cell(accumulator[0], var1))
    {
	
	
	 
	if(done)	{
		done = false;
	}else	{ 
		return;
	}
       
    }

    accumulator[0] = var1;

    if (var1.name == "@")
    {
        calculate_num_to_acc(var1.value);
    }
    else if(!var1.isArray)
    {
	mr8_copy("B", var1.rejestr);
 
    }
 
}

 
bool is_power_of_two(long long num)
{
    stringstream sstring1;
    fprintbinary(sstring1, num);
    string bin_ = sstring1.str();
    return (std::count(bin_.begin(), bin_.end(), '1') == 1);
}

void multiply(Variable *var1, Variable *var2)
{
 
	long long ida = 2;  
 
	
	 
	calculate_index_i(ida);
	mr8_store("D");
 
	
	
	 


	 if(var1->isRegister && var2->isRegister){ 		
		load_register_to_accumulator(*var1);
		mr8_copy("C","B");  
		load_register_to_accumulator(*var2);
		mr8_copy("D","B");  	 
 
	 }else if((!var1->isRegister) && (!var2->isRegister)){ 
		load_variable_to_accumulator(*var1);
		mr8_copy("C","B");  
		load_variable_to_accumulator(*var2);
		mr8_copy("D","B");  
	 }else if(var1->isRegister){
	    load_register_to_accumulator(*var1);
		mr8_copy("C","B");  
		load_variable_to_accumulator(*var2);
		mr8_copy("D","B");  
	 }else if(var2->isRegister){	 
		load_variable_to_accumulator(*var1);
		mr8_copy("C","B");  			
		load_register_to_accumulator(*var2);
		mr8_copy("D","B");  
	 }
	 
	
	
	mr8_sub("B", "C");
	mr8_jzero("B", ip()+16); // if x > y (0 > y - x)
	mr8_sub("A", "A"); // ret = 0
	mr8_copy("B", "C");   // while x > 0
	mr8_jzero("B", ip()+29);  
	mr8_inc("B"); // if a & 1
    mr8_jodd("B", ip()+4);
    mr8_copy("B", "A"); 
    mr8_add("B", "D");
    mr8_copy("A", "B"); // ret += y // endif
    mr8_copy("B", "D"); 
    mr8_add("B", "B");
	mr8_copy("D", "B"); 
	mr8_copy("B", "C");   
    mr8_half("B");
    mr8_copy("C", "B"); // x <<= 1
    mr8_jump(ip()-12); // endwhile
    mr8_sub("B", "B"); // else (x <= y)
    mr8_copy("A", "B"); // ret = 0
    mr8_copy("B", "D"); // while y > 0
    mr8_jzero("B", ip()+13);
	mr8_inc("B");
    mr8_jodd("B", ip()+4); // if y & 1
    mr8_copy("B", "A");
    mr8_add("B", "C");
    mr8_copy("A", "B");
	
    mr8_copy("B", "C"); 
    mr8_add("B", "B");
    mr8_copy("C", "B"); 
	mr8_copy("B", "D");   
    mr8_half("B");
    mr8_copy("D", "B"); // y <<= 1
    mr8_jump(ip()-12);
    mr8_copy("B", "A"); // return 
 
    calculate_index_i(ida);
	mr8_load("D");
	 
	 
	
  

}

void divide(Variable *var1, Variable *var2)
{

 
	long long ida = 2;
 
 
	calculate_index_i(ida);
	mr8_store("D");
	mr8_inc("A");
	mr8_store("E");

	
	
		  if(var1->isRegister && var2->isRegister){ 		
		load_register_to_accumulator(*var1);
		mr8_copy("C","B");  
		load_register_to_accumulator(*var2);
		mr8_copy("D","B");  	 
 
	 }else if((!var1->isRegister) && (!var2->isRegister)){ 
		load_variable_to_accumulator(*var1);
		mr8_copy("C","B");  
		load_variable_to_accumulator(*var2);
		mr8_copy("D","B");  
	 }else if(var1->isRegister){
	    load_register_to_accumulator(*var1);
		mr8_copy("C","B");  
		load_variable_to_accumulator(*var2);
		mr8_copy("D","B");  
	 }else if(var2->isRegister){	 
		load_variable_to_accumulator(*var1);
		mr8_copy("C","B");  				
		load_register_to_accumulator(*var2);
		mr8_copy("D","B");  
	 }
	
 
    mr8_sub("B", "B");
    mr8_copy("E", "B");
	mr8_copy("B", "D");
    mr8_jzero("B", ip()+50); // Return 0 
    mr8_dec("B"); // if y == 1
    mr8_jzero("B", ip()+45); // Return x
    mr8_sub("B", "B");
    mr8_inc("B"); 
    mr8_copy("A", "B"); // a = 1
    mr8_copy("B", "D"); // while (y <= x) // (y - x = 0)
    mr8_sub("B", "C");	
    mr8_jzero("B", ip()+2);
    mr8_jump(ip()+8); // to endwhile
   	mr8_copy("B", "D");
    mr8_add("B", "B");
    mr8_copy("D", "B"); // y <<= 1
    mr8_copy("B", "A"); 
    mr8_add("B", "B");
    mr8_copy("A", "B"); // a <<= 1
    mr8_jump(ip()-10);   // endwhile 
    mr8_copy("B", "D"); 
    mr8_half("B"); 
    mr8_copy("D", "B"); // y >>= 1
    mr8_copy("B", "A"); 
    mr8_half("B");
    mr8_copy("A", "B");  // a >>= 1
    mr8_copy("B", "A"); // while (a > 0)
    mr8_jzero("B", ip()+21); // to endwhile
    mr8_copy("B", "E");
	mr8_add("B", "B"); 
    mr8_copy("E", "B");  // b <<= 1
    mr8_copy("B", "D");  // if y <= x // (y - x = 0)
	mr8_sub("B", "C");	 
	mr8_jzero("B", ip()+2); 
	mr8_jump(ip()+7); // to endif 
    mr8_copy("B", "C"); 
	mr8_sub("B", "D"); // x = x - y
	mr8_copy("C", "B");  
    mr8_copy("B", "E");   
    mr8_inc("B");
	mr8_copy("E", "B");   // b++ //endif
	mr8_copy("B", "D");  
	mr8_half("B");
    mr8_copy("D", "B");  // y >>= 1
    mr8_copy("B", "A"); 
    mr8_half("B");
    mr8_copy("A", "B"); // a >>= 1
    mr8_jump(ip()-21); // endwhile
    mr8_copy("B", "E");  // Return b
	mr8_jump(ip()+4);
    mr8_copy("B", "C");  // Return x
    mr8_jump(ip()+2);
    mr8_sub("B", "B"); // Return 0 

  
    calculate_index_i(ida);
	mr8_load("D");
	mr8_inc("A");
	mr8_load("E");
 
  
}

void modulo(Variable *var1, Variable *var2)
{
 
    long long ida = 2;
 
	
	calculate_index_i(ida);
	mr8_store("D");
	mr8_inc("A");
	mr8_store("E");
	
	  if(var1->isRegister && var2->isRegister){ 		
		load_register_to_accumulator(*var1);
		mr8_copy("C","B");  
		load_register_to_accumulator(*var2);
		mr8_copy("D","B");  	 
		}
	 else if((!var1->isRegister) && (!var2->isRegister)){ 
		load_variable_to_accumulator(*var1);
		mr8_copy("C","B");  
		load_variable_to_accumulator(*var2);
		mr8_copy("D","B");  
	 }else if(var1->isRegister){
	    load_register_to_accumulator(*var1);
		mr8_copy("C","B");  
		load_variable_to_accumulator(*var2);
		mr8_copy("D","B");  
	 }else if(var2->isRegister){	 
		load_variable_to_accumulator(*var1);
		mr8_copy("C","B");  				
		load_register_to_accumulator(*var2);
		mr8_copy("D","B");  
	 }
	
    mr8_sub("B", "B");
    mr8_copy("E", "B"); // b = 0
    mr8_copy("B", "D");   // if y == 0
    mr8_jzero("B", ip()+47); // Return 0
    mr8_dec("B"); // if b == 1
    mr8_jzero("B", ip()+45); // Return 0    
    mr8_sub("B", "B");
	mr8_inc("B");
    mr8_copy("A", "B");  // a = 1
    mr8_copy("B", "D"); // while (y <= x) // (y - x = 0)
    mr8_sub("B", "C");	
	mr8_jzero("B", ip()+2);
	mr8_jump(ip()+8); // to endwhile
    mr8_copy("B", "D"); 
    mr8_add("B", "B"); 
    mr8_copy("D", "B"); // y <<= 1
	mr8_copy("B", "A"); 
    mr8_add("B", "B");
    mr8_copy("A", "B"); // a <<= 1 
 	mr8_jump(ip()-10); // endwhile 
    mr8_copy("B", "D"); // y >>= 1
    mr8_half("B");
	mr8_copy("D", "B");  
    mr8_copy("B", "A");  // a >>= 1
    mr8_half("B");
    mr8_copy("A", "B"); 
	mr8_copy("B", "A");  // while (a > 0)
	mr8_jzero("B", ip()+21); // to endwhile 
    mr8_copy("B", "E");  
    mr8_add("B", "B"); 
    mr8_copy("E", "B"); // b <<= 1  
    mr8_copy("B", "D"); // if y <= x // (y - x = 0)
    mr8_sub("B", "C");	
    mr8_jzero("B", ip()+2);
    mr8_jump(ip()+7); // to endif
    mr8_copy("B", "C"); 
    mr8_sub("B", "D");
    mr8_copy("C", "B"); // x = x - y
	mr8_copy("B", "E");  
    mr8_inc("B");
    mr8_copy("E", "B"); // b++ //endif
    mr8_copy("B", "D");
    mr8_half("B"); 
    mr8_copy("D", "B"); // y >>= 1
    mr8_copy("B", "A");
	mr8_half("B"); 
    mr8_copy("A", "B"); // a >>= 1
    mr8_jump(ip()-20); // endwhile
    mr8_copy("B", "C");  
    mr8_jump(ip()+2);
    mr8_sub("B", "B"); // Return 0
 
    calculate_index_i(ida);
	mr8_load("D");
	mr8_inc("A");
	mr8_load("E");  
    
	
 
}

void sub_from_acc(Variable *var2)
{
    if (var2->isArray && var2->isIndexAVariable)
    {
	
	if(var2->isIndexAVariableName != ""){
 
		calculate_index_i(2);
		mr8_store("B");
        calculate_array_indexRegister(*var2);
		calculate_index_i(3);
		mr8_store("B");
		calculate_index_i(2);
		mr8_load("B");
 
		calculate_index_i(3);
		mr8_load("A");
		mr8_load("A");
		mr8_sub("B", "A");
	 
		 
		}else{
		
	
	    calculate_index_i(2);
		mr8_store("B");
        calculate_array_index(*var2);
		calculate_index_i(3);
		mr8_store("B");
		calculate_index_i(2);
		mr8_load("B");
 
		calculate_index_i(3);
		mr8_load("A");
		mr8_load("A");
		mr8_sub("B", "A");
		}

   
    }
    else if (var2->name == "@")
    {
        if (var2->value == 0)
        {
            return;
        }
        else if (var2->value <= 40)
        {
            for (int i = 0; i < var2->value; ++i)
            {
                if (ip() > 0 && commands[ip()-1] == "INC")
                {
                    commands.pop_back();
                    continue;
                }
                mr8_dec("B");
            }
        }
        else
        {
         
            calculate_index_i(var2->value); // >=1
			mr8_sub("B", "A"); // 10
			
			
        }
    }
    else
    {
 
		  calculate_index_i(get_real_index(*var2));
		  mr8_load("A");
          mr8_sub("B", "A"); // 10
    }
    accumulator[0] = empty;
}



void sub_from_accRegister(Variable *var2)
{

          mr8_sub("B", var2->rejestr); // 10
    
    accumulator[0] = empty;
}



void add_from_acc(Variable *var2)
{
    if (var2->isArray && var2->isIndexAVariable)
    {
	
	if(var2->isIndexAVariableName != ""){
 
		calculate_index_i(2);
		mr8_store("B");
        calculate_array_indexRegister(*var2);
		calculate_index_i(3);
		mr8_store("B");
		calculate_index_i(2);
		mr8_load("B");
 
		calculate_index_i(3);
		mr8_load("A");
		mr8_load("A");
		mr8_add("B", "A");
	 
		 
		}else{
		
	
	    calculate_index_i(2);
		mr8_store("B");
        calculate_array_index(*var2);
		calculate_index_i(3);
		mr8_store("B");
		calculate_index_i(2);
		mr8_load("B");
 
		calculate_index_i(3);
		mr8_load("A");
		mr8_load("A");
		mr8_add("B", "A");
		}

   
    }
    else if (var2->name == "@")
    {
        if (var2->value == 0)
        {
            return;
        }
        
        else
        {
         
            calculate_index_i(var2->value); // >=1
			mr8_add("B", "A"); // 10
			
			
        }
    }
    else
    {
 
		  calculate_index_i(get_real_index(*var2));
		  mr8_load("A");
          mr8_add("B", "A"); // 10
    }
    accumulator[0] = empty;
}



void add_from_accRegister(Variable *var2)
{

          mr8_add("B", var2->rejestr); // 10
    
    accumulator[0] = empty;
}

void update_jump(size_t k, size_t j)
{
string adderr = "JZERO ";
    if ( commands[k] == "JUMP -1" ) {
        commands[k] = "JUMP " + std::to_string(j);
    } else {
	   
        commands[k] = adderr.append("B ").append(std::to_string(j));
    }
}

%}
%union {
    Variable *variable;
    long long number;
    std::string *string;
    int token;
}

%locations
%token <token> VAR KW_BEGIN END
%token <string> PIDENTIFIER
%token <number> NUM
%token <token> SEMICOLON
%token <token> COLON
%token <token> READ WRITE
%token <token> IF THEN ELSE ENDIF
%token <token> WHILE DO ENDWHILE ENDDO
%token <token> FOR FROM TO DOWNTO ENDFOR
%token <token> ASSIGN
%token <token> L_BR R_BR
%token <token> OPERATION_PLUS OPERATION_MINUS OPERATION_MULT OPERATION_DIV OPERATION_MOD
%token <token> OPERATION_EQ OPERATION_NEQ OPERATION_LT OPERATION_LE OPERATION_GT OPERATION_GE
%precedence NEGATION

%type <variable> identifier
%type <variable> value
%type <string> error
%%

program:
      VAR declarations KW_BEGIN commands END {
          mr8_halt();
          print_all_commands();
      }
    ;

declarations:
      declarations PIDENTIFIER SEMICOLON {
        string *localName = $2;
        Variable *result = put_new_variable(*localName, 0, 0, 0);
        if (result == nullptr) {
            string errorHandler = "zmienna " + *localName + " już została zadeklarowana";
            yyerror(errorHandler.c_str());
        }
        delete localName;
      }
    | declarations PIDENTIFIER L_BR NUM COLON NUM R_BR SEMICOLON {
        string *localName = $2;
		long long arrayFirst = $4;
        long long arrayLength = $6;
		long long realArrayLength = arrayLength - arrayFirst + 1;
		
		
				if (arrayFirst > arrayLength) {
            string errorHandler = "zły przedział tablicy " + *localName + " początek przedziału: ";
            errorHandler += cln_to_string(arrayFirst);
			errorHandler += " jest większy od końca  : " ;
			errorHandler += cln_to_string(arrayLength);
            yyerror(errorHandler.c_str());
        }
		
        if (realArrayLength < 1) {
            string errorHandler = "zła długość tablicy " + *localName + ": ";
            errorHandler += cln_to_string(realArrayLength);
            yyerror(errorHandler.c_str());
        }
		
 
		
        Variable *result = put_new_variable(*localName, realArrayLength, arrayFirst, arrayLength);
        if (result == nullptr) {
            string errorHandler = "zmienna " + *localName + " już została zadeklarowana";
            yyerror(errorHandler.c_str());
        }

         
			calculate_num_to_acc(result->index);
			mr8_inc("B");
			calculate_index_i(result->index);
            mr8_store("B");
 
		varCounter += arrayFirst + 1;

        delete localName;
    }
    | %empty
    | declarations PIDENTIFIER NUM {
        string *localName = $2;
        long long num = $3;
        string errorHandler = "nierozpoznany napis " + *localName + cln_to_string(num);
        yyerror(errorHandler.c_str());
        delete localName;
       
    }
    ;

commands:
      commands command
    | command
    ;

command:
      identifier ASSIGN expression SEMICOLON {
        Variable *asig = $1;
        
		 if(asig->isRegister == true){
		    store_accumulator_in_register(*asig);
		   
		 }else{
		    store_accumulator_in_variable(*asig);
	 	}
       

        if (asig->isArray) {
            delete asig;
        }
      }
    | IF condition THEN commands {
        cond_start_ip.pop();
        size_t end = cond_endOf_ip.top();
        cond_endOf_ip.pop();

        else_start_ips.push(ip());
        mr8_jump(-1);
        
        update_jump(end, ip());
        accumulator[0] = empty;
    } ELSE commands {
        size_t begin = else_start_ips.top();
        else_start_ips.pop();
        update_jump(begin, ip());
        accumulator[0] = empty;
    } ENDIF
    | IF condition THEN commands {
        cond_start_ip.pop();
        size_t end = cond_endOf_ip.top();
        cond_endOf_ip.pop();
        update_jump(end, ip());
        accumulator[0] = empty;
    } ENDIF
    | WHILE condition DO commands {
        size_t begin = cond_start_ip.top();
        cond_start_ip.pop();
        size_t end = cond_endOf_ip.top();
        cond_endOf_ip.pop();
        mr8_jump(begin);
        update_jump(end, ip());
        accumulator[0] = empty;
    } ENDWHILE
	| DO {
	     
	     com_start_ip.push(ip());
		 done = true;
     
	
	} commands WHILE condition {

        size_t begin = cond_start_ip.top();
        cond_start_ip.pop();
        size_t end = cond_endOf_ip.top();
        cond_endOf_ip.pop();
		
		size_t beginCommans = com_start_ip.top();
        com_start_ip.pop();
		 
        mr8_jump(beginCommans);
        update_jump(end, ip() );
        accumulator[0] = empty;
		done = false;
    } ENDDO
    | FOR PIDENTIFIER FROM value TO value {
        string *localname = $2;
        *localname = *localname;
        Variable *iteration = put_new_temp_variable(*localname);
        if (iteration == nullptr) {
            string errorHandler = "zmienna " + *localname + " już została zadeklarowana";
            yyerror(errorHandler.c_str());
        }
        iteration->isTemporary = true;
        iteration->value = 1;
        Variable *iterationConddition = put_new_temp_variable(*localname + "'");
        iterationConddition->isTemporary = true;
        iterationConddition->value = 1;
        Variable *min = $4;
        Variable *max = $6;


		if(min->isRegister){
		
		 load_register_to_accumulator(*min);
		}else{
		 load_variable_to_accumulator(*min);
		}

		if(iteration->isRegister){
			mr8_copy(iteration->rejestr, "B");
		} else {
			calculate_index_i(iteration->index);
			mr8_store("B");
		}

        if(max->isRegister){
			load_register_to_accumulator(*max);
		 } else {
			load_variable_to_accumulator(*max);
		}
 
         
			 mr8_inc("B");
		
		if(min->isRegister){
			sub_from_accRegister(min);
		} else {
			sub_from_acc(min);
		}
		
         if(iterationConddition->isRegister){
			mr8_copy(iterationConddition->rejestr, "B");
		} else {
	    	calculate_index_i(iterationConddition->index);
			mr8_store("B");
		}
		
        cond_start_ip.push(ip());
        cond_endOf_ip.push(ip());
        mr8_jzero("B" , -1);

        accumulator[0] = empty;
        accumulator[0].value = 1;
        if (min->name == "@" || min->isArray) {
            delete min;
        }
        if (max->name == "@" || max->isArray) {
            delete max;
        }
    } DO commands ENDFOR {
        string *localname = $2;
        Variable *iteration = get_variable(*localname);
        Variable *iterationConddition = get_variable(*localname + "'");
        size_t condIp = cond_start_ip.top();
        cond_start_ip.pop();
        cond_endOf_ip.pop();
		
		if(iteration->isRegister){
			mr8_copy("B", iteration->rejestr);
		} else {
	    calculate_index_i(iteration->index);
        mr8_load("B");
		}
		
		 
        mr8_inc("B");
		
		if(iteration->isRegister){
			mr8_copy(iteration->rejestr, "B");
		} else {
			calculate_index_i(iteration->index);
			mr8_store("B");
		}
		 if(iterationConddition->isRegister){
			mr8_copy("B", iterationConddition->rejestr);
		} else {
			calculate_index_i(iterationConddition->index);
			mr8_load("B");
		}		
		 
		 
			mr8_dec("B");
		
		if(iterationConddition->isRegister){
			mr8_copy(iterationConddition->rejestr, "B");
		} else {
			calculate_index_i(iterationConddition->index);
			mr8_store("B");
		}

		 
        mr8_jump(condIp);
        update_jump(condIp, ip());

        delete_temp_variable(iterationConddition->name);
        delete_temp_variable(iteration->name);

        accumulator[0] = empty;
        accumulator[0].value = 1;

        delete localname;
    }
    | FOR PIDENTIFIER FROM value DOWNTO value {
        string *localname = $2;
        *localname = *localname;
        Variable *iteration = put_new_temp_variable(*localname);
        if (iteration == nullptr) {
            string errorHandler = "zmienna " + *localname + " już została zadeklarowana";
            yyerror(errorHandler.c_str());
        }
        iteration->isTemporary = true;
        iteration->value = 1;
        Variable *iterationConddition = put_new_temp_variable(*localname + "'");
        iterationConddition->isTemporary = true;
        iterationConddition->value = 1;
        Variable *min = $6;
        Variable *max = $4;

		if(max->isRegister){
		
		 load_register_to_accumulator(*max);
		} else {
		 load_variable_to_accumulator(*max);
		}

        if(iteration->isRegister){
			mr8_copy(iteration->rejestr, "B");
		} else {
			calculate_index_i(iteration->index);
			mr8_store("B");
		}

			mr8_inc("B");
		
		if(min->isRegister){
			sub_from_accRegister(min);
		} else {
			sub_from_acc(min);
		}
		
		if(iterationConddition->isRegister){
			mr8_copy(iterationConddition->rejestr, "B");
		} else {
	    	calculate_index_i(iterationConddition->index);
			mr8_store("B");
		}
        
        cond_start_ip.push(ip());
        cond_endOf_ip.push(ip());
        mr8_jzero("B", -1);

        accumulator[0] = empty;
        accumulator[0].value = 1;
        if (min->name == "@" || min->isArray) {
            delete min;
        }
        if (max->name == "@" || max->isArray) {
            delete max;
        }
    } DO commands ENDFOR {
        string *localname = $2;
        Variable *iteration = get_variable(*localname);
        Variable *iterationConddition = get_variable(*localname + "'");
        size_t condIp = cond_start_ip.top();
        cond_start_ip.pop();
        cond_endOf_ip.pop();
		
		
		if(iteration->isRegister){
			mr8_copy("B", iteration->rejestr);
		} else {
			calculate_index_i(iteration->index);
			mr8_load("B");
		}

 
			mr8_dec("B");
		
		if(iteration->isRegister){
			mr8_copy(iteration->rejestr, "B");
		} else {
			calculate_index_i(iteration->index);
			mr8_store("B");
		}
		 if(iterationConddition->isRegister){
			mr8_copy("B", iterationConddition->rejestr);
		} else {
			calculate_index_i(iterationConddition->index);
			mr8_load("B");
		}
		
		
 
			mr8_dec("B");
		
		if(iterationConddition->isRegister){
			mr8_copy(iterationConddition->rejestr, "B");
		} else {
			calculate_index_i(iterationConddition->index);
			mr8_store("B");
		}

 
        mr8_jump(condIp);
        update_jump(condIp, ip());

        delete_temp_variable(iterationConddition->name);
        delete_temp_variable(iteration->name);

        accumulator[0] = empty;
        accumulator[0].value = 1;

        delete localname;
    }
    | READ identifier SEMICOLON {
        Variable *var1 = $2;
        mr8_get("B");

        if(var1->isRegister == true){
		store_accumulator_in_register(*var1);
		}else{
		   store_accumulator_in_variable(*var1);
		}
		
      

        if (var1->isArray) {
            delete var1;
        }
    }
    | WRITE value SEMICOLON {
        Variable *var1 = $2;
 
		if(var1->isRegister == true){
 
		  load_register_to_accumulator(*var1);
		}else{
		 
		  load_variable_to_accumulator(*var1);}
   
        mr8_put("B");
        if (var1->name == "@" || var1->isArray) {
            delete var1;
        }
    }
    ;

expression:
      value {  
        Variable *var1 = $1;
	   
	    if(var1->isRegister ==true){
	       load_register_to_accumulator(*var1);
	   }else{
	      load_variable_to_accumulator(*var1);
	    }
         
		 
        if (var1->name == "@" || var1->isArray) {
            delete var1;
        }
    }
    | value OPERATION_PLUS value {
        Variable *var1 = $1;
        Variable *var2 = $3;
 
        if (var1->name == "@" && var2->name == "@")
        {
           
            calculate_num_to_acc(var1->value + var2->value);
        }
		else if (var1->rejestr != "" && var2->rejestr != "")
        {
            
			mr8_sub("B", "B");
            mr8_add("B", var1->rejestr);
			mr8_add("B", var2->rejestr);
        }
        else if (same_memory_cell(*var1, *var2))
        {
             
			  
			if(var1->isRegister == true){
			load_register_to_accumulator(*var1);
			}else{			
			load_variable_to_accumulator(*var1);
			}
             
            mr8_add("B", "B");
        }
        else
        {
            
			
			 if(var1->isRegister == true){
			 
			 load_register_to_accumulator(*var1);
			 }else{
			  load_variable_to_accumulator(*var1);
			 }

			if(var2->isRegister == true){
			 
				add_from_accRegister(var2);
			 }else{
			    add_from_acc(var2);
			 }
            
           
        }
        accumulator[0] = empty;
        accumulator[0].value = 1;
        if (var1->name == "@" || var1->isArray) {
            delete var1;
        }
        if (var2->name == "@" || var2->isArray) {
            delete var2;
        }
    }
    | value OPERATION_MINUS value {
        Variable *var1 = $1;
        Variable *var2 = $3;
        if (var1->name == "@" && var2->name == "@")
        {
           
            long long returnValue = var1->value - var2->value;
            if (returnValue < 0) {
                returnValue = 0;
            }
            calculate_num_to_acc(returnValue);
        }
		else if (var1->rejestr != "" && var2->rejestr != "")
        {
            
			mr8_sub("B", "B");
            mr8_add("B", var1->rejestr);
			mr8_sub("B", var2->rejestr);
        }
        else if (same_memory_cell(*var1, *var2))
        {
           
            mr8_sub("B", "B");
        }
        else
        {
            
			
			 if(var1->isRegister == true){
			 
			 load_register_to_accumulator(*var1);
			 }else{
			  load_variable_to_accumulator(*var1);
			 }

			if(var2->isRegister == true){
			 
				sub_from_accRegister(var2);
			 }else{
			    sub_from_acc(var2);
			 }
            
           
        }
        accumulator[0] = empty;
        accumulator[0].value = 1;
        if (var1->name == "@" || var1->isArray) {
            delete var1;
        }
        if (var2->name == "@" || var2->isArray) {
            delete var2;
        }
    }
    | value OPERATION_MULT value {
        Variable *var1 = $1;
        Variable *var2 = $3;

        if (var1->name == "@" && var2->name == "@")
        {
            
            long long returnValue = var1->value * var2->value;
            calculate_num_to_acc(returnValue);
        }
        else
        {
             
            if (var2->name == "@")
            {
                std::swap(var1, var2);
            }

            if (var1->name == "@")
            {
                if (var1->value == 0)
                {
                    mr8_sub("B", "B");
                }
                else if (var1->value == 1)
                {
				
				    if(var2->isRegister == true){
					load_register_to_accumulator(*var2);
					}else{					
					load_variable_to_accumulator(*var2);
					}
                     
                }
                else if (is_power_of_two(var1->value))
                {
				if(var2->isRegister == true){
					load_register_to_accumulator(*var2);
					}else{
                    load_variable_to_accumulator(*var2);
					}
                    while (var1->value > 1)
                    {
                        mr8_add("B", "B");
                        var1->value >>= 1;
                    }
                }
                else
                {
                    multiply(var1, var2);
                }
            }
            else
            {
                multiply(var1, var2);
            }

            accumulator[0] = empty;
            accumulator[0].value = 1;
            if (var1->name == "@" || var1->isArray) {
                delete var1;
            }
            if (var2->name == "@" || var2->isArray) {
                delete var2;
            }
        }
    }
    | value OPERATION_DIV value {
        Variable *var1 = $1;
        Variable *var2 = $3;

        if (var1->name == "@" && var2->name == "@")
        {
          
            long long returnValue = 0;
            if (var2->value != 0)
            {
                returnValue =  floor(var1->value / var2->value);
            }
            calculate_num_to_acc(returnValue);
        }
        else
        {
             
            if (var2->name == "@")
            {
                if (var2->value == 0)
                {
                    mr8_sub("B", "B");
                }
                else if (var2->value == 1)
                {
				
				if(var1->isRegister == true){
					load_register_to_accumulator(*var1);
					}else{
                    load_variable_to_accumulator(*var1);
					}
                }
                else if (is_power_of_two(var2->value))
                {
                    if(var1->isRegister == true){
					load_register_to_accumulator(*var1);
					}else{
                    load_variable_to_accumulator(*var1);
					}
                    while (var2->value > 1)
                    {
                        mr8_half("B");
                        var2->value >>= 1;
                    }
                }
                else
                {
                    divide(var1, var2);
                }
            }
            
            else if (var1->name == "@")
            {
                if (var1->value == 0)
                {
                    mr8_sub("B", "B");
                }
                else
                {
                    divide(var1, var2);
                }
            }
            else
            {
                divide(var1, var2);
            }
        }

        accumulator[0] = empty;
        accumulator[0].value = 1;
        if (var1->name == "@" || var1->isArray) {
            delete var1;
        }
        if (var2->name == "@" || var2->isArray) {
            delete var2;
        }
    }
    | value OPERATION_MOD value {
        Variable *var1 = $1;
        Variable *var2 = $3;

        if (var1->name == "@" && var2->name == "@")
        {
            
            long long returnValue = 0;
            if (var2->value != 0)
            {
                returnValue =  var1->value % var2->value ;
            }
            calculate_num_to_acc(returnValue);
        }
        else
        {
           
            if (var2->name == "@")
            {
                if (var2->value == 0)
                {
                    mr8_sub("B", "B");
                }
                else if (var2->value == 1)
                {
                    mr8_sub("B", "B");
                }
                else
                {
                    modulo(var1, var2);
                }
            }
             
            else if (var1->name == "@")
            {
                if (var1->value == 0)
                {
                    mr8_sub("B", "B");
                }
                else
                {
                    modulo(var1, var2);
                }
            }
            else
            {
                modulo(var1, var2);
            }
        }

        accumulator[0] = empty;
        accumulator[0].value = 1;
        if (var1->name == "@" || var1->isArray) {
            delete var1;
        }
        if (var2->name == "@" || var2->isArray) {
            delete var2;
        }
    }
    ;

condition:
      value OPERATION_EQ value {
        Variable *var1 = $1;
        Variable *var2 = $3;

        accumulator[0] = empty;

	   
        cond_start_ip.push(ip());
        // x = y <=> (x - y) + (y - x) = 0
		
		if(var1->isRegister){
		load_register_to_accumulator(*var1);
		}else{
		load_variable_to_accumulator(*var1);
		}
		
		if(var2->isRegister){
		sub_from_accRegister(var2);
		}else{
		sub_from_acc(var2);
		}
		
	     mr8_copy("C", "B"); 
		 
		 if(var2->isRegister){
		load_register_to_accumulator(*var2);
		}else{
		load_variable_to_accumulator(*var2);
		}
		
		if(var1->isRegister){
		sub_from_accRegister(var1);
		}else{
		sub_from_acc(var1);
		}
         mr8_add("B", "C");
		
        mr8_jzero("B", ip()+2);
        cond_endOf_ip.push(ip());
        mr8_jump(-1);

        if (var1->name == "@" || var1->isArray) {
            delete var1;
        }
        if (var2->name == "@" || var2->isArray) {
            delete var2;
        }
    }
    | value OPERATION_NEQ value {
        Variable *var1 = $1;
        Variable *var2 = $3;

        // x != y
        accumulator[0] = empty;

        cond_start_ip.push(ip());
		
		if(var1->isRegister){
		load_register_to_accumulator(*var1);
		}else{
		load_variable_to_accumulator(*var1);
		}
        if(var2->isRegister){
		sub_from_accRegister(var2);
		}else{
		sub_from_acc(var2);
		} 
		
        mr8_copy("C", "B"); 
		
		 if(var2->isRegister){
		load_register_to_accumulator(*var2);
		}else{
		load_variable_to_accumulator(*var2);
		}
		
		if(var1->isRegister){
		sub_from_accRegister(var1);
		}else{
		sub_from_acc(var1);
		}
         mr8_add("B", "C");
        cond_endOf_ip.push(ip());
        mr8_jzero("B", -1); 
        	 
        if (var1->name == "@" || var1->isArray) {
            delete var1;
        }
        if (var2->name == "@" || var2->isArray) {
            delete var2;
        }
    }
    | value OPERATION_LT value {
        Variable *var1 = $1;
        Variable *var2 = $3;

        // x < y <=> 0 < y - x
        accumulator[0] = empty;

		cond_start_ip.push(ip());
		 if(var2->isRegister){
		load_register_to_accumulator(*var2);
		}else{
		load_variable_to_accumulator(*var2);
		}
		
		if(var1->isRegister){
		sub_from_accRegister(var1);
		}else{
		sub_from_acc(var1);
		}
         
 
        cond_endOf_ip.push(ip());
        mr8_jzero("B", -1);

        if (var1->name == "@" || var1->isArray) {
            delete var1;
        }
        if (var2->name == "@" || var2->isArray) {
            delete var2;
        }
    }
    | value OPERATION_GT value {
        Variable *var1 = $1;
        Variable *var2 = $3;

        accumulator[0] = empty;

        // x > y <=> x - y > 0
        cond_start_ip.push(ip());
		
		
		if(var1->isRegister){
		load_register_to_accumulator(*var1);
		}else{
		load_variable_to_accumulator(*var1);
		}
        if(var2->isRegister){
		sub_from_accRegister(var2);
		}else{
		sub_from_acc(var2);
		} 
		
        cond_endOf_ip.push(ip());
        mr8_jzero("B", -1);

        if (var1->name == "@" || var1->isArray) {
            delete var1;
        }
        if (var2->name == "@" || var2->isArray) {
            delete var2;
        }
    }
    | value OPERATION_LE value {
        Variable *var1 = $1;
        Variable *var2 = $3;

        accumulator[0] = empty;

        // x <= y <=> x - y <= 0 <=> x - y = 0
        cond_start_ip.push(ip());
		
		if(var1->isRegister){
		load_register_to_accumulator(*var1);
		}else{
		load_variable_to_accumulator(*var1);
		}
        if(var2->isRegister){
		sub_from_accRegister(var2);
		}else{
		sub_from_acc(var2);
		} 
		
        mr8_jzero("B", ip()+2);
        cond_endOf_ip.push(ip());
        mr8_jump(-1);

        if (var1->name == "@" || var1->isArray) {
            delete var1;
        }
        if (var2->name == "@" || var2->isArray) {
            delete var2;
        }
    }
    | value OPERATION_GE value {
        Variable *var1 = $1;
        Variable *var2 = $3;

        accumulator[0] = empty;

        // x >= y <=> 0 >= y - x <=> 0 = y - x
        cond_start_ip.push(ip());
		
		if(var2->isRegister){
		load_register_to_accumulator(*var2);
		}else{
		load_variable_to_accumulator(*var2);
		}
        if(var1->isRegister){
		sub_from_accRegister(var1);
		}else{
		sub_from_acc(var1);
		} 
		
 
        mr8_jzero("B", ip()+2);
        cond_endOf_ip.push(ip());
        mr8_jump(-1);

        if (var1->name == "@" || var1->isArray) {
            delete var1;
        }
        if (var2->name == "@" || var2->isArray) {
            delete var2;
        }
    }
    ;

value:
      NUM {
          Variable *var1 = new Variable();
          var1->name = "@";
          var1->value = $1;
          $$ = var1;
      
      }
    | OPERATION_MINUS NUM %prec NEGATION { yyerror("niewłaściwy znak '-'"); }
    | identifier {
        Variable *var1 = $1;
		
     if(var1->value < 0) {
            string errorHandler = "niezainicjalizowana zmienna " + var1->name;
            yyerror(errorHandler.c_str());
        }
        $$ = var1;
    }
    ;

identifier:
      PIDENTIFIER {
          string *nameVar = $1;
          Variable *localVar = get_variable(*nameVar);
		  
 
          if (localVar == nullptr) {
              string errorHandler = "niezadeklarowana zmienna " + *nameVar;
              yyerror(errorHandler.c_str());
          }		  
		  
          if (localVar->isArray) {
            string errorHandler = "niewłaściwe użycie zmiennej tablicowej " + *nameVar;
            yyerror(errorHandler.c_str());
          }
          $$ = localVar;
          delete nameVar;
      }
    | PIDENTIFIER L_BR PIDENTIFIER R_BR {
        string *nameVar = $1;
        string *nameVar2 = $3;

        
        Variable *localVar = get_variable(*nameVar);
        if (localVar == nullptr) {
            string errorHandler = "niezadeklarowana zmienna " + *nameVar;
            yyerror(errorHandler.c_str());
        }
        if (!localVar->isArray) {
            string errorHandler = "niewłaściwe użycie zmiennej " + *nameVar;
            yyerror(errorHandler.c_str());
        }

		 
        
        Variable *localVar2 = get_variable(*nameVar2);
		
 
		
		if (localVar2 == nullptr) {
            string errorHandler = "niezadeklarowana zmienna " + *nameVar2;
            yyerror(errorHandler.c_str());
        }
		
		
        if (localVar2->value < 0) {
            string errorHandler = "niezainicjalizowana zmienna " + *nameVar2;
            yyerror(errorHandler.c_str());
        } 
       
 
        
		   if (localVar2->isArray) {
            string errorHandler = "niewłaściwe użycie zmiennej " + *nameVar2;
            yyerror(errorHandler.c_str());
        }
 

        
        Variable *return_var = new Variable(*localVar);
        return_var->arrayIndex = localVar2->index;
        return_var->isIndexAVariable = true;  
		
		if(localVar2->isRegister){
		 return_var->isIndexAVariableName = localVar2->rejestr;
 
		} else{
		  return_var->isIndexAVariableName = "";
		}
        
        $$ = return_var;
        
        delete nameVar;
        delete nameVar2;
    }
    | PIDENTIFIER L_BR NUM R_BR {
        string *nameVar = $1;
        long long localIndex1 = $3;

        
        Variable *localVar = get_variable(*nameVar);
        if (localVar == nullptr) {
            string errorHandler = "niezadeklarowana zmienna " + *nameVar;
            yyerror(errorHandler.c_str());
        }
        if (!localVar->isArray) {
            string errorHandler = "niewłaściwe użycie zmiennej " + *nameVar;
            yyerror(errorHandler.c_str());
        }
		
		 

        
        if (localIndex1 < localVar->indexFirst || localIndex1 > localVar->indexSecond) {
            string errorHandler = "zły indeks " + cln_to_string(localIndex1)  + " tablicy " + *nameVar;
            yyerror(errorHandler.c_str());
        }

       
        Variable *return_var = new Variable(*localVar);
        return_var->arrayIndex = localIndex1;
        return_var->isIndexAVariable = false;  

        $$ = return_var;
        
        delete nameVar;
      
    }
    ;
%%

int yyerror(const char *str)
{
    std::cerr << "Błąd w linii " << yylineno << ": " << str << std::endl;
    exit(1);
}

int main(  int argc, char const * argv[] )
{
 
  FILE * data;
  fstream dataOut;
  
  data = fopen( argv[1], "r" );
  if( !data )
  {
    std::cerr << "Błąd: Nie można otworzyć pliku " << argv[1] << std::endl;
    return -1;
  }
  dataOut.open(argv[2], ios::out);
  
   if( !dataOut )
  {
    std::cerr << "Błąd: Nie można zapisać w pliku " << argv[2] << std::endl;
    return -1;
  }
  
   myOut = &dataOut;
  
  yyin = data  ;
 
 
    empty.index = -2;
     yyparse(); 
	fclose( data );
	print_all_commandsToFile();
 	 dataOut.close();
	 return 0;
	 
	//  empty.index = -2;
	// return yyparse();
}
