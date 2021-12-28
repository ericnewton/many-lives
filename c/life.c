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

static int min(int a, int b) {
  if (a < b) {
    return a;
  }
  return b;
}

static int max(int a, int b) {
  if (a > b) {
    return a;
  }
  return b;
}

typedef struct {
  int x;
  int y;
} Coord;

static bool coord_equals(const Coord *a, const Coord *b) {
  return a->x == b->x && a->y == b->y;
}

static size_t coord_hash(const Coord * val) {
  return val->x * 97 + val->y;
}

typedef struct Link {
  struct Link * next;
  Coord coord;
} Link;

/*
 * A hash set implementation.  Uses a fixed sized array of
 * link-lists. All entries are stored in the linked list at the hash
 * value of the entry (modulus the array size). Each linked list is a
 * "bucket" for holding the entries at that hash location.  The list
 * is unordered.
 */
static const size_t BUCKET_COUNT = 1999;
typedef struct {
  size_t bucket_count;
  struct Link* buckets[BUCKET_COUNT];
  size_t count;
} HashSet;

static HashSet *hash_set_create() {
  HashSet *result = (HashSet *)malloc(sizeof(HashSet));
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

static void hash_set_free(HashSet *set) {
  for (size_t i = 0; i < BUCKET_COUNT; i++) {
    Link * p = set->buckets[i];
    while (p != NULL) {
      Link * doomed = p;
      p = p->next;
      free(doomed);
    }
  }
  free(set);
}

static int hash_set_add(HashSet * set, const Coord * val) {
  size_t hash = coord_hash(val);
  size_t index = hash % BUCKET_COUNT;
  struct Link * p = set->buckets[index];
  while (p != NULL && !coord_equals(&p->coord, val)) {
    p = p->next;
  }
  if (p == NULL) {
    p = (struct Link*)malloc(sizeof(struct Link));
    if (!p) {
      perror(NULL);
      return -1;
    }
    p->next = set->buckets[index];
    p->coord = *val;
    set->buckets[index] = p;
    set->count++;
    return true;
  }
  return false;
}

static bool hash_set_contains(const HashSet *set, const Coord *val) {
  size_t hash = coord_hash(val);
  size_t index = hash % BUCKET_COUNT;
  struct Link * p = set->buckets[index];
  while (p != NULL && !coord_equals(&p->coord, val)) {
    p = p->next;
  }
  return p != NULL;
}

static void hash_set_remove(HashSet *set, const Coord *val) {
  size_t hash = coord_hash(val);
  size_t index = hash % BUCKET_COUNT;
  struct Link ** p = &(set->buckets[index]);
  while (*p != NULL && !coord_equals(&(*p)->coord, val)) {
    p = &(*p)->next;
  }
  if (*p != NULL) {
    Link *tmp = *p;
    *p = (*p)->next;
    free(tmp);
    set->count--;
  }
}

typedef struct {
  int bucket;
  Link *ptr;
} HashIterator;
static const HashIterator HASH_ITERATOR_START = { -1, NULL};
static const HashIterator HASH_ITERATOR_END = { BUCKET_COUNT, NULL };

static HashIterator hash_iterator_next(const HashSet *set, HashIterator iter) {
  if (iter.ptr) {
    if (iter.ptr->next) {
      HashIterator result = { iter.bucket, iter.ptr->next };
      return result;
    }
  }
  while (++iter.bucket < BUCKET_COUNT) {
    if (set->buckets[iter.bucket] != NULL) {
      HashIterator result = {iter.bucket, set->buckets[iter.bucket]};
      return result;
    }
  }
  return HASH_ITERATOR_END;
}

static HashIterator hash_iterator_start(const HashSet *set) {
  return hash_iterator_next(set, HASH_ITERATOR_START);
}

static const Coord* hash_iterator_value(HashIterator iter) {
  if (iter.ptr != NULL) {
    return &(iter.ptr->coord);
  }
  return NULL;
}

typedef enum {Live, Die} Destiny;
typedef struct {
  Coord coord;
  Destiny destiny;
} Change;

typedef struct {
  Change *changes;
  size_t count;
  size_t capacity;
} ChangeList;

static ChangeList* change_list_create(size_t capacity) {
  ChangeList* result = (ChangeList*)malloc(sizeof(ChangeList));
  if (!result) {
    perror(NULL);
    return NULL;
  }
  result->changes = (Change*)malloc(capacity*sizeof(ChangeList));
  if (!result->changes) {
    perror(NULL);
    free(result);
    return NULL;
  }
  result->count = 0;
  result->capacity = capacity;
  return result;
}

static int change_list_add(ChangeList* lst, Change *change) {
  if (lst->count >= lst->capacity) {
    fprintf(stderr, "change_list capacity too small to add a value\n");
    return -1;
  }
  lst->changes[lst->count++] = *change;
  return 0;
}

static void change_list_free(ChangeList * lst) {
  free(lst->changes);
  free(lst);
}

static int hash_set_count(const HashSet *live_set) {
  return live_set->count;
}

static HashSet* apply_updates(const HashSet* live_set, const ChangeList* updates) {
  HashSet* result = hash_set_create();
  if (!result) {
    return NULL;
  }
  for (HashIterator iter = hash_iterator_start(live_set);
       hash_iterator_value(iter);
       iter = hash_iterator_next(live_set, iter)) {
    const Coord * c = hash_iterator_value(iter);
    if (hash_set_add(result, c) < 0) {
      hash_set_free(result);
      return NULL;
    }
  }
  for (int c = 0; c < updates->count; c++) {
    Change change = updates->changes[c];
    switch (change.destiny) {
    case Live:
      if (hash_set_add(result, &change.coord) < 0) {
	hash_set_free(result);
	return NULL;
      }
      break;
    case Die:
      hash_set_remove(result, &change.coord);
      break;
    }
  }
  return result;
}

typedef struct {
  Coord lower_left;
  Coord upper_right;
} BoundingBox;

static BoundingBox enlarge(BoundingBox bbox, const Coord *coord) {
  BoundingBox result = {
    { min(bbox.lower_left.x, coord->x),
      min(bbox.lower_left.y, coord->y)},
    { max(bbox.upper_right.x, coord->x),
      max(bbox.upper_right.y, coord->y) }
  };
  return result;
}

const int HUMAN_WAIT_TIME_MS = 1000 / 30;
static void print_board(HashSet* live_set) {
  /* clear screen, move cursor to upper-left corner */
  printf("%c[2J;%c[;H", 27, 27);
  BoundingBox bbox = { {INT_MAX, INT_MAX}, {INT_MIN, INT_MIN} };
  for (HashIterator iter = hash_iterator_start(live_set);
       hash_iterator_value(iter);
       iter = hash_iterator_next(live_set, iter)) {
    bbox = enlarge(bbox, hash_iterator_value(iter));
  }
  for (int y = bbox.upper_right.y; y >= bbox.lower_left.y; y--) {
    for (int x = bbox.lower_left.x; x <= bbox.upper_right.x; x++) {
      Coord coord = { x, y };
      char c = ' ';
      if (hash_set_contains(live_set, &coord)) {
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

static HashSet* compute_neighbors(const ChangeList *lst) {
  HashSet* result = hash_set_create();
  for (int i = 0; i < lst->count; i++) {
    Coord * c = &(lst->changes[i].coord);
    for (int x = -1; x <= 1; x++) {
      for (int y = -1; y <= 1; y++) {
	if (x != 0 || y != 0) {
	  Coord neighbor = {c->x + x, c->y + y};
	  hash_set_add(result, &neighbor);
	}
      }
    }
  }
  return result;
}

static int nieghbor_count(const HashSet *live_set, const Coord *coord) {
  int result = 0;
  for (int x = -1; x <= 1; x++) {
    for (int y = -1; y <= 1; y++) {
      if (x != 0 || y != 0) {
	Coord neighbor = {coord->x + x, coord->y + y};
	if (hash_set_contains(live_set, &neighbor)) {
	  result++;
	}
      }
    }
  }
  return result;
}

static ChangeList * compute_updates(const HashSet *live_set,
				    const HashSet *neighbors) {
  int count = hash_set_count(neighbors);
  ChangeList *result = change_list_create(count);
  if (!result) {
    return NULL;
  }
  for (HashIterator iter = hash_iterator_start(neighbors);
       hash_iterator_value(iter);
       iter = hash_iterator_next(neighbors, iter)) {
    const Coord * c = hash_iterator_value(iter);
    int n = nieghbor_count(live_set, c);
    switch (n) {
    case 2:
      break;
    case 3:
      if (!hash_set_contains(live_set, c)) {
	Change change = { *c, Live };
	if (change_list_add(result, &change) < 0) {
	  change_list_free(result);
	  return NULL;
	}
      }
      break;
    default:
      if (hash_set_contains(live_set, c)) {
	Change change = { *c, Die };
	if (change_list_add(result, &change) < 0) {
	  change_list_free(result);
	  return NULL;
	}
      }
      break;
    }
  }
  return result;
}

static int run() {
  Coord r_pentomino[] = {
    {0, 0}, {0, 1}, {1, 1}, {-1, 0}, {0, -1}
  };
  ChangeList* updates = change_list_create(COUNT_OF(r_pentomino));
  if (!updates) {
    return -1;
  }
  for (size_t i = 0; i < COUNT_OF(r_pentomino); i++) {
    Change change = { r_pentomino[i], Live };
    if (change_list_add(updates, &change) < 0) {
      change_list_free(updates);
      return -1;
    }
  }
  HashSet * live_set = hash_set_create();
  if (!live_set) {
    change_list_free(updates);
    return -1;
  }
  for (int generation = 0; generation < GENERATIONS; generation++) {
    HashSet* updated = apply_updates(live_set, updates);
    if (!updated) {
      change_list_free(updates);
      hash_set_free(live_set);
      return -1;
    }
    if (SHOW_WORK) {
      print_board(updated);
    }
    HashSet* neighbors = compute_neighbors(updates);
    if (!neighbors) {
      change_list_free(updates);
      hash_set_free(live_set);
      hash_set_free(updated);
      return -1;
    }
    change_list_free(updates);
    updates = compute_updates(updated, neighbors);
    if (!updates) {
      hash_set_free(live_set);
      hash_set_free(updated);
      hash_set_free(neighbors);
      return -1;
    }
    hash_set_free(neighbors);
    hash_set_free(live_set);
    live_set = updated;
  }
  hash_set_free(live_set);
  change_list_free(updates);
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
