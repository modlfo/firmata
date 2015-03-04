/*  Ocaml serial port bindings
 *  Copyright 2015, Leonardo Laguna Ruiz (modlfo@gmail.com)
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

#include <stdio.h>
#include <caml/mlvalues.h>
#include <caml/memory.h>
#include <caml/alloc.h>
#include <caml/custom.h>

#include "serial.h"

extern "C" {

value newSerial(){
	CAMLparam0 ();
	CAMLlocal1(obj);
	Serial* port = new Serial();
	obj = Val_long((long)port);
	CAMLreturn(obj);
}

void deleteSerial(value obj){
	CAMLparam1(obj);
	Serial* serial_obj = (Serial*) Long_val(obj);
	delete serial_obj;
	CAMLreturn0;
}

value openSerial(value obj, value port){
	CAMLparam2(obj,port);
	CAMLlocal1(result);
	Serial* serial_obj = (Serial*) Long_val(obj);
	int ret = serial_obj->Open(String_val(port));
	// Compose the return value
	if(ret==0)
		result = Val_long(0);
	else {
		string msg = serial_obj->error_message();
		result = caml_alloc(1,0);
		Store_field(result,0,caml_copy_string(msg.c_str()));
	}
	CAMLreturn(result);
}

void closeSerial(value obj, value port){
	CAMLparam2(obj,port);
	CAMLlocal1(result);
	Serial* serial_obj = (Serial*) Long_val(obj);
	serial_obj->Close();
	CAMLreturn0;
}

value setBaudrate(value obj, value baudrate){
	CAMLparam2(obj,baudrate);
	CAMLlocal1(result);
	Serial* serial_obj = (Serial*) Long_val(obj);
	int ret = serial_obj->Set_baud(Long_val(baudrate));
	// Compose the return value
	if(ret==0)
		result = Val_long(1);
	else {
		result = Val_long(0);
	}
	CAMLreturn(result);
}

value portList(value obj){
	CAMLparam1(obj);
	CAMLlocal2(result,tmplist);
	Serial* serial_obj = (Serial*) Long_val(obj);
	std::vector<string> port_vector = serial_obj->port_list();

	result = Val_int(0); // nil

	// Create a list of strings
	for(std::vector<string>::iterator it = port_vector.begin(); it != port_vector.end(); ++it) {
    	tmplist = caml_alloc(2,1);
    	Store_field(tmplist,0,caml_copy_string((*it).c_str()));
    	Store_field(tmplist,1,result);
    	result = tmplist;
	}
	CAMLreturn(result);
}

value waitSerial(value obj,value msec){
	CAMLparam2(obj,msec);
	CAMLlocal1(result);
	Serial* serial_obj = (Serial*) Long_val(obj);
	int n = serial_obj->Input_wait(Long_val(msec));
	result = Val_int(n);
	CAMLreturn(result);
}

value isOpenSerial(value obj){
	CAMLparam1(obj);
	CAMLlocal1(result);
	Serial* serial_obj = (Serial*) Long_val(obj);
	int n = serial_obj->Is_open();
	result = Val_int(n);
	CAMLreturn(result);
}

void setControl(value obj,value dtr,value rts){
	CAMLparam3(obj,dtr,rts);
	Serial* serial_obj = (Serial*) Long_val(obj);
	serial_obj->Set_control(Long_val(dtr),Long_val(rts));
	CAMLreturn0;
}

value writeSerial(value obj, value list){
	CAMLparam2(obj,list);
	CAMLlocal2(result,tmplist);
	unsigned char buffer[1024*4];
	Serial* serial_obj = (Serial*) Long_val(obj);
	tmplist = list;
	int i=0;
	int total=0;
	while(Is_block(tmplist)){
		buffer[i]=(unsigned char)(Int_val(Field(tmplist,0)) & 0xFF);
		//printf(" %i\n", buffer[i]);
		tmplist = Field(tmplist,1);
		i++; total++;
		if(i>1024*4){
			serial_obj->Write(buffer,1024*4);
			i = 0;
		}
	}
	if(i>0)
		serial_obj->Write(buffer,i);
	result = Val_int(total);
	CAMLreturn(result);
}

value readSerial(value obj){
	CAMLparam1(obj);
	CAMLlocal2(result,tmplist);
	Serial* serial_obj = (Serial*) Long_val(obj);
	unsigned char buffer[1024*4];

	result = Val_int(0); // nil

	int nread = serial_obj->Read((void*)&buffer,1024*4);
	for(int j=1;j<=nread;j++){
		tmplist = caml_alloc(2,1);
		unsigned char c = buffer[nread-j];
    	Store_field(tmplist,0,Val_long(c));
    	Store_field(tmplist,1,result);
    	result = tmplist;
	}
	CAMLreturn(result);
}

}