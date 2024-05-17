#include <stdio.h>
#include <unistd.h>
#include <stdlib.h>
#include <stdbool.h>
#include <limits.h>
#include <sys/time.h>

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

typedef struct Link {
  struct Link * next;
  struct Entry entry;
} Link;

/*
 * A hash map implementation. Uses a fixed sized array of link-lists.
 * All entries are stored in the linked list at the hash value of the
 * key (modulus the array size). Each linked list is a "bucket" for
 * holding the key and value at that hash location. The list is
 * unordered.
 */
#define BUCKET_COUNT 1999
typedef struct {
  size_t bucket_count;
  Link* buckets[BUCKET_COUNT];
  size_t count;
} HashMap;

static HashMap *hash_map_create() {
  HashMap *result = (HashMap *)malloc(sizeof(HashMap));
  if (!result) {
    perror(NULL);
    return NULL;
  }
  result->bucket_count = BUCKET_COUNT;
  result->count = 0;
  for (size_t i = 0; i < result->bucket_count; i++) {
    result->buckets[i] = NULL;
  }
  return result;
}

static void hash_map_free(HashMap *map) {
  for (size_t i = 0; i < BUCKET_COUNT; i++) {
    Link * p = map->buckets[i];
    while (p != NULL) {
      Link * doomed = p;
      p = p->next;
      free(doomed);
    }
  }
  free(map);
}

static bool hash_map_add(HashMap * map, const Coord * key) {
  size_t hash = coord_hash(key);
  size_t index = hash % BUCKET_COUNT;
  Link * p = map->buckets[index];
  while (p != NULL && !coord_equals(&p->entry.key, key)) {
    p = p->next;
  }
  if (p == NULL) {
    p = (Link*)malloc(sizeof(Link));
    if (!p) {
      perror(NULL);
      return false;
    }
    p->next = map->buckets[index];
    p->entry.key = *key;
    p->entry.value = 1;
    map->buckets[index] = p;
    map->count++;
    return true;
  }
  p->entry.value++;
  return true;
}

static int hash_map_get(const HashMap *map, const Coord *key) {
  size_t hash = coord_hash(key);
  size_t index = hash % BUCKET_COUNT;
  Link * p = map->buckets[index];
  while (p != NULL && !coord_equals(&p->entry.key, key)) {
    p = p->next;
  }
  if (p != NULL) {
    return p->entry.value;
  }
  return 0;
}

typedef struct {
  int bucket;
  Link *ptr;
} HashIterator;
static const HashIterator HASH_ITERATOR_START = { -1, NULL};
static const HashIterator HASH_ITERATOR_END = { BUCKET_COUNT, NULL };

static HashIterator hash_iterator_next(const HashMap *map, HashIterator iter) {
  if (iter.ptr) {
    if (iter.ptr->next) {
      HashIterator result = { iter.bucket, iter.ptr->next };
      return result;
    }
  }
  while (++iter.bucket < BUCKET_COUNT) {
    if (map->buckets[iter.bucket] != NULL) {
      HashIterator result = {iter.bucket, map->buckets[iter.bucket]};
      return result;
    }
  }
  return HASH_ITERATOR_END;
}

static HashIterator hash_iterator_start(const HashMap *map) {
  return hash_iterator_next(map, HASH_ITERATOR_START);
}

static const Entry* hash_iterator_value(HashIterator iter) {
  if (iter.ptr != NULL) {
    return &(iter.ptr->entry);
  }
  return NULL;
}

const int HUMAN_WAIT_TIME_MS = 1000 / 30;
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
  for (HashIterator iter = hash_iterator_start(live_set);
       ;
       iter = hash_iterator_next(live_set, iter)) {
    const Entry * entry = hash_iterator_value(iter);
    if (!entry) {
      break;
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
  for (HashIterator iter = hash_iterator_start(counts);
       ;
       iter = hash_iterator_next(counts, iter)) {
    const Entry * entry = hash_iterator_value(iter);
    if (!entry) {
      break;
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
