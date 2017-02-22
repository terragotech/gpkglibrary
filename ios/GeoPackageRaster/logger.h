//#include "stdafx.h"
#ifndef _LOGGER_H_
#define _LOGGER_H_
#include <stdio.h>
#include <time.h>
#include <string.h>
#include <string>
using namespace std;
#define GEOPACKAGE_LOG_ERROR_FILE_OPEN_FAILED			-4001
#define GEOPACKAGE_LOG_ERROR_BAD_INPUT_PARAMETER		-4002
#define GEOPACKAGE_LOG_ERROR_BAD_TIME_STRING			-4003
#define GEOPACKAGE_LOG_ERROR_FILE_IO					-4004
#define GEOPACKAGE_LOG_ERROR_NO_FILE_EXT				-4005
#define GEOPACKAGE_LOG_ERROR_INSUFFICIENT_BUFFER_SIZE	-4006
#define GEOPACKAGE_LOG_ERROR_BAD_FILE_NAME				-4007

#define GEOPACKAGE_LOG_SUCCESS					0

int write_log(char *filename, char *message);
int write_progress(char *filename, char *message);
int remove_extension(char *filename_noext,char *filename,int buffer_size);
int check_term(char *filename);
#endif
