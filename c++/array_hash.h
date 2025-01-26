#include <stdexcept>
#include <vector>

namespace ah {
  static const size_t primes[] = {
    37, 79, 131, 181, 239, 293, 359, 421, 821, 953
  };
				
  template <typename K, typename V, class H> class ArrayHash {
  private:
    static const size_t SENTINAL = 0;
    H hasher;
    struct KV {
      size_t hash;
      K key;
      V value;
      KV(size_t h, const K & k, const V & v) : hash(h), key(k), value(v) {}
      KV() : hash(SENTINAL) {}
    };

    static size_t round_up_size(size_t minimum) {
      for (size_t i = 0; i < sizeof(primes)/sizeof(primes[0]); i++) {
	if (primes[i] > minimum) {
	  return primes[i];
	}
      }
      return minimum * 2 + 1;
    }
    
    size_t _size = 0;
    std::vector<KV> array;

    size_t hash(const K & key) const {
      size_t result = hasher(key);
      if (result == SENTINAL) {
	result++;
      }
      return result;
    }

    size_t find(const K & key) const {
      if (array.empty()) {
	return 0;
      }
      size_t h = hash(key);
      size_t location = h % array.size();
      for (size_t i = location; i < array.size(); i++) {
	const KV & kv = array.at(i);
	if (kv.hash == SENTINAL || (kv.hash == h && kv.key == key)) {
	    return i;
	}
      }
      for (size_t i = 0; i < location; i++) {
	const KV & kv = array.at(i);
	if (kv.hash == SENTINAL || (kv.hash == h && kv.key == key)) {
	    return i;
	}
      }
      return array.size();
    }

  public:
    void insert(const K & key, const V & value) {
      size_t index = find(key);
      if (index == array.size()) {
	// future: rehash
	throw std::runtime_error("Unable to make room for key");
      }
      KV & kv = array.at(index);
      if (kv.hash == SENTINAL) {
	kv = KV(hash(key), key, value);
	_size++;
      } else {
	kv.value = value;
      }
    }
    
    V & operator[](const K & key) {
      size_t index = find(key);
      if (index == array.size()) {
	throw std::runtime_error("Unable to make room for [key]");
      }
      KV & kv = array.at(index);
      if (kv.hash == SENTINAL) {
	kv = KV(hash(key), key, V());
	_size++;
      }
      return kv.value;
    }
    
    const V & operator[](const K & key) const {
      size_t index = find(key);
      if (index == array.size()) {
	throw std::runtime_error("no such key");
      }
      KV & kv = array.at(index);
      if (kv.hash == SENTINAL) {
	throw std::exception("no such key");
      }
    }

    size_t count(const K & key) const {
      size_t index = find(key);
      if (index == array.size()) {
	return 0;
      }
      const KV & kv = array.at(index);
      if (kv.hash == SENTINAL) {
	return 0;
      }
      return 1;
    }

    size_t size() const {
      return _size;
    }

    ArrayHash(size_t capacity) : array(round_up_size(capacity)) {}
    ArrayHash(const ArrayHash &other)
    : _size(round_up_size(other._size))
      , array(other.array)
      {
      }
    ~ArrayHash() {}

    class iterator {
    private:
      const ArrayHash *container;
      size_t i;
    public:
      iterator(const ArrayHash* ah, size_t offset)
	: container(ah),
	  i(offset)
	{
	}
      iterator(const iterator & other) 
	: container(other.container),
	  i(other.i)
	  {
	  }
      bool operator!=(iterator & other) {
	return !(i == other.i && container == other.container);
      }
      void operator++() {
	for (i++; i < container->array.size(); i++) {
	  if (container->array.at(i).hash != SENTINAL) {
	    break;
	  }
	}
      }
      std::pair<K, V> operator*() {
	const KV & kv = container->array.at(i);
	return std::pair(kv.key, kv.value);
      }
    };

    iterator begin() const {
      for (size_t i = 0; i < array.size(); i++) {
	if (array.at(i).hash != SENTINAL) {
	  return iterator(this, i);
	}
      }
      return end();
    }

    iterator end() const {
      return iterator(this, array.size());
    }
  };
}
	  
	
      
