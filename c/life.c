#include <stdio.h>
#include <unistd.h>
#include <stdlib.h>
#include <stdbool.h>
#include <limits.h>
#include <sys/time.h>
#include <assert.h>

static const int GENERATIONS = 1000;
static const bool SHOW_WORK = false;

// stackoverflow: https://tinyurl.com/yxnypje8
#define COUNT_OF(arr) (sizeof(arr)/sizeof(0[arr]))

typedef struct Coord {
  int x;
  int y;
} Coord;

static bool coord_equals(const Coord *a, const Coord *b) {
  return a->x == b->x && a->y == b->y;
}

static size_t coord_hash(const Coord * val) {
  return val->x * 97 + val->y;
}

typedef struct Entry {
  Coord key;
  int value;
} Entry;

static bool isempty(const Entry *val) {
  return val->value == -1;
}

/*
 * A hash map implementation. 
 */
#define CAPACITY 1999
typedef struct {
  size_t capacity;
  Entry entries[CAPACITY];
  size_t count;
} HashMap;

static HashMap *hash_map_create() {
  HashMap *result = (HashMap *)malloc(sizeof(HashMap));
  if (!result) {
    perror(NULL);
    return NULL;
  }
  result->capacity = CAPACITY;
  result->count = 0;
  for (size_t i = 0; i < result->capacity; i++) {
    result->entries[i].value = -1;
  }
  return result;
}

static void hash_map_free(HashMap *map) {
  free(map);
}

static int find(const HashMap *map, const Coord * key) {
  size_t hash = coord_hash(key);
  size_t index = hash % map->capacity;
  for (int i = index; i < map->capacity; i++) {
    const Entry * p = map->entries + i;
    if (isempty(p)) {
      return i;
    }
    if (coord_equals(&p->key, key)) {
      return i;
    }
  }
  for (int i = 0; i < index; i++) {
    const Entry * p = map->entries + i;
    if (isempty(p)) {
      return i;
    }
    if (coord_equals(&p->key, key)) {
      return i;
    }
  }
  return -1;
}
  

static bool hash_map_add(HashMap * map, const Coord * key) {
  int index = find(map, key);
  if (index < 0) {
    return false;
  }
  Entry * entry = map->entries + index;
  if (isempty(entry)) {
    entry->key.x = key->x;
    entry->key.y = key->y;
    entry->value = 0;
  }
  entry->value++;
  return true;
}

static int hash_map_get(const HashMap *map, const Coord *key) {
  int index = find(map, key);
  if (index < 0) {
    return 0;
  }
  const Entry * entry = map->entries + index;
  if (isempty(entry)) {
    return 0;
  }
  return entry->value;
}

static const int HUMAN_WAIT_TIME_MS = 1000 / 30;
static void print_board(HashMap* live_map) {
  /* clear screen, move cursor to upper-left corner */
  printf("%c[2J;%c[;H", 27, 27);
  for (int y = 20; y > -20; y--) {
    for (int x = -40; x < 40; x++) {
      Coord coord = { x, y };
      char c = ' ';
      if (hash_map_get(live_map, &coord) > 0) {
	c = '@';
      }
      printf("%c", c);
    }
    printf("\n");
  }
  if (usleep(1000 * HUMAN_WAIT_TIME_MS) < 0) {
    perror("error waiting for humans to see the current generation");
    exit(1);
  }
}

static HashMap * count_neighbors(const HashMap* live_set) {
  HashMap * counts = hash_map_create();
  if (!counts) {
    return NULL;
  }
  for (int i = 0; i < live_set->capacity; i++) {
    const Entry * entry = live_set->entries + i;
    if (isempty(entry)) {
      continue;
    }
    for (int offset_x = -1; offset_x <= 1; offset_x++) {
      for (int offset_y = -1; offset_y <= 1; offset_y++) {
	if (offset_x == 0 && offset_y == 0) {
	  continue;
	}
	Coord neighbor = { entry->key.x + offset_x, entry->key.y + offset_y };
	bool success = hash_map_add(counts, &neighbor);
	if (!success) {
	  hash_map_free(counts);
	  return NULL;
	}
      }
    }
  }
  return counts;
}


static HashMap* next_generation(const HashMap* live_set) {
  HashMap * counts = count_neighbors(live_set);
  if (!counts) {
    return NULL;
  }
  HashMap * result = hash_map_create();
  if (!result) {
    hash_map_free(counts);
    return NULL;
  }
  for (int i = 0; i < counts->capacity; i++) {
    const Entry * entry = counts->entries + i;
    if (isempty(entry)) {
      continue;
    }
    if (entry->value == 3 || (entry->value == 2 && hash_map_get(live_set, &entry->key))) {
      if (!hash_map_add(result, &entry->key)) {
	hash_map_free(counts);
	hash_map_free(result);
	return NULL;
      }
    }
  }
  hash_map_free(counts);
  return result;
}


static int run() {
  Coord r_pentomino[] = {
    {0, 0}, {0, 1}, {1, 1}, {-1, 0}, {0, -1}
  };
  HashMap * live_set = hash_map_create();
  if (!live_set) {
    return -1;
  }
  for (size_t i = 0; i < COUNT_OF(r_pentomino); i++) {
    if (!hash_map_add(live_set, &r_pentomino[i])) {
      hash_map_free(live_set);
      return -1;
    }
  }
  for (int generation = 0; generation < GENERATIONS; generation++) {
    if (SHOW_WORK) {
      print_board(live_set);
    }
    HashMap* new_live_set = next_generation(live_set);
    if (!new_live_set) {
      hash_map_free(live_set);
      return -1;
    }
    hash_map_free(live_set);
    live_set = new_live_set;
  }
  hash_map_free(live_set);
  return 0;
}

/* current time in microseconds */
static const long ERROR_NOW = 0L;
static long now() {
  struct timeval tv;
  struct timezone tz = {0, 0};
  int result = gettimeofday(&tv, &tz);
  if (result < 0) {
    perror("unable to get the current time");
    return ERROR_NOW;
  }
  return tv.tv_sec * 1000L * 1000 + tv.tv_usec;
}

int main(int argc, char** argv) {
  if (SHOW_WORK) {
    if (run() < 0) {
      fprintf(stderr, "an error occurred\n");
      return 1;
    }
  } else {
    for (int i = 0; i < 5; i++) {
      long start = now();
      if (start == ERROR_NOW) {
	return 1;
      }
      if (run() < 0) {
	fprintf(stderr, "an error occurred\n");
	return 1;
      }
      long end = now();
      if (end == ERROR_NOW) {
	return 1;
      }
      long diff = end - start;
      printf("%ld generations per second\n", (GENERATIONS * 1000 * 1000) / diff);
    }
  }
}
