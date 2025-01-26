ifeq ($(shell uname), Darwin)
CC=gcc-14
endif
life: life.c
	$(CC) -O3 -Wall -o life life.c

clean:
	$(RM) life

