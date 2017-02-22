#include "logger2.h"

/*
* Function to write log 
*/
int check_term(char *filename)
{
	FILE *fp_term = fopen(filename,"r");
	if(fp_term !=  NULL)
	{
		fclose(fp_term);
		remove(filename);
		return 1;
	}
	return 0;
}
//Write Progress
int write_progress(char *filename, char *message)
{
	FILE *fp_log = fopen(filename,"w");
	if(NULL != fp_log)
	{
		fprintf(fp_log,"PROGRESS:%s",message);
		fclose(fp_log);
	}
	return 0;
}




