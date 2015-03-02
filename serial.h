/*  Serial port object for use with wxWidgets
 *  Copyright 2010, Paul Stoffregen (paul@pjrc.com)
 *  Modified by: Leonardo Laguna Ruiz (modlfo@gmail.co)
 *
 *  This program is free software: you can redistribute it and/or modify
 *  it under the terms of the GNU General Public License as published by
 *  the Free Software Foundation, either version 3 of the License, or
 *  (at your option) any later version.
 *
 *  This program is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU General Public License for more details.
 *
 *  You should have received a copy of the GNU General Public License
 *  along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */
#ifndef __serial_h__
#define __serial_h__


#include <stdint.h>

#if defined(LINUX)
#include <termios.h>
#elif defined(MACOSX)
#include <termios.h>
#elif defined(WINDOWS)
#include <windows.h>
#endif

#include <vector>
#include <string>
#include <sstream>
#include <algorithm> 

using namespace std;

class Serial
{
public:
	Serial();
	~Serial();
	vector<string> port_list();
	int Open(const string& name);
	string error_message();
	int Set_baud(int baud);
	int Set_baud(const string& baud_str);
	int Read(void *ptr, int count);
	int Write(const void *ptr, int len);
	int Input_wait(int msec);
	void Input_discard(void);
	int Set_control(int dtr, int rts);
	void Output_flush();
	void Close(void);
	int Is_open(void);
	string get_name(void);
private:
	int port_is_open;
	string port_name;
	int baud_rate;
	string error_msg;
private:
#if defined(LINUX) || defined(MACOSX)
	int port_fd;
	struct termios settings_orig;
	struct termios settings;
#elif defined(WINDOWS)
	HANDLE port_handle;
	COMMCONFIG port_cfg_orig;
	COMMCONFIG port_cfg;
#endif
};

#endif // __serial_h__
