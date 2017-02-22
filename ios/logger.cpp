//#include "stdafx.h"
#include "logger.h"
/*
* Function to write log 
*/
//int check_term(char *filename)
//{
//	FILE *fp_term = fopen(filename,"r");
//	if(fp_term !=  NULL)
//	{
//		fclose(fp_term);
//		remove(filename);
//		return 1;
//	}
//	return 0;
//}
////Write Progress
//int write_progress(char *filename, char *message)
//{
//	FILE *fp_log = fopen(filename,"w");
//	if(NULL != fp_log)
//	{
//		fprintf(fp_log,"PROGRESS:%s",message);
//		fclose(fp_log);
//	}
//	return 0;
//}
///Writes a log message to the specified file name
int write_log(char *filename, char *message)
{
	string time_string;
	string time_string_tmp;

	int result = GEOPACKAGE_LOG_SUCCESS;

	//Check input parameters
	if((NULL == filename) || (NULL == message))
	{
		printf("ERROR:Bad input parameters\n");		
		return GEOPACKAGE_LOG_ERROR_BAD_INPUT_PARAMETER;
	}

	//Open the file in append mode
	FILE *fp_log = fopen(filename,"a");
	if(NULL == fp_log)
	{
		printf("ERROR:Opening the file failed\n");		
		return GEOPACKAGE_LOG_ERROR_FILE_OPEN_FAILED;
	}

	time_t tresult = time(NULL);
	time_string_tmp.append(asctime(localtime(&tresult)));

	if(time_string_tmp.length() <= 1)
	{
		fclose(fp_log);
		return GEOPACKAGE_LOG_ERROR_BAD_TIME_STRING;
	}
	
	// Remove the carriage return from the time string using substr 

	time_string = time_string_tmp.substr(0,time_string_tmp.length()-1);
	result = fprintf(fp_log,"%s : %s\n",time_string.c_str(),message);
	if(result < 0)
	{
		printf("ERROR:Write log file failed\n");
		result = GEOPACKAGE_LOG_ERROR_FILE_IO;
	}
	else
	{
		result = GEOPACKAGE_LOG_SUCCESS;
	}
	fclose(fp_log);
	return result;
}//int write_log(char *filename, char *message)

/*
* Remove extenstion from filename
*/
///Function remove the extenstion from the file name
int remove_extension(char *filename_noext,char *filename,int buffer_size)
{
	int result = GEOPACKAGE_LOG_SUCCESS;
	if((NULL == filename) || (NULL == filename_noext))
	{
		printf("ERROR:Bad input parameters\n");		
		return GEOPACKAGE_LOG_ERROR_BAD_INPUT_PARAMETER;
	}
	string s_file_ext_tmp(filename);
	int didx = 0;
	int bExtenstionStarts = 0;
	for(int idx = s_file_ext_tmp.length()-1; idx >= 0; idx--)
	{
		if(s_file_ext_tmp[idx] == '.')
		{
			didx = idx;
			bExtenstionStarts = 1;
			break;
		}
	}
	if(0 == bExtenstionStarts)
	{
		printf("ERROR:Bad input file name has not extension\n");		
		return GEOPACKAGE_LOG_ERROR_NO_FILE_EXT;
	}
	string s_file_ext = s_file_ext_tmp.substr(0,didx);
	if(!(s_file_ext.length() < buffer_size))
	{
		printf("ERROR:Bad buffer size\n");		
		return GEOPACKAGE_LOG_ERROR_INSUFFICIENT_BUFFER_SIZE;
	}
	if(0 == s_file_ext.length())
	{
		printf("ERROR:Bad file name\n");
		return GEOPACKAGE_LOG_ERROR_BAD_FILE_NAME;
	}
	strncpy(filename_noext,s_file_ext.c_str(),buffer_size);
	return result;
}//int remove_extension(char *filename_noext,char *filename,int buffer_size)


