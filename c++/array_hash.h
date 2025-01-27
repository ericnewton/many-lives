#include <stdexcept>
#include <vector>

namespace ah {
  
  typedef std::size_t size_t;
  
  const size_t EMPTY_ENTRY_MARKER = 0;
  
  template <typename K, typename V, class H>
  class ArrayHash {
  private:
    H _hasher;
    
    struct KV {
      size_t _hash;
      K _key;
      V _value;
      KV(size_t h, const K & k, const V & v) : _hash(h), _key(k), _value(v) {}
      KV() : _hash(EMPTY_ENTRY_MARKER) {}
    };

    // returns a number with all bits on that covers the minimum size
    // so we can use bitwise and (&) for hashing
    static size_t round_up_size(size_t minimum) {
      auto i = 0;
      while (minimum != 0) {
	minimum >>= 1;
	i++;
      }
      return (1 << (i + 1)) - 1;
    }
    
    size_t _size = 0;
    std::vector<KV> _array;

    size_t hash(const K & key) const {
      auto result = _hasher(key);
      if (result == EMPTY_ENTRY_MARKER) {
	result++;
      }
      return result;
    }

    size_t find(size_t hash, const K & key) const {
      auto location = hash & _array.size();
      for (size_t i = location; i < _array.size(); i++) {
	const auto & kv = _array.at(i);
	if (kv._hash == EMPTY_ENTRY_MARKER ||
	    (kv._hash == hash && kv._key == key)) {
	    return i;
	}
      }
      for (size_t i = 0; i < location; i++) {
	const auto & kv = _array.at(i);
	if (kv._hash == EMPTY_ENTRY_MARKER ||
	    (kv._hash == hash && kv._key == key)) {
	    return i;
	}
      }
      return _array.size();
    }

    size_t find(const K & key) const {
      return find(hash(key), key);
    }
      
  public:
    V & operator[](const K & key) {
      auto h = hash(key);
      auto index = find(h, key);
      if (index == _array.size()) {
	throw std::runtime_error("Unable to make room for [key]");
      }
      auto & kv = _array.at(index);
      if (kv._hash == EMPTY_ENTRY_MARKER) {
	kv = KV(h, key, V());
	_size++;
      }
      return kv._value;
    }
    
    const V & operator[](const K & key) const {
      auto index = find(key);
      if (index == _array.size()) {
	throw std::runtime_error("no such key");
      }
      auto & kv = _array.at(index);
      if (kv.hash == EMPTY_ENTRY_MARKER) {
	throw std::exception("no such key");
      }
    }

    size_t count(const K & key) const {
      auto index = find(key);
      if (index == _array.size()) {
	return 0;
      }
      const KV & kv = _array.at(index);
      if (kv._hash == EMPTY_ENTRY_MARKER) {
	return 0;
      }
      return 1;
    }

    size_t size() const {
      return _size;
    }

    ArrayHash(size_t capacity) : _array(round_up_size(capacity)) {}
    
    ArrayHash(const ArrayHash &other)
    : _size(round_up_size(other._size))
      , _array(other._array)
      {
      }

    class iterator {
    private:
      const ArrayHash * _container;
      size_t _index;
    public:
      iterator(const ArrayHash* ah, size_t offset)
	: _container(ah),
	  _index(offset)
	{
	}
      bool operator!=(iterator & other) {
	return !(_index == other._index && _container == other._container);
      }
      void operator++() {
	for (_index++; _index < _container->_array.size(); _index++) {
	  if (_container->_array.at(_index)._hash != EMPTY_ENTRY_MARKER) {
	    break;
	  }
	}
      }
      std::pair<K, V> operator*() {
	const KV & kv = _container->_array.at(_index);
	return std::pair<K, V>(kv._key, kv._value);
      }
    };

    iterator begin() const {
      for (size_t i = 0; i < _array.size(); i++) {
	if (_array.at(i)._hash != EMPTY_ENTRY_MARKER) {
	  return iterator(this, i);
	}
      }
      return end();
    }

    iterator end() const {
      return iterator(this, _array.size());
    }
  };
}
	  
	
      
