#include "ruby.h"
#include <errno.h>
#include <stdio.h>
#include <unistd.h>
#include <sys/types.h>
#include <sys/time.h>
#include <sys/select.h>

fd_set socks;
void build_select_list(VALUE read_array) 
{
	int current;
	FD_ZERO(&socks);
	int i;
	for(i = 0; i < RARRAY_LEN(read_array); i++)
	{
		int file_des;
		file_des = NUM2INT(rb_ary_entry(read_array, i));
		FD_SET(file_des,&socks);
	}	
}

static VALUE t_select(VALUE self, VALUE read_array, int highest)
{
	build_select_list(read_array);
	int returned;
	int i;
	returned = select(highest + 1, &socks, NULL, NULL, NULL);
	if(returned == -1) {
		perror("select ()");
	}
	printf("%d file descriptors ready to read\n", returned);
	VALUE ready_to_read;
	ready_to_read = rb_ary_new();
	if(returned) {
		for(i = 0; i < 10; i++) {
			if(FD_ISSET(i, &socks)) {
				VALUE converted = INT2NUM(i); 
				rb_ary_push(ready_to_read, converted);
			}
		}
	}
	return ready_to_read;
}

VALUE blake_io;
void Init_blake_io() {
	blake_io = rb_define_class("BlakeIO", rb_cObject);
	rb_define_singleton_method(blake_io, "select", t_select, 2);
}