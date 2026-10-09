#include <cstdint>
#include <cstddef>
#include <cstring>
#include <yvals_core.h>
#include <xthreads.h>
#include <time.h>

// Compatibility shims for newer MSVC STL vectorized and synchronization routines
// needed when linking against Firebase C++ SDK built with newer MSVC toolsets.

extern "C" {

bool _Avx2WmemEnabled = false;

const void* __cdecl __std_find_end_1(
    const void* const _First1,
    const void* const _Last1,
    const void* const _First2,
    const size_t _Count2) noexcept {
  const char* f1 = static_cast<const char*>(_First1);
  const char* l1 = static_cast<const char*>(_Last1);
  const char* f2 = static_cast<const char*>(_First2);
  if (_Count2 == 0) return l1;
  if (static_cast<size_t>(l1 - f1) < _Count2) return l1;
  for (const char* p = l1 - _Count2; p >= f1; --p) {
    if (memcmp(p, f2, _Count2) == 0) {
      return p;
    }
  }
  return l1;
}

const void* __cdecl __std_search_1(
    const void* const _First1,
    const void* const _Last1,
    const void* const _First2,
    const size_t _Count2) noexcept {
  const char* f1 = static_cast<const char*>(_First1);
  const char* l1 = static_cast<const char*>(_Last1);
  const char* f2 = static_cast<const char*>(_First2);
  if (_Count2 == 0) return f1;
  if (static_cast<size_t>(l1 - f1) < _Count2) return l1;
  const char* limit = l1 - _Count2;
  for (const char* p = f1; p <= limit; ++p) {
    if (memcmp(p, f2, _Count2) == 0) {
      return p;
    }
  }
  return l1;
}

void* __cdecl __std_remove_8(
    void* _First,
    void* const _Last,
    const uint64_t _Val) noexcept {
  uint64_t* first = static_cast<uint64_t*>(_First);
  uint64_t* last = static_cast<uint64_t*>(_Last);
  uint64_t* out = first;
  for (; first != last; ++first) {
    if (*first != _Val) {
      *out++ = *first;
    }
  }
  return out;
}

size_t __cdecl __std_find_first_of_trivial_pos_1(
    const void* const _Haystack,
    const size_t _Haystack_length,
    const void* const _Needle,
    const size_t _Needle_length) noexcept {
  if (_Haystack_length == 0 || _Needle_length == 0) {
    return static_cast<size_t>(-1);
  }
  const unsigned char* h = static_cast<const unsigned char*>(_Haystack);
  const unsigned char* n = static_cast<const unsigned char*>(_Needle);
  bool lookup[256] = { false };
  for (size_t j = 0; j < _Needle_length; ++j) {
    lookup[n[j]] = true;
  }
  for (size_t i = 0; i < _Haystack_length; ++i) {
    if (lookup[h[i]]) {
      return i;
    }
  }
  return static_cast<size_t>(-1);
}

size_t __cdecl __std_find_last_of_trivial_pos_1(
    const void* const _Haystack,
    const size_t _Haystack_length,
    const void* const _Needle,
    const size_t _Needle_length) noexcept {
  if (_Haystack_length == 0 || _Needle_length == 0) {
    return static_cast<size_t>(-1);
  }
  const unsigned char* h = static_cast<const unsigned char*>(_Haystack);
  const unsigned char* n = static_cast<const unsigned char*>(_Needle);
  bool lookup[256] = { false };
  for (size_t j = 0; j < _Needle_length; ++j) {
    lookup[n[j]] = true;
  }
  for (size_t i = _Haystack_length; i > 0; --i) {
    if (lookup[h[i - 1]]) {
      return i - 1;
    }
  }
  return static_cast<size_t>(-1);
}

_Thrd_result __cdecl _Cnd_timedwait_for_unchecked(
    _Cnd_t cond,
    _Mtx_t mtx,
    unsigned int target_ms) noexcept {
  _timespec64 ts;
  _timespec64_get(&ts, 1);
  ts.tv_sec += target_ms / 1000;
  ts.tv_nsec += (target_ms % 1000) * 1000000L;
  if (ts.tv_nsec >= 1000000000L) {
    ts.tv_sec += 1;
    ts.tv_nsec -= 1000000000L;
  }
  return _Cnd_timedwait(cond, mtx, &ts);
}

} // extern "C"
