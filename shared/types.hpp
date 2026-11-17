/*
 *  This files determine how the types work
 *  We will use them alongside when building the kernel
 *  We do not rely on C++ data types as it is dependent on system architecture
 *  The number after u refers to bits (the number of bits this type can hold)
 *  We have fixed data types that are defined from C++ data types with using keyword
 *  We perform a check at compiler time via static_assert() with sizeof() as condition
 *  If the size of data type is out of range, an error will be thrown at compiler time
 */

#ifndef DATA_TYPE
#define DATA_TYPE

using u8 = unsigned char; // 8 bit data type (1 byte)
using u16 = unsigned short; // 16 bit data type (2 bytes)
using u32 = unsigned int; // 32 bit data type (4 bytes)
using u64 = unsigned long; // 64 bit data type (8 bytes)
using usize = unsigned long; // as wide as a pointer

static_assert(sizeof(u8) == 1, "u8 must be 1 byte long");
static_assert(sizeof(u16) == 2, "u16 must be 2 bytes long");
static_assert(sizeof(u32) == 4, "u32 must be 4 bytes long");
static_assert(sizeof(u64) == 8, "u64 must be 8 bytes long");
static_assert(sizeof(usize) == sizeof(void*), "usize must be as wide as a pointer");

#endif // DATA_TYPE