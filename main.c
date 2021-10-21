/**
 * lisp.c
 *
 * Author: Ziga Lenarcic
 *
 * Public domain
 */

#include <dlfcn.h>

#include <sys/select.h>
#include <sys/time.h> /* gettimeofday */
#include <stdio.h>
#include <math.h>

#define STRING_DELIMITER '"'

typedef long int i64;
typedef unsigned char u8;
typedef i64 obj;

#define IS_NIL(x) ((x) == nil)

/* if last bit 0 -> object immediate */
/* if last bit 1 -> object reference counted */

#define IS_IMMEDIATE(x) (((i64)(x) & 0x1) == 0x0)
#define IS_REF_COUNTED(x) (((i64)(x) & 0x1) == 0x1)

#define IS_INTEGER(x) (((i64)(x) & 0x3) == 0x0)
#define MAKE_INTEGER(x) ((obj)((i64)(x) << 2))
#define GET_INTEGER(x) ((i64)(x) >> 2)

#define IS_REAL(x) (((i64)(x) & 0x3) == 0x2)
#define MAKE_REAL(x) ((obj)(((i64)doubleToInt(x) & ~0x3LL) | 0x2LL))
#define GET_REAL(x) (intToDouble((i64)(x) & ~0x3LL))

#define IS_NUMBER(x) (IS_INTEGER(x) || IS_REAL(x))
#define GET_DOUBLE_VALUE(x, def) (IS_INTEGER(x) ? (double)GET_INTEGER(x) : (IS_REAL(x) ? GET_REAL(x) : (def)))

#define GET_PTR(x) ((void *)((x) & (~0x07)))
#define OBJ_FROM_PTR(x, tag) ((i64)(x) | tag)
#define CHECK_TAG(x, tag) (((x) & 0x07) == tag)

#define IS_FUNCTION(x) (CHECK_TAG((x), 0x05))
#define IS_SYMBOL(x) (CHECK_TAG((x), 0x07))
#define IS_LIST(x) (CHECK_TAG((x), 0x01))
#define IS_OTHER(x) (CHECK_TAG((x), 0x03))
#define IS_OF_TYPE(x,t) (CHECK_TAG((x), 0x03) && (((CObjHeader *)GET_PTR((x)))->type == (t)))

#define CAR(o) (((CList *)GET_PTR(o))->el  )
#define CDR(o) (((CList *)GET_PTR(o))->next)

#define GET_REF_CNT(x) (*(i64 *)GET_PTR(x))

#define PUSH_CALL_STACK(env, x, s) do { if (env->call_stack_pos < (sizeof(env->call_stack)/sizeof(env->call_stack[0]))) \
    { env->call_stack[env->call_stack_pos][0] = (x); env->call_stack[env->call_stack_pos++][1] = (s); } else writeError("Call stack overflow"); } while (0)
#define POP_CALL_STACK(env) ((env->call_stack_pos > 0) ? env->call_stack[--env->call_stack_pos][0] : nil)
#define CALL_STACK(env, i) ((env)->call_stack[(env)->call_stack_frame + (i)])
#define GET_COUNT(env) GET_INTEGER(CALL_STACK(env, 1)[0])
#define GET_ARG(env, i) (CALL_STACK(env, (i) - GET_COUNT(env))[0])

#define OBJ_FIELDS  \
    i64 ref_count; \
struct type_definition_s *type

typedef struct {
    i64 ref_count;
    obj el;
    obj next;
} CList;

typedef struct {
    OBJ_FIELDS;

    i64 call_stack_frame;
    i64 call_stack_pos;
    i64 call_stack_bindings_start;
    i64 call_stack_bindings_end;
    obj call_stack[4096][2];
} CEnvironment;

typedef struct {
    OBJ_FIELDS;
} CObjHeader;

typedef obj (* function_ptr)(CEnvironment *env);
typedef obj (* function_spec_ptr)(CEnvironment *env, obj args);

typedef struct type_definition_s {
    OBJ_FIELDS;

    const char *name;
    void (*free_func)(obj);
    void (*print_func)(i64, obj);
} CTypeDefinition;

typedef struct {
    OBJ_FIELDS;

    i64 has_global_value;
    obj global_val;
    obj function_val;
    i64 name_len;
    char name[0];
} CSymbol;

typedef struct {
    OBJ_FIELDS;

    i64 length;
    char val[0];
} CString;

typedef struct {
    OBJ_FIELDS;

    //obj symbol_bound;
    i64 function_type;
    void *f_ptr;
    obj arglist;
    obj body;
    obj argtypes;
} CFunction;

typedef struct {
    OBJ_FIELDS;

    CEnvironment env;
    u8 code[200];
    obj f;
} CCCallback;

enum {
    PARSE_STATE_READ_NEXT_TOKEN = 0,
    PARSE_STATE_READING_UNKOWN_TOKEN = 1,
    PARSE_STATE_READING_STRING = 4,
    PARSE_STATE_READING_COMMENT = 9,
    PARSE_STATE_MAYBE_COMMENT = 8,
    PARSE_STATE_PARSE_NUMBER = 10,
    PARSE_STATE_PARSE_HEXADECIMAL_NUMBER = 11,
    PARSE_STATE_PARSE_FLOATING_POINT_NUMBER = 12,
};

typedef struct
{
    char fileName[256];
    i64 file_line;

    char tempBuffer[1024];
    i64 tempBufferPos;
    char *tempBufferLarge;
    i64 escapeNextCharacter;

    i64 state;

    i64 depth;
    obj stack[128];
    obj stack_last[128];
    i64 quote_stack[128];
    const char *start;
    const char *current;
    const char *end;
    i64 final;

    obj return_val;
    i64 errorCode;
} CParseStatus;

typedef struct CMemoryHeap_
{
    i64 *pStorage[10];
    i64 *pLargeAllocations;
} CMemoryHeap;

CParseStatus globalParseStatus;

static const i64 bucketSizes[10] = {24, 64, 128, 512, 1024, 4096, 16 * 1024, 128 * 1024, 512 * 1024, 1024 * 1024};
static const i64 bucketCounts[10] = {1024, 1024, 512, 256, 128, 64, 64, 32, 6, 4};

CMemoryHeap globalHeap;

obj nil;
obj symbol_true;
obj symbol_quote;
obj symbol_i64;
obj symbol_f64;

void printType(i64 fd, obj o);
void printString(i64 fd, obj o);
void printCCallback(i64 fd, obj o);

CTypeDefinition tType = {1, &tType, "type", 0, &printType};
CTypeDefinition tInteger = {1, &tType, "integer", 0, 0};
CTypeDefinition tReal = {1, &tType, "real", 0, 0};
CTypeDefinition tListType = {1, &tType, "list", 0, 0};
CTypeDefinition tSymbolType = {1, &tType, "symbol", 0, 0};
CTypeDefinition tFunctionType = {1, &tType, "function", 0, 0};
CTypeDefinition tStringType = {1, &tType, "string", 0, &printString};
CTypeDefinition tCCalbackType = {1, &tType, "ccallback", 0, &printCCallback};

i64 dec_ref(obj o);

i64 write(i64 fd, const void *data, i64 length)
{
    i64 nReturn;
    asm volatile (
            "movq %1, %%rdi\n\r"
            "movq %2, %%rsi\n\r"
            "movq %3, %%rdx\n\r"
            "movq $1, %%rax\n\t"
            "syscall"
            : "=a" (nReturn)
            : "r" (fd), "r" (data), "r" (length)
            : "rdi", "rsi", "rdx", "rcx", "r11", "memory");

    return nReturn;
}

i64 read(i64 fd, const void *data, i64 length)
{
    i64 nReturn;
    asm volatile (
            "movq %1, %%rdi\n\r"
            "movq %2, %%rsi\n\r"
            "movq %3, %%rdx\n\r"
            "movq $0, %%rax\n\t"
            "syscall"
            : "=a" (nReturn)
            : "r" (fd), "r" (data), "r" (length)
            : "rdi", "rsi", "rdx", "rcx", "r11", "memory");

    return nReturn;
}

i64 openFile(const char *fileName, i64 nFlags, i64 nMode)
{
    i64 nFd;
    asm volatile (
            "movq %1, %%rdi\n\r"
            "movq %2, %%rsi\n\r"
            "movq %3, %%rdx\n\r"
            "movq $2, %%rax\n\t"
            "syscall"
            : "=a" (nFd)
            : "r" (fileName), "r" (nFlags), "r" (nMode)
            : "rdi", "rsi", "rdx", "rcx", "r11", "memory");
    return nFd;
}

i64 closeFile(i64 nFd)
{
    i64 nReturn;
    asm volatile (
            "movq %1, %%rdi\n\r"
            "movq $3, %%rax\n\t"
            "syscall"
            : "=a" (nReturn)
            : "r" (nFd)
            : "rdi", "rsi", "rdx", "rcx", "r11", "memory");
    return nReturn;
}

void quitProcess(int nExitCode)
{
    asm volatile ("movl %0, %%edi\n\r"
            "movq $60,%%rax\n\t"
            "syscall"
            :
            : "r" (nExitCode)
            :);
}

i64 allocateMemory(i64 size)
{
    /* mmap */
    i64 nReturn;
    asm volatile (
            "movq $0, %%rdi\n\r"
            "movq %1, %%rsi\n\r"
            "movq $7, %%rdx\n\r"
            "movq $0x22, %%r10\n\r"
            "movq $-1, %%r8\n\r"
            "movq $0, %%r9\n\r"
            "movq $9, %%rax\n\t"
            "syscall"
            : "=a" (nReturn)
            : "r" (size)
            : "rdi", "rsi", "rdx", "r10", "r8", "r9", "rcx", "r11", "memory");

    return nReturn;
}

i64 deallocateMemory(i64 addr, i64 length)
{
    /* munmap */
    i64 nReturn;
    asm volatile (
            "movq %1, %%rdi\n\r"
            "movq %2, %%rsi\n\r"
            "movq $11, %%rax\n\t"
            "syscall"
            : "=a" (nReturn)
            : "r" (addr), "r" (length)
            : "rdi", "rsi", "rdx", "rcx", "r11", "memory");

    return nReturn;
}

i64 countChars(const char *text)
{
    const char *text_start = text;
    if (text)
        while (*text)
            text++;

    return (i64)text - (i64)text_start;
}

i64 doubleToInt(double d)
{
    union { double d; i64 i; } tmp = { .d = d };
    return tmp.i;
}

double intToDouble(i64 i)
{
    union { double d; i64 i; } tmp = { .i = i };
    return tmp.d;
}

void copyStringSafe(char *dst, const char *src, i64 dst_len)
{
    i64 count = 0;

    if (dst_len == 0)
        return;

    while (*src && ((count + 1) < dst_len))
    {
        *dst = *src;
        dst++;
        src++;
        count++;
    }

    *dst = 0;
}

void moveMemory(void *destination, const void *source, i64 number_bytes)
{
    u8 *d = (u8 *)destination;
    const u8 *s = (const u8 *)source;

    while (number_bytes--)
        *d++ = *s++;
}

i64 compareMemory(const void *memory1, const void *memory2, i64 number_bytes)
{
    const u8 *m1 = (const u8 *)memory1;
    const u8 *m2 = (const u8 *)memory2;

    while (number_bytes-- && (*m1 == *m2))
    {
        m1++;
        m2++;
    }

    if (number_bytes == -1)
        return 0;
    else
        return (i64)*m1 - (i64)*m2;
}

void setMemory(void *destination, u8 value, i64 number_bytes)
{
    u8 *d = (u8 *)destination;

    while (number_bytes--)
        *d++ = value;
}

void writeNullTerminated(i64 fd, const char *text)
{
    const char *text_start = text;
    while (*text)
        text++;

    write(fd, text_start, (i64)text - (i64)text_start);
}

void printHex(i64 num, char *out, i64 numChars)
{
    for (i64 i = 0; i < numChars; i++)
    {
        i64 i2 = i + (16 - numChars);
        if (i2 >= 0)
        {
            i64 val = (num >> (60 - 4*i2)) & 0xf;
            out[i] = (val >= 10) ? (val - 10 + 'a') : (val + '0');
        }
        else
            out[i] = '0';
    }
}

void writeNumberHex(i64 fd, i64 number)
{
    char buffer[18];

    buffer[0] = '0';
    buffer[1] = 'x';

    printHex(number, &buffer[2], 16);

    write(fd, buffer, 18);
}

void writeNumber(i64 fd, i64 number)
{
    char buffer[24];
    i64 i = 23;
    i64 add_minus = 0;

    if (number < 0)
    {
        number = -number;
        add_minus = 1;
    }
    else if (number == 0)
    {
        write(fd,"0",1);
        return;
    }

    while (number)
    {
        buffer[i--] = (number % 10) + '0';
        number = number / 10;
    }

    if (add_minus)
        buffer[i--] = '-';

    write(fd, &buffer[i + 1], 23 - i);
}

void writeError(const char *text)
{
    write(2, "Error:", 6);
    writeNullTerminated(2, text);
    write(2, "\n", 1);
}

void initHeap(CMemoryHeap *heap)
{
    for (i64 i = 0; i < 10; i++)
    {
        heap->pStorage[i] = NULL;
    }

    heap->pLargeAllocations = NULL;
}

i64 allocateHeap(i64 size, CMemoryHeap *heap)
{
    /*writeNullTerminated(1, "allocate: ");
      writeNumber(1, size);
      write(1," ",1);*/

    i64 i = 0;
    if (size <= bucketSizes[0]) i = 0;
    else if (size <= bucketSizes[1]) i = 1;
    else if (size <= bucketSizes[2]) i = 2;
    else if (size <= bucketSizes[3]) i = 3;
    else if (size <= bucketSizes[4]) i = 4;
    else if (size <= bucketSizes[5]) i = 5;
    else if (size <= bucketSizes[6]) i = 6;
    else if (size <= bucketSizes[7]) i = 7;
    else if (size <= bucketSizes[8]) i = 8;
    else if (size <= bucketSizes[9]) i = 9;
    else
    {
        /* sizes larger allocate as single allocations */
        i64 allocationSize = (size + 0x8) + 2 * sizeof(i64);

        i64 addr = allocateMemory(allocationSize);
        if (addr == 0)
        {
            writeNullTerminated(1, "alloc: allocation failed\n");
            return 0;
        }

        i64 offset = 8 - (addr & 0x7);
        *(u8 *)(addr + offset - 1) = offset;

        i64 *mem = (i64 *)(addr + offset);

        mem[0] = (i64)heap->pLargeAllocations;
        mem[1] = allocationSize;
        heap->pLargeAllocations = mem; /* insert at the front */

        /*writeNumberHex(1, (i64)&mem[2]);
          write(1,"\n",1);*/
        return (i64)&mem[2];
    }

    /*writeNullTerminated(1, " bucket ");
      writeNumber(1, i);
      write(1, " ", 1);*/

    i64 bucketSize = bucketSizes[i];
    i64 *cur_part = heap->pStorage[i]; /* 0 next, 1 allocation size, 2 first free, 3 free count, 4 all count */
    while (cur_part)
    {
        if (cur_part[3] > 0)
        {
            /* allocate from this part */
            i64 addr = cur_part[2];
            cur_part[2] = *(i64 *)addr; /* next */
            cur_part[3]--;

            /* check for heap corruption (return pointer not aligned - memory was written to after free */
            if (((addr - (i64)cur_part - 40) % bucketSize) != 0)
            {
                writeNullTerminated(1, "alloc error: heap corruption detected - address not aligned ");
                writeNumberHex(1, addr);
                writeNullTerminated(1, " part start ");
                writeNumberHex(1, (i64)cur_part);
                writeNullTerminated(1, " bucket size ");
                writeNumberHex(1, (i64)bucketSize);
                write(1,"\n",1);
                return 0;
            }

            /*writeNumberHex(1, addr);
              write(1," free ",1);
              writeNumber(1, cur_part[3]);
              write(1,"\n",1);*/
            return addr;
        }

        cur_part = (i64 *)cur_part[0];
    }

    i64 allocationSize = bucketSize * bucketCounts[i] + 40 + 8;
    i64 addr = allocateMemory(allocationSize);
    if (addr == 0)
    {
        writeNullTerminated(1, "alloc: allocation failed\n");
        return 0;
    }

    i64 offset = 8 - (addr & 0x7);
    *(u8 *)(addr + offset - 1) = offset;
    i64 *part = (i64 *)(addr + offset);

    part[0] = (i64)(heap->pStorage[i]);
    part[1] = allocationSize;
    part[2] = (i64)part + 40 + bucketSize; /* first one will be returned */
    part[3] = bucketCounts[i] - 1; /* one less free as 1 will be returned */
    part[4] = bucketCounts[i];
    for (i64 j = 1; j < part[4]; j++)
    {
        if (j == (part[4] - 1))
            *(i64 *)((i64)part + 40 + j * bucketSize) = 0; /* last one */
        else
            *(i64 *)((i64)part + 40 + j * bucketSize) = ((i64)part + 40 + (j + 1) * bucketSize);
    }
    heap->pStorage[i] = part;

    /*writeNumberHex(1, (i64)part + 40);
      write(1," new part\n",1);*/
    return (i64)part + 40;
}

void freeHeap(i64 addr, CMemoryHeap *heap)
{
    /*writeNullTerminated(1, "free: ");
      writeNumberHex(1, addr);
      write(1," ",1);*/

    for (i64 i = 0; i < 10; i++)
    {
        i64 bucketSize = bucketSizes[i];
        i64 *cur_part = heap->pStorage[i]; /* 0 next, 1 allocation size, 2 first free, 3 free count, 4 all count */
        i64 *prev = 0;

        while (cur_part)
        {
            if ((addr >= ((i64)cur_part + 40)) &&
                    (addr < ((i64)cur_part + 40 + bucketSize * cur_part[4])))
            {
                /* check if pointer is aligned */
                if (((addr - (i64)cur_part - 40) % bucketSize) != 0)
                {
                    writeNullTerminated(1, "free error: address not aligned ");
                    writeNumberHex(1, addr);
                    writeNullTerminated(1, " part start ");
                    writeNumberHex(1, (i64)cur_part);
                    writeNullTerminated(1, " bucket size ");
                    writeNumberHex(1, (i64)bucketSize);
                    write(1,"\n",1);
                    return;
                }
                /* add it to the front of the free list */
                *(i64 *)addr = cur_part[2];
                /*writeNullTerminated(1, " next free was ");
                  writeNumberHex(1, *(i64 *)addr);*/
                cur_part[2] = addr;
                cur_part[3]++;

                /*writeNullTerminated(1, " bucket ");
                  writeNumber(1, i);*/

                if (cur_part[3] == cur_part[4])
                {
                    /* remove part */
                    if (prev)
                        prev[0] = cur_part[0]; /* next */
                    else
                        heap->pStorage[i] = (i64 *)cur_part[0];

                    /*writeNullTerminated(1, " removing part size ");
                      writeNumber(1, (i64)cur_part[1]);*/
                    i64 allocationAddr = (i64)cur_part - *(u8 *)((i64)cur_part - 1);
                    deallocateMemory(allocationAddr, cur_part[1]);
                }
                /*write(1,"\n",1);*/
                return;
            }

            prev = cur_part;
            cur_part = (i64 *)cur_part[0]; /* next */
        }
    }

    if (heap->pLargeAllocations)
    {
        i64 *cur_part = heap->pLargeAllocations;
        i64 *prev = 0;

        while (cur_part)
        {
            if (addr == cur_part[2])
            {
                /* remove */
                if (prev)
                    prev[0] = cur_part[0]; /* next */
                else
                    heap->pLargeAllocations = (i64 *)cur_part[0];

                /*writeNullTerminated(1, " large size ");
                  writeNumber(1, (i64)cur_part[1]);
                  write(1,"\n",1);*/
                i64 allocationAddr = (i64)cur_part - *(u8 *)((i64)cur_part - 1);
                deallocateMemory(allocationAddr, cur_part[1]);
                return;
            }

            prev = cur_part;
            cur_part = (i64 *)cur_part[0]; /* next */
        }
    }

    writeNullTerminated(1, "freeHeap: error - allocation not found: ");
    writeNumberHex(1, addr);
    write(1,"\n",1);
}

void printHeap(CMemoryHeap *heap)
{
    writeNullTerminated(1, "Heap details:\n");
    i64 bytes_allocated = 0;
    i64 bytes_used = 0;

    for (i64 i = 0; i < 10; i++)
    {
        i64 total_size = 0;
        i64 count = 0;
        i64 used_count = 0;
        i64 parts = 0;

        i64 *part = heap->pStorage[i];

        while (part)
        {
            parts++;

            count += part[4];
            bytes_allocated += part[1];
            used_count += part[4] - part[3];
            bytes_used += (part[4] - part[3]) * bucketSizes[i];

            part = (i64 *)part[0];
        }

        writeNullTerminated(1, "  Bucket ");
        writeNumber(1, i);
        writeNullTerminated(1, " - ");
        writeNumber(1, bucketSizes[i]);
        writeNullTerminated(1, " parts ");
        writeNumber(1, parts);
        writeNullTerminated(1, " used ");
        writeNumber(1, used_count);
        write(1, "/", 1);
        writeNumber(1, count);
        write(1, "\n", 1);
    }

    i64 total_size = 0;
    i64 count = 0;

    i64 *cur = heap->pLargeAllocations;

    while (cur)
    {
        total_size += cur[1];
        bytes_allocated += cur[1];
        bytes_used += cur[1];
        count++;
        cur = (i64 *)cur[0];
    }

    writeNullTerminated(1, "  Large Allocations (> 1MB): ");
    writeNumber(1, count);
    writeNullTerminated(1, ", total size ");
    writeNumber(1, total_size);
    write(1,"\n",1);

    writeNullTerminated(1, "Bytes allocated ");
    writeNumber(1, bytes_allocated);
    writeNullTerminated(1, ", used ");
    writeNumber(1, bytes_used);
    write(1,"\n",1);
}

int initEnvironment(CEnvironment *env)
{
    setMemory(env, 0, sizeof(CEnvironment));
    return 0;
}

void printType(i64 fd, obj o)
{
    writeNullTerminated(fd,"<type ");
    CTypeDefinition *td = (CTypeDefinition *)GET_PTR(o);
    writeNullTerminated(fd, td->name);
    write(fd,">",1);
}

void printString(i64 fd, obj o)
{
    static const char tmp[1] = { STRING_DELIMITER };
    write(fd,tmp,1);
    CString *s = (CString *)GET_PTR(o);
    write(fd,s->val,s->length);
    write(fd,tmp,1);
}

void printo(i64 fd, obj o);

void printCCallback(i64 fd, obj o)
{
    writeNullTerminated(fd,"<ccallback ");
    //printo(fd, ((ccallback *)GET_PTR(o))->f);
    write(fd,">",1);
}

void printo(i64 fd, obj o)
{
    if (IS_INTEGER(o))
    {
        writeNumber(fd,GET_INTEGER(o));
    }
    else if (IS_REAL(o))
    {
        char tmp[64];
        snprintf(tmp, sizeof(tmp), "%f", GET_REAL(o));
        writeNullTerminated(fd,tmp);
    }
    else if (IS_SYMBOL(o))
    {
        CSymbol *s = (CSymbol *)GET_PTR(o);
        write(fd, s->name, s->name_len);
    }
    else if (IS_LIST(o))
    {
        write(fd, "(", 1);

        for (obj c = o; !IS_NIL(c); c = CDR(c))
        {
            printo(fd, CAR(c));

            if (!IS_NIL(CDR(c)))
                write(fd, " " , 1);
        }

        write(fd, ")", 1);
    }
    else if (IS_FUNCTION(o))
    {
        CFunction *f = (CFunction *)GET_PTR(o);
        if (f->function_type == 2)
            writeNullTerminated(fd,"<special-form ");
        else if (f->function_type == 5)
            writeNullTerminated(fd,"<function-dylib ");
        else
            writeNullTerminated(fd,"<function ");

        if ((f->function_type == 1) || (f->function_type == 2) || (f->function_type == 5))
            writeNumberHex(fd,(i64)f->f_ptr);
        else
        {
            printo(fd,f->arglist);
            write(fd," ",1);
            printo(fd,f->body);
        }

        write(fd,">",1);
    }
    else if (IS_OTHER(o) && ((CObjHeader *)GET_PTR(o))->type)
    {
        /* invoke printing function */
        if (((CObjHeader *)GET_PTR(o))->type->print_func)
        {
            ((CObjHeader *)GET_PTR(o))->type->print_func(fd, o);
        }
        else
        {
            writeNullTerminated(fd, "<");
            writeNullTerminated(fd, ((CObjHeader *)GET_PTR(o))->type->name);
            write(fd,">",1);
        }
    }
    else
    {
        write(fd,"?",1);
        writeNumberHex(fd,(i64)o);
    }
}

obj inc_ref(obj o)
{
    if (IS_REF_COUNTED(o) && !IS_SYMBOL(o))
    {
        //printf("%s: Ref count for obj 0x%016lx: %u\n", __func__, (i64)o, GET_REF_CNT(o) + 1);
        ++GET_REF_CNT(o);
        return o;
    }

    return o;
}

i64 dec_ref(obj o)
{
    if (IS_REF_COUNTED(o) && !IS_SYMBOL(o))
    {
        i64 ref_cnt = --GET_REF_CNT(o);
        //printf("%s: Ref count for obj 0x%016lx: %u\n", __func__, (i64)o, ref_cnt);
        if (ref_cnt == 0)
        {
            //printf("Refcount for obj 0x%016lx = 0, freeing...\n", (i64)o);

            if (IS_SYMBOL(o))
            {
                /* symbol */
                CSymbol *s = (CSymbol *)GET_PTR(o);

                writeNullTerminated(1, "Freeing symbol:");
                printo(1, o);
                write(1, "\n", 1);

                if (s->has_global_value)
                {
                    dec_ref(s->global_val);
                }
            }
            else if (IS_LIST(o))
            {
                /* this node will be freed - decrement ref to all it points to - CAR and CDR */
                dec_ref(CAR(o));
                /* dont free the first node - it will be freed after that */

                /* instead of dec_ref(CDR(o)); do it without recursion */
                obj c = CDR(o);

                while (!IS_NIL(c))
                {
                    i64 ref_cnt_c = --GET_REF_CNT(c);
                    if (ref_cnt_c == 0)
                    {
                        /* CDR has ref count 0, do freeing without recursive calls */
                        dec_ref(CAR(c));
                        obj next = CDR(c);
                        freeHeap((i64)GET_PTR(c), &globalHeap);
                        c = next;
                    }
                    else break;
                }
            }
            else if (IS_FUNCTION(o))
            {
                CFunction *f = (CFunction *)GET_PTR(o);
                dec_ref(f->arglist);
                dec_ref(f->body);
            }

            freeHeap((i64)GET_PTR(o), &globalHeap);
        }

        return ref_cnt;
    }

    return 0;
}

obj add_list(obj new_head, obj old_list)
{
    CList *new_el = (CList *)allocateHeap(sizeof(CList), &globalHeap);

    new_el->ref_count = 1;
    new_el->el = new_head;
    new_el->next = old_list;

    return OBJ_FROM_PTR(new_el, 0x01);
}

i64 ListLength(obj o)
{
    i64 ret = 0;
    if (IS_LIST(o))
    {
        for (obj c = o; !IS_NIL(c); c = CDR(c))
        {
            ret++;
        }
    }

    return ret;
}

obj GetNth(obj o, i64 idx)
{
    if (IS_LIST(o))
    {
        for (obj c = o; !IS_NIL(c); c = CDR(c))
        {
            if (idx == 0)
                return CAR(c);
            idx--;
        }
    }

    return nil;
}

i64 is_whitespace(char c)
{
    switch (c)
    {
        case ' ':
        case '\t':
        case '\r':
        case '\n':
            return 1;
        default:
            return 0;
    }
}

i64 is_digit(char c)
{
    if ((c >= '0') && (c <= '9'))
        return 1;

    return 0;
}

i64 is_hex_digit(char c)
{
    if ((c >= '0') && (c <= '9'))
        return 1;

    if ((c >= 'a') && (c <= 'f'))
        return 1;

    if ((c >= 'A') && (c <= 'F'))
        return 1;

    return 0;
}

enum {
    PARSE_ERROR_TOO_MANY_CLOSING_PARENTHESIS = 1,
    PARSE_ERROR_NUMBER = 2,
    PARSE_ERROR_HEXADECIMAL_NUMBER = 3,
    PARSE_ERROR_FLOATING_POINT_NUMBER = 4,
    PARSE_ERROR_STRING = 5,
    PARSE_ERROR_QUOTE_UNFINISHED = 6,
};

const char *getErrorMessage(i64 parseErrorCode)
{
    switch (parseErrorCode)
    {
        case PARSE_ERROR_TOO_MANY_CLOSING_PARENTHESIS: return "Too many closing parentheses";
        case PARSE_ERROR_QUOTE_UNFINISHED: return "Quote unfinished";
        case PARSE_ERROR_NUMBER: return "Unable to parse decimal number";
        case PARSE_ERROR_HEXADECIMAL_NUMBER: return "Unable to parse hexadecimal number";
        case PARSE_ERROR_FLOATING_POINT_NUMBER: return "Unable to parse floating point number";
        case PARSE_ERROR_STRING: return "Unable to parse string";
        default:
                                 return "Unknown parse error";
    }
}

void advanceWhitespace(CParseStatus *ps)
{
    while ((ps->current != ps->end) && is_whitespace(*ps->current))
    {
        if (ps->current[0] == '\n')
            ps->file_line++;

        ps->current++;
    }
}

i64 read_number(const char **str, const char *end, i64 *number)
{
    i64 negative = 0;

    if ((**str) == '-')
    {
        (*str)++;
        negative = 1;
    }
    else if ((**str) == '+')
    {
        (*str)++;
    }

    while (**str)
    {
        if (is_digit(**str))
        {
            *number = *number * 10 + ((**str) - '0');
            (*str)++;

            if (*str == end)
                break;
        }
        else break;
    }

    if (negative)
        *number = -(*number);

    return 1;
}

i64 read_floating_point_number(const char **str, const char *end, double *number)
{
    char tempString[64];
    i64 length = (i64)end - (i64)*str;

    if (length >= (sizeof(tempString) - 1))
        return 0;

    moveMemory(tempString, *str, length);
    tempString[length] = '\0';

    if (sscanf(tempString, "%lf", number) == 1)
    {
        while (*str != end)
        {
            if (is_digit(**str) || (**str == '+') || (**str == '-') || (**str == '.') || (**str == 'e'))
                (*str)++;
            else
                break;
        }

        return 1;
    }
    else
        return 0;
}

i64 read_hex_number(const char **str, const char *end, i64 *number)
{
    i64 negative = 0;

    if ((*str)[0] == '-')
    {
        (*str)++;
        negative = 1;
    }
    else if ((*str)[0] == '+')
    {
        (*str)++;
    }

    (*str) += 2;
    while (**str)
    {
        if (is_hex_digit(**str))
        {
            i64 value;
            if ((**str >= '0') && (**str <= '9'))
                value = **str - '0';

            if ((**str >= 'a') && (**str <= 'f'))
                value = **str - 'a' + 10;

            if ((**str >= 'A') && (**str <= 'F'))
                value = **str - 'A' + 10;

            *number = (*number << 4) + value;

            (*str)++;

            if (*str == end)
                break;
        }
        else break;
    }

    if (negative)
        *number = -(*number);

    return 1;
}

struct {
    i64 count;
    obj objects[1024];
} symbols;

obj make_string(const char *str, i64 len)
{
    if (len < 0)
        len = countChars(str);

    CString *s = (CString *)allocateHeap(sizeof(CString) + len, &globalHeap);
    s->ref_count = 1;
    s->type = &tStringType;
    s->length = len;

    moveMemory(s->val, str, len);
    writeNullTerminated(1, "New string:");
    write(1, s->val, s->length);
    write(1, "\n", 1);

    obj o = OBJ_FROM_PTR(s, 0x03);

    return o;
}

obj make_symbol(const char *str, i64 len)
{
    if (len < 0)
        len = countChars(str);

    if (len == 0)
        return nil;

    /* find or create a symbol */
    for (i64 i = 0; i < symbols.count; i++)
    {
        obj o = symbols.objects[i];
        CSymbol *s = (CSymbol *)GET_PTR(o);
        if ((s->name_len == len) && (compareMemory(s->name, str, len) == 0))
        {
            return inc_ref(o);
        }
    }

    CSymbol *s = (CSymbol *)allocateHeap(sizeof(CSymbol) + /* name length */ len, &globalHeap);
    s->ref_count = 1;
    s->has_global_value = 0;
    s->global_val = 0;
    s->function_val = 0;
    s->name_len = len;

    moveMemory(s->name, str, len);
    /*
       writeNullTerminated(1, "New symbol:");
       write(1, s->name, s->name_len);
       write(1, "\n", 1);
       */

    obj o = OBJ_FROM_PTR(s, 0x07);
    symbols.objects[symbols.count] = o;
    symbols.count++;

    return inc_ref(o); /* inc_ref so it will stay valid in symbols table */
}

obj make_function(i64 function_type, void *f_ptr, obj definition, obj argtypes)
{
    CFunction *f_obj = (CFunction *)allocateHeap(sizeof(CFunction), &globalHeap);
    f_obj->ref_count = 1;
    f_obj->function_type = function_type;
    if ((function_type == 1) || (function_type == 2) || (function_type == 5))
    {
        f_obj->f_ptr = f_ptr;
        f_obj->arglist = 0;
        f_obj->body = 0;
        f_obj->argtypes = inc_ref(argtypes);
    }
    else
    {
        f_obj->argtypes = nil;
        if (IS_LIST(definition))
        {
            f_obj->arglist = inc_ref(CAR(definition));
            f_obj->body = inc_ref(CDR(definition));

            for (obj c = f_obj->arglist; !IS_NIL(c); c = CDR(c))
            {
                obj arg_name = CAR(c);

                if (!IS_SYMBOL(arg_name))
                {
                    writeError("Argument not a symbol - invalid\n");
                    printo(2,arg_name);
                    write(2,"\n",1);

                    dec_ref(OBJ_FROM_PTR(f_obj, 0x05));
                    return nil;
                }
            }

        }
        else
        {
            f_obj->arglist = nil;
            f_obj->body = nil;
        }
    }

    return OBJ_FROM_PTR(f_obj, 0x05);
}

/**
 * parse
 *
 * @param forceEnd if nonzero assume parsing must complete in current input range
 */

i64 parse(CParseStatus *ps, i64 forceEnd)
{
    ps->return_val = nil;
    ps->errorCode = 0;

    while ((i64)ps->current < (i64)ps->end)
    {
        obj o = nil;
        i64 add_o = 0;

#if 0
        writeNullTerminated(1,"Parse ");
        writeNumber(1,ps->state);
        writeNullTerminated(1," parse ptr:");
        i64 chars_left = (i64)ps->end - (i64)ps->current;
        if (chars_left > 10)
            write(1,ps->current,10);
        else
            write(1,ps->current,chars_left);
        write(1,"\n",1);
#endif

        switch (ps->state)
        {
            case PARSE_STATE_READ_NEXT_TOKEN:
                {
                    advanceWhitespace(ps);

                    if (ps->current == ps->end)
                    {
                        goto eof_reached;
                    }

                    switch (ps->current[0])
                    {
                        case '(':
                            ps->current++;

                            ps->depth++;
                            ps->stack[ps->depth] = nil;
                            ps->stack_last[ps->depth] = nil;
                            ps->quote_stack[ps->depth] = 0;
                            break;
                        case ')':
                            ps->current++;


                            if (ps->quote_stack[ps->depth] == 1)
                            {
                                ps->errorCode = PARSE_ERROR_TOO_MANY_CLOSING_PARENTHESIS;
                                goto parse_error;
                            }
                            if (ps->depth > 0)
                            {
                                ps->depth--;
                                o = ps->stack[ps->depth + 1];
                                add_o = 1;
                            }
                            else
                            {
                                ps->errorCode = PARSE_ERROR_TOO_MANY_CLOSING_PARENTHESIS;
                                goto parse_error;
                            }
                            break;
                        case STRING_DELIMITER:
                            ps->current++;

                            ps->state = PARSE_STATE_READING_STRING;
                            break;
                        case '-':
                            ps->tempBuffer[0] = ps->current[0];
                            ps->tempBufferPos = 1;
                            ps->current++;
                            ps->state = PARSE_STATE_MAYBE_COMMENT;
                            break;
                        case '\'':
                            ps->current++;

                            ps->quote_stack[ps->depth] = 1;
                            /*ps->depth++;
                              ps->stack[ps->depth] = nil;
                              ps->stack_last[ps->depth] = nil;*/
                            ps->state = PARSE_STATE_READ_NEXT_TOKEN;
                            break;
                        default:
                            ps->state = PARSE_STATE_READING_UNKOWN_TOKEN;
                            break;
                    }
                }
                break;
            case PARSE_STATE_READING_UNKOWN_TOKEN:
                switch (ps->current[0])
                {
                    case '(':
                    case ')':
                    case STRING_DELIMITER:
                    case ' ':
                    case '\t':
                    case '\r':
                    case '\n':
                        goto finish_token;
                        break;
                    default:
                        if (ps->tempBufferPos < sizeof(ps->tempBuffer))
                        {
                            ps->tempBuffer[ps->tempBufferPos++] = ps->current[0];
                        }
                        else
                        {
                            /* token too long */
                        }
                        ps->current++;
                        break;
                }
                break;

finish_token:
                {
#if 0
                    writeNullTerminated(1, "New token:");
                    write(1, ps->tempBuffer, ps->tempBufferPos);
                    write(1, "\n", 1);
#endif

                    if (ps->tempBufferPos > 0)
                    {
                        /* determine what is this */
                        i64 off = 0;

                        if ((ps->tempBuffer[0] == '-') || (ps->tempBuffer[0] == '+'))
                            off = 1;

                        if ((ps->tempBuffer[off] == '0') && (ps->tempBufferPos >= (off + 3)) &&
                                ((ps->tempBuffer[off + 1] == 'x') || (ps->tempBuffer[off + 1] == 'X')) &&
                                (is_hex_digit(ps->tempBuffer[off + 2])))
                        {
                            ps->state = PARSE_STATE_PARSE_HEXADECIMAL_NUMBER;
                            goto finish_token2;
                        }

                        if ((ps->tempBufferPos >= (off + 1)) && (is_digit(ps->tempBuffer[off]) || ((ps->tempBuffer[off] == '.') && (ps->tempBufferPos >= (off + 2))
                                        && is_digit(ps->tempBuffer[off + 1]))))
                        {
                            for (int i = off; i < ps->tempBufferPos; i++)
                            {
                                if ((ps->tempBuffer[i] == '.') || (ps->tempBuffer[i] == 'e') || (ps->tempBuffer[i] == 'E'))
                                {
                                    ps->state = PARSE_STATE_PARSE_FLOATING_POINT_NUMBER;
                                    goto finish_token2;
                                }

                                if (!is_digit(ps->tempBuffer[i]))
                                {
                                    break;
                                }
                            }

                            ps->state = PARSE_STATE_PARSE_NUMBER;
                            goto finish_token2;
                        }

                        o = make_symbol(ps->tempBuffer, ps->tempBufferPos);
                        add_o = 1;
                    }
                    else
                    {
                        /* TODO write parse error */
                        writeNullTerminated(1,"Unexpected parse error: token of size 0\n");
                        ps->current++;
                    }

                    ps->tempBufferPos = 0;
                    ps->state = PARSE_STATE_READ_NEXT_TOKEN;
                }
finish_token2:
                break;
            case PARSE_STATE_PARSE_NUMBER:
                {
                    i64 x = 0;
                    const char *tmp = ps->tempBuffer;
                    const char *end = ps->tempBuffer + ps->tempBufferPos;
                    if (read_number(&tmp, end, &x))
                    {
                        o = MAKE_INTEGER(x);
                        add_o = 1;

                        ps->tempBufferPos = 0;
                        ps->state = PARSE_STATE_READ_NEXT_TOKEN;
                    }
                    else
                    {
                        ps->errorCode = PARSE_ERROR_NUMBER;
                        goto parse_error;
                    }
                }
                break;
            case PARSE_STATE_PARSE_HEXADECIMAL_NUMBER:
                {
                    i64 x = 0;
                    const char *tmp = ps->tempBuffer;
                    const char *end = ps->tempBuffer + ps->tempBufferPos;
                    if (read_hex_number(&tmp, end, &x))
                    {
                        o = MAKE_INTEGER(x);
                        add_o = 1;

                        ps->tempBufferPos = 0;
                        ps->state = PARSE_STATE_READ_NEXT_TOKEN;
                    }
                    else
                    {
                        ps->errorCode = PARSE_ERROR_HEXADECIMAL_NUMBER;
                        goto parse_error;
                    }
                }
                break;
            case PARSE_STATE_PARSE_FLOATING_POINT_NUMBER:
                {
                    double x = 0;
                    const char *tmp = ps->tempBuffer;
                    const char *end = ps->tempBuffer + ps->tempBufferPos;
                    if (read_floating_point_number(&tmp, end, &x))
                    {
                        o = MAKE_REAL(x);
                        add_o = 1;

                        ps->tempBufferPos = 0;
                        ps->state = PARSE_STATE_READ_NEXT_TOKEN;
                    }
                    else
                    {
                        ps->errorCode = PARSE_ERROR_FLOATING_POINT_NUMBER;
                        goto parse_error;
                    }
                }
                break;
            case PARSE_STATE_READING_STRING:
                {
                    if (ps->escapeNextCharacter)
                    {
                        ps->escapeNextCharacter = 0;
                        if (ps->tempBufferPos < sizeof(ps->tempBuffer))
                        {
                            switch (ps->current[0])
                            {
                                case 'n':  ps->tempBuffer[ps->tempBufferPos++] = 0x0a; break; /* LF */
                                case 'r':  ps->tempBuffer[ps->tempBufferPos++] = 0x0d; break; /* CR */
                                case 't':  ps->tempBuffer[ps->tempBufferPos++] = 0x09; break; /* TAB */
                                case '0':  ps->tempBuffer[ps->tempBufferPos++] = 0x00; break; /* NUL */
                                case STRING_DELIMITER: ps->tempBuffer[ps->tempBufferPos++] = STRING_DELIMITER; break; /* String delimiter */
                                default:
                                                   {
                                                       /* error: unknown escaped character */
                                                   }
                            }
                        }
                        else
                        {
                            /* string too long */
                        }
                    }
                    else
                    {
                        if (ps->current[0] == '\\')
                        {
                            ps->escapeNextCharacter = 1;
                        }
                        else if (ps->current[0] == STRING_DELIMITER)
                        {
                            CString *s = (CString *)allocateHeap(sizeof(CString) + ps->tempBufferPos, &globalHeap);
                            s->ref_count = 1;
                            s->type = &tStringType;
                            s->length = ps->tempBufferPos;

                            moveMemory(s->val, ps->tempBuffer, ps->tempBufferPos);

#if 0
                            writeNullTerminated(1, "New string:'");
                            write(1, s->val, s->length);
                            write(1, "'\n", 2);
#endif

                            o = OBJ_FROM_PTR(s, 0x03);
                            add_o = 1;

                            ps->tempBufferPos = 0;
                            ps->state = PARSE_STATE_READ_NEXT_TOKEN;
                        }
                        else
                        {
                            if (ps->tempBufferPos < sizeof(ps->tempBuffer))
                            {
                                ps->tempBuffer[ps->tempBufferPos++] = ps->current[0];
                            }
                            else
                            {
                                /* string long */
                            }
                        }
                    }

                    ps->current++;
                }
                break;
            case PARSE_STATE_MAYBE_COMMENT:
                if (ps->current[0] == '-')
                {
                    ps->tempBufferPos = 0;
                    ps->state = PARSE_STATE_READING_COMMENT;
                    ps->current++;
                }
                else
                {
                    ps->state = PARSE_STATE_READING_UNKOWN_TOKEN;
                }
                break;
            case PARSE_STATE_READING_COMMENT:
                if (ps->current[0] == '\n')
                    ps->state = PARSE_STATE_READ_NEXT_TOKEN;

                ps->current++;
                break;
        }

        if (add_o)
        {
            //printf("add_o: ps depth %d\n", ps->depth);
            if (ps->quote_stack[ps->depth])
            {
                //writeNullTerminated(1,"Quote stack 1\n");
                o = add_list(inc_ref(symbol_quote), add_list(o, nil));
                ps->quote_stack[ps->depth] = 0;
            }

            if (ps->depth == 0)
            {
                ps->return_val = o;
                return 1;
            }

            if (IS_NIL(ps->stack[ps->depth]))
                ps->stack_last[ps->depth] = ps->stack[ps->depth] = add_list(o, nil);
            else
                ps->stack_last[ps->depth] = CDR(ps->stack_last[ps->depth]) = add_list(o, nil);
        }
    }

eof_reached:
    return 0;

parse_error:
    return 0;
}

int set_symbol(obj sym, obj val)
{
    if (IS_SYMBOL(sym))
    {
        CSymbol *s = (CSymbol *)GET_PTR(sym);

        /*printo(1, o);
          write(1, ": ", 2);
          printo(1, val);
          write(1, "\n", 1);*/

        if (s->has_global_value)
        {
            dec_ref(s->global_val);
        }
        s->has_global_value = 1;
        s->global_val = val;

        return 1;
    }

    return 0;
}

int set_symbol_function(obj sym, obj val)
{
    if (IS_SYMBOL(sym))
    {
        CSymbol *s = (CSymbol *)GET_PTR(sym);

        if (s->function_val > 0)
        {
            dec_ref(s->function_val);
        }
        s->function_val = val;

        return 1;
    }

    return 0;
}

obj eval(obj o, CEnvironment *env);

obj eval_body(obj o, CEnvironment *env)
{
    if (IS_LIST(o))
    {
        for (obj c = o; !IS_NIL(c); c = CDR(c))
        {
            obj new = eval(CAR(c), env);

            if (IS_NIL(CDR(c)))
                return new;
            else
                dec_ref(new);
        }

        return nil;
    }

    return nil;
}

obj f_ccall(CEnvironment *env);

obj eval_function(obj f, obj args, CEnvironment *env)
{
    i64 stack_start_pos = env->call_stack_pos;

    CFunction *func = (CFunction *)GET_PTR(f);

    i64 num_args = 0;
    if (func->function_type == 2)
    {
        obj r = ((function_spec_ptr)(func->f_ptr))(env, args); /* builtin special functions (C) */
        return r;
    }
    else if (func->function_type == 1)
    {
        for (obj c = args; !IS_NIL(c); c = CDR(c))
        {
            obj c_val = eval(CAR(c), env);
            PUSH_CALL_STACK(env, c_val, MAKE_INTEGER(0));
            num_args++;
        }
    }
    else if (func->function_type == 5)
    {
        /* depends on f_ccall */
        //PUSH_CALL_STACK(env, MAKE_INTEGER((i64)func->f_ptr), MAKE_INTEGER(0));
        PUSH_CALL_STACK(env, f, MAKE_INTEGER(0));
        num_args++;

        for (obj c = args; !IS_NIL(c); c = CDR(c))
        {
            obj c_val = eval(CAR(c), env);
            PUSH_CALL_STACK(env, c_val, MAKE_INTEGER(0));
            num_args++;
        }
    }
    else if (func->function_type == 3)
    {
        /* interpreted functions */
        obj c_name;
        obj c_val;

        for (c_val = args, c_name = func->arglist; !IS_NIL(c_val) && !IS_NIL(c_name); c_val = CDR(c_val), c_name = CDR(c_name))
        {
            obj arg_value = eval(CAR(c_val), env);
            obj arg_name = CAR(c_name);

            PUSH_CALL_STACK(env, arg_value, MAKE_INTEGER(0));

            num_args++;
        }

        if (!IS_NIL(c_val))
        {
            writeError("Too many arguments\n");
        }

        i64 i = 0;
        /* add binding symbols after all arguments have been evaluated */
        for (c_name = func->arglist; !IS_NIL(c_name); c_name = CDR(c_name))
        {
            obj arg_name = CAR(c_name);

            env->call_stack[env->call_stack_pos - num_args + i][1] = arg_name;
            i++;
        }

        if (!IS_NIL(c_name))
        {
            writeError("Too few arguments\n");
        }
    }

    PUSH_CALL_STACK(env, MAKE_INTEGER(env->call_stack_frame), MAKE_INTEGER(stack_start_pos));
    PUSH_CALL_STACK(env, MAKE_INTEGER(num_args), f);
    env->call_stack_frame = env->call_stack_pos - 2;

    obj r = nil;

    i64 prev_bindings = env->call_stack_bindings_end;
    i64 prev_bindings_start = env->call_stack_bindings_start;

    env->call_stack_bindings_start = env->call_stack_frame - num_args;
    env->call_stack_bindings_end = env->call_stack_pos;

    if (func->function_type == 1)
    {
        r = ((function_ptr)(func->f_ptr))(env); /* builtin functions (C) */
    }
    else if (func->function_type == 5)
    {
        r = f_ccall(env); /* C external functions */
    }
    else
    {
        /* interpreted functions */
        r = eval_body(func->body, env);
    }

    env->call_stack_bindings_start = prev_bindings_start;
    env->call_stack_bindings_end = prev_bindings;

#if 0
    if ((func->function_type == 1) || (func->function_type == 3))
    {
        for (i64 i = env->call_stack_pos - 1; i >= (stack_start_pos + 2); i--)
            dec_ref(env->call_stack[i][0]);
    }
#endif

    env->call_stack_pos = stack_start_pos;
    env->call_stack_frame = GET_INTEGER(env->call_stack[env->call_stack_frame][0]);

    return r;
}

obj eval(obj o, CEnvironment *env)
{
    if (IS_IMMEDIATE(o))
    {
        return o;
    }
    else if (IS_SYMBOL(o))
    {
        /* symbol value lookup */
        CSymbol *s = (CSymbol *)GET_PTR(o);

        /*writeNullTerminated(1, "Looking up symbol:");
          write(1, s->name, s->name_len);
          write(1, "\n", 1);*/

        for (i64 i = env->call_stack_bindings_end - 1; i >= (env->call_stack_bindings_start); i--)
        {
            if (o == env->call_stack[i][1])
            {
                //writeNullTerminated(1,"Found binding stack value (lexical)\n");
                obj r = inc_ref(env->call_stack[i][0]);
                //printo(1,r);
                //write(1,"\n",1);
                return r;
            }
        }

        if (s->has_global_value)
        {
            obj r = inc_ref(s->global_val);
            return s->global_val;
        }
        else
        {
            writeError("Symbol undefined");
            writeError(s->name);
            return nil;
        }
    }
    else if (IS_LIST(o))
    {
        /* function call */
        obj sym = CAR(o);
        obj f = IS_SYMBOL(sym) ? ((CSymbol *)GET_PTR(sym))->function_val : nil;

        if (IS_FUNCTION(f))
        {
            obj r = eval_function(f, CDR(o), env);
            return r;
        }
        else
        {
            writeError("Object not a function:");
            printo(2,f);
            write(2,"\n",1);
            return nil;
        }
    }
    else
    {
        return inc_ref(o);
    }
}

obj f_const(CEnvironment *env, obj args)
{
    obj sym = CAR(args);
    obj val = eval(CAR(CDR(args)), env);

    if (IS_SYMBOL(sym))
    {
        CSymbol *s = (CSymbol *)GET_PTR(sym);

        if (s->has_global_value)
        {
            dec_ref(s->global_val);
        }
        s->has_global_value = 1;
        s->global_val = val;
    }

    return inc_ref(val);
}

obj f_set(CEnvironment *env, obj args)
{
    obj sym = CAR(args);
    obj val = eval(CAR(CDR(args)), env);

    if (IS_SYMBOL(sym))
    {
        set_symbol(sym, val);
    }

    return inc_ref(val);
}

obj f_equals(CEnvironment *env, obj args)
{
    if (args == nil)
        return symbol_true;

    obj val_ref = eval(CAR(args), env);

    for (obj c = CDR(args); !IS_NIL(c); c = CDR(c))
    {
        obj val = eval(CAR(c), env);

        if (val != val_ref)
        {
            dec_ref(val_ref);
            dec_ref(val);
            return nil;
        }

        dec_ref(val);
    }

    dec_ref(val_ref);
    return symbol_true;
}

obj f_not(CEnvironment *env)
{
    obj arg0 = GET_ARG(env,0);

    if (IS_NIL(arg0))
    {
        return symbol_true;
    }
    else
    {
        return nil;
    }
}

obj f_and(CEnvironment *env, obj args)
{
    if (args == nil)
        return nil;

    obj val_ret = nil;

    for (obj c = args; !IS_NIL(c); c = CDR(c))
    {
        obj val = eval(CAR(c), env);

        if (IS_NIL(val))
        {
            dec_ref(val_ret);
            dec_ref(val);
            return nil;
        }

        dec_ref(val_ret);
        val_ret = val;
    }

    return val_ret;
}

obj f_or(CEnvironment *env, obj args)
{
    if (args == nil)
        return symbol_true;

    for (obj c = args; !IS_NIL(c); c = CDR(c))
    {
        obj val = eval(CAR(c), env);

        if (!IS_NIL(val))
        {
            return val;
        }

        dec_ref(val);
    }

    return nil;
}

#define NUMERIC_COMPARE(name, op) \
    obj f_##name(CEnvironment *env, obj args) \
{ \
    if (args == nil) \
    return symbol_true; \
    \
    obj val_ref = eval(CAR(args), env); \
    \
    for (obj c = CDR(args); !IS_NIL(c); c = CDR(c)) \
    { \
        obj val = eval(CAR(c), env); \
        \
        if (IS_INTEGER(val_ref)) \
        { \
            if (IS_INTEGER(val)) \
            { \
                if (!(GET_INTEGER(val_ref) op GET_INTEGER(val))) \
                { \
                    dec_ref(val_ref); \
                    dec_ref(val); \
                    return nil; \
                } \
            } \
            else if (IS_REAL(val)) \
            { \
                if (!((double)GET_INTEGER(val_ref) op GET_REAL(val))) \
                { \
                    dec_ref(val_ref); \
                    dec_ref(val); \
                    return nil; \
                } \
            } \
            else \
            { \
                dec_ref(val_ref); \
                dec_ref(val); \
                writeError("Variable not a number"); \
                return nil; \
            } \
        } \
        else if (IS_REAL(val_ref)) \
        { \
            if (IS_INTEGER(val)) \
            { \
                if (!(GET_REAL(val_ref) op (double)GET_INTEGER(val))) \
                { \
                    dec_ref(val_ref); \
                    dec_ref(val); \
                    return nil; \
                } \
            } \
            else if (IS_REAL(val)) \
            { \
                if (!(GET_REAL(val_ref) op GET_REAL(val))) \
                { \
                    dec_ref(val_ref); \
                    dec_ref(val); \
                    return nil; \
                } \
            } \
            else \
            { \
                dec_ref(val_ref); \
                dec_ref(val); \
                writeError("Variable not a number"); \
                return nil; \
            } \
        } \
        else \
        { \
            dec_ref(val_ref); \
            dec_ref(val); \
            writeError("Variable not a number"); \
            return nil; \
        } \
        \
        dec_ref(val_ref); \
        val_ref = val; \
    } \
    \
    dec_ref(val_ref); \
    return symbol_true; \
}

NUMERIC_COMPARE(less, <)
NUMERIC_COMPARE(more, >)
NUMERIC_COMPARE(less_eq, <=)
NUMERIC_COMPARE(more_eq, >=)

obj f_list(CEnvironment *env)
{
    obj ret = nil;

    i64 count = GET_COUNT(env);
    for (i64 i = count - 1; i >= 0; i--)
    {
        ret = add_list(inc_ref(GET_ARG(env, i)), ret);
    }

    return ret;
}

obj f_add_to_list(CEnvironment *env)
{
    return add_list(inc_ref(GET_ARG(env, 0)), inc_ref(GET_ARG(env, 1)));
}

obj f_first(CEnvironment *env)
{
    return inc_ref(CAR(GET_ARG(env, 0)));
}

obj f_rest(CEnvironment *env)
{
    return inc_ref(CDR(GET_ARG(env, 0)));
}

obj f_quote(CEnvironment *env, obj args)
{
    return CAR(args);
}

obj f_if(CEnvironment *env, obj args)
{
    obj test = eval(CAR(args), env);

    if (!IS_NIL(test))
    {
        dec_ref(test);
        return eval(CAR(CDR(args)), env);
    }
    else
    {
        dec_ref(test);
        return eval(CAR(CDR(CDR(args))), env);
    }
}

obj f_do(CEnvironment *env, obj args)
{
    return eval_body(args, env);
}

obj f_while(CEnvironment *env, obj args)
{
    obj body = CDR(args);

    while (1)
    {
        obj test = eval(CAR(args), env);

        if (!IS_NIL(test))
        {
            dec_ref(test);
            obj ret = eval_body(body, env);
            dec_ref(ret);
        }
        else
        {
            dec_ref(test);
            return nil;
        }
    }

    return nil;
}

obj f_print_environment(CEnvironment *env);
obj f_loop(CEnvironment *env, obj args)
{
    obj init_form = CAR(args);
    obj test_form = CAR(CDR(args));
    obj increment_form = CAR(CDR(CDR(args)));
    obj body_form = CDR(CDR(CDR(args)));

    obj variable = IS_LIST(init_form) ? CAR(init_form) : init_form;
    if (!IS_SYMBOL(variable))
    {
        writeError("Variable not a symbol");
        return nil;
    }

    obj init_val = MAKE_INTEGER(0);

    if (IS_LIST(init_form))
    {
        init_val = eval(CAR(CDR(init_form)), env);
    }

    set_symbol(variable, inc_ref(init_val));

    while (1)
    {
        obj test = eval(test_form, env);

        if (!IS_NIL(test))
        {
            dec_ref(test);
            obj ret = eval_body(body_form, env);
            dec_ref(ret);
        }
        else
        {
            dec_ref(test);
            break;
        }

        obj new_val = eval(increment_form, env);
        set_symbol(variable, inc_ref(new_val));
    }

    return nil;
}

obj f_function(CEnvironment *env, obj args)
{
    if (IS_SYMBOL(CAR(args)) && !IS_NIL(CAR(args)))
    {
        /* function must be bound to this symbol */
        obj f = make_function(3, 0, CDR(args), nil);
        set_symbol_function(inc_ref(CAR(args)), f);
        return inc_ref(f);
    }
    else
        return make_function(3, 0, args, nil);
}

obj f_symbol_function(CEnvironment *env)
{
    if (GET_COUNT(env) != 1)
    {
        writeError("Argument count not 1");
        return nil;
    }

    obj o = GET_ARG(env,0);

    if (IS_SYMBOL(o))
    {
        return inc_ref(((CSymbol *)GET_PTR(o))->function_val);
    }

    writeError("Argument not a symbol");
    return nil;
}

obj f_type(CEnvironment *env)
{
    if (GET_COUNT(env) != 1)
    {
        writeError("Argument count not 1");
        return nil;
    }

    obj o = GET_ARG(env,0);

    if (IS_INTEGER(o))
        return inc_ref(OBJ_FROM_PTR(&tInteger, 0x03));

    if (IS_REAL(o))
        return inc_ref(OBJ_FROM_PTR(&tReal, 0x03));

    if (IS_LIST(o))
        return inc_ref(OBJ_FROM_PTR(&tListType, 0x03));

    if (IS_SYMBOL(o))
        return inc_ref(OBJ_FROM_PTR(&tSymbolType, 0x03));

    if (IS_FUNCTION(o))
        return inc_ref(OBJ_FROM_PTR(&tFunctionType, 0x03));

    if (IS_OTHER(o))
        return inc_ref(OBJ_FROM_PTR(((CObjHeader *)GET_PTR(o))->type, 0x03));

    return nil;
}

obj f_print_environment(CEnvironment *env)
{
    writeNullTerminated(1,"Environment ");
    writeNumberHex(1,(i64)env);
    writeNullTerminated(1,"\n  stack_pos ");
    writeNumber(1,env->call_stack_pos);
    writeNullTerminated(1,"\n  stack_frame ");
    writeNumber(1,env->call_stack_frame);
    writeNullTerminated(1,"\n  stack_bindings_start ");
    writeNumber(1,env->call_stack_bindings_start);
    writeNullTerminated(1,"\n  stack_bindings_end ");
    writeNumber(1,env->call_stack_bindings_end);
    writeNullTerminated(1,"\nStack:\n");
    for (i64 i = 0; i < env->call_stack_pos; i++)
    {
        writeNumber(1,i);
        write(1,":\t",2);
        printo(1,env->call_stack[i][0]);
        write(1,"\t",1);
        printo(1,env->call_stack[i][1]);
        write(1,"\n",1);
    }

    return nil;
}

obj f_quit(CEnvironment *env)
{
    if (GET_COUNT(env) > 0)
        quitProcess(GET_INTEGER(GET_ARG(env,0)));
    else
        quitProcess(0);

    return nil;
}

obj f_plus(CEnvironment *env)
{
    i64 return_val = 0;
    double return_val_d = 0.0;

    i64 i = 0;
    i64 count = GET_COUNT(env);
    for (i = 0; i < count; i++)
    {
        obj a = GET_ARG(env,i);
        if (IS_INTEGER(a))
        {
            return_val += GET_INTEGER(a);
        }
        else if (IS_REAL(a))
        {
            return_val_d = (double)return_val + GET_REAL(a);
            break;
        }
        else
        {
            writeError("Argument not a number");
            return nil;
        }
    }

    if (i >= count)
        return MAKE_INTEGER(return_val);

    i++;

    for (; i < count; i++)
    {
        obj a = GET_ARG(env,i);
        if (IS_INTEGER(a))
        {
            return_val_d += (double)GET_INTEGER(a);
        }
        else if (IS_REAL(a))
        {
            return_val_d = return_val_d + GET_REAL(a);
        }
        else
        {
            writeError("Argument not a number");
            return nil;
        }
    }

    return MAKE_REAL(return_val_d);
}

obj f_multiply(CEnvironment *env)
{
    i64 return_val = 1;
    double return_val_d = 1.0;

    i64 i = 0;
    i64 count = GET_COUNT(env);
    for (i = 0; i < count; i++)
    {
        obj a = GET_ARG(env,i);
        if (IS_INTEGER(a))
        {
            return_val *= GET_INTEGER(a);
        }
        else if (IS_REAL(a))
        {
            return_val_d = (double)return_val * GET_REAL(a);
            break;
        }
        else
        {
            writeError("Argument not a number");
            return nil;
        }
    }

    if (i >= count)
        return MAKE_INTEGER(return_val);

    i++;

    for (; i < count; i++)
    {
        obj a = GET_ARG(env,i);
        if (IS_INTEGER(a))
        {
            return_val_d *= (double)GET_INTEGER(a);
        }
        else if (IS_REAL(a))
        {
            return_val_d = return_val_d * GET_REAL(a);
        }
        else
        {
            writeError("Argument not a number");
            return nil;
        }
    }

    return MAKE_REAL(return_val_d);
}


obj f_minus(CEnvironment *env)
{
    i64 return_val = 0;
    double return_val_d = 0;

    i64 i = 0;
    i64 count = GET_COUNT(env);
    if (count == 1)
    {
        obj a = GET_ARG(env,0);
        if (IS_INTEGER(a))
        {
            return MAKE_INTEGER(-GET_INTEGER(a));
        }
        else if (IS_REAL(a))
        {
            return a ^ 0x8000000000000000ull;
        }
        else
        {
            writeError("Argument not a number");
            return nil;
        }
    }

    for (i = 0; i < count; i++)
    {
        obj a = GET_ARG(env,i);
        if (IS_INTEGER(a))
        {
            if (i == 0)
                return_val = GET_INTEGER(a);
            else
                return_val -= GET_INTEGER(a);
        }
        else if (IS_REAL(a))
        {
            if (i == 0)
                return_val_d = GET_REAL(a);
            else
                return_val_d = (double)return_val - GET_REAL(a);
            break;
        }
        else
        {
            writeError("Argument not a number");
            return nil;
        }
    }

    if (i >= count)
        return MAKE_INTEGER(return_val);

    i++;

    for (; i < count; i++)
    {
        obj a = GET_ARG(env,i);
        if (IS_INTEGER(a))
        {
            return_val_d -= (double)GET_INTEGER(a);
        }
        else if (IS_REAL(a))
        {
            return_val_d = return_val_d - GET_REAL(a);
        }
        else
        {
            writeError("Argument not a number");
            return nil;
        }
    }

    return MAKE_REAL(return_val_d);
}

obj f_divide(CEnvironment *env)
{
    i64 return_val = 0;
    double return_val_d = 0;

    i64 i = 0;
    i64 count = GET_COUNT(env);
    if (count == 1)
    {
        obj a = GET_ARG(env,0);
        if (IS_INTEGER(a))
        {
            return MAKE_REAL(1.0 / (double)GET_INTEGER(a));
        }
        else if (IS_REAL(a))
        {
            return MAKE_REAL(1.0 / GET_REAL(a));
        }
        else
        {
            writeError("Argument not a number");
            return nil;
        }
    }

    for (i = 0; i < count; i++)
    {
        obj a = GET_ARG(env,i);
        if (IS_INTEGER(a))
        {
            if (i == 0)
                return_val = GET_INTEGER(a);
            else
            {
                i64 x = GET_INTEGER(a);

                if (return_val % x == 0)
                {
                    return_val /= x;
                }
                else
                {
                    return_val_d = (double)return_val / (double)x;
                    break;
                }
            }
        }
        else if (IS_REAL(a))
        {
            if (i == 0)
                return_val_d = GET_REAL(a);
            else
                return_val_d = (double)return_val / GET_REAL(a);
            break;
        }
        else
        {
            writeError("Argument not a number");
            return nil;
        }
    }

    if (i >= count)
        return MAKE_INTEGER(return_val);

    i++;

    for (; i < count; i++)
    {
        obj a = GET_ARG(env,i);
        if (IS_INTEGER(a))
        {
            return_val_d /= (double)GET_INTEGER(a);
        }
        else if (IS_REAL(a))
        {
            return_val_d = return_val_d / GET_REAL(a);
        }
        else
        {
            writeError("Argument not a number");
            return nil;
        }
    }

    return MAKE_REAL(return_val_d);
}

obj f_int_divide(CEnvironment *env)
{
    i64 return_val = 0;

    i64 i = 0;
    i64 count = GET_COUNT(env);
    if (count < 2)
    {
        writeError("2 Arguments or more required");
        return nil;
    }

    for (i = 0; i < count; i++)
    {
        obj a = GET_ARG(env,i);
        if (IS_INTEGER(a))
        {
            if (i == 0)
                return_val = GET_INTEGER(a);
            else
                return_val /= GET_INTEGER(a);
        }
        else if (IS_REAL(a))
        {
            if (i == 0)
                return_val = (i64)GET_REAL(a);
            else
                return_val /= (i64)GET_REAL(a);
        }
        else
        {
            writeError("Argument not a number");
            return nil;
        }
    }

    return MAKE_INTEGER(return_val);
}

obj f_print(CEnvironment *env)
{
    i64 argCount = GET_COUNT(env);

    for (i64 i = 0; i < argCount; i++)
    {
        obj arg = GET_ARG(env,i);

        if (IS_OF_TYPE(arg, &tStringType))
        {
            CString *s = (CString *)GET_PTR(arg);
            write(1,s->val,s->length);
        }
        else if (IS_INTEGER(arg))
        {
            writeNumber(1,GET_INTEGER(arg));
        }
        else
        {
            printo(1, arg);
        }
    }

    return nil;
}

obj f_hex(CEnvironment *env)
{
    obj arg0 = GET_ARG(env,0);

    if (IS_INTEGER(arg0))
    {
        i64 num = GET_INTEGER(arg0);
        char buffer[18];

        buffer[0] = '0';
        buffer[1] = 'x';

        printHex(num, &buffer[2], 16);

        CString *s = (CString *)allocateHeap(sizeof(CString) + 18, &globalHeap);
        s->ref_count = 1;
        s->type = &tStringType;
        s->length = 18;
        moveMemory(s->val, buffer, 18);

        return OBJ_FROM_PTR(s, 0x03);
    }
    else
    {
        writeNullTerminated(1,"Not a number\n");
    }

    return nil;
}

obj f_ccall(CEnvironment *env)
{
    //obj function_addr = GET_ARG(env,0);

    //i64 ptr = GET_INTEGER(function_addr);

    obj f = GET_ARG(env,0);
    i64 ptr = (i64)((CFunction *)GET_PTR(f))->f_ptr;
    obj argtypes =  ((CFunction *)GET_PTR(f))->argtypes;

    i64 arg_count = GET_COUNT(env) - 1;
    /* regs[] will be copied to registers: rdi, rsi, rdx, rcx, r8, r9,
     * xmm0, xmm1, xmm2, xmm3, xmm4, xmm5, xmm6, xmm7 */
    i64 regs[14];
    i64 stack[64];
    i64 i_regs_ints = 0;
    i64 i_regs_sse = 0;
    i64 i_args_stack = 0;

    setMemory(regs, 0, sizeof(regs));

    obj types_current = argtypes;

    for (i64 i = 1; i < GET_COUNT(env); i++)
    {
        obj arg = GET_ARG(env,i);
        obj type = IS_LIST(types_current) ? CAR(types_current) : nil;
        if (!IS_NIL(types_current))
            types_current = CDR(types_current);

        if (IS_INTEGER(arg))
        {
            if (type == symbol_i64)
            {
                if (i_regs_ints < 6)
                    regs[i_regs_ints++] = GET_INTEGER(arg);
                else
                    stack[i_args_stack++] = GET_INTEGER(arg);
            }
            else if (type == symbol_f64)
            {
                if (i_regs_sse < 8)
                    regs[6 + i_regs_sse++] = doubleToInt(GET_INTEGER(arg));
                else
                    stack[i_args_stack++] = doubleToInt(GET_INTEGER(arg));
            }
        }
        else if (IS_REAL(arg))
        {
            if (type == symbol_i64)
            {
                if (i_regs_ints < 6)
                    regs[i_regs_ints++] = (i64)GET_REAL(arg);
                else
                    stack[i_args_stack++] = (i64)GET_REAL(arg);
            }
            else if (type == symbol_f64)
            {
                if (i_regs_sse < 8)
                    regs[6 + i_regs_sse++] = doubleToInt(GET_REAL(arg));
                else
                    stack[i_args_stack++] = doubleToInt(GET_REAL(arg));
            }
        }
        else if (IS_OF_TYPE(arg, &tStringType))
        {
            if (i_regs_ints < 6)
                regs[i_regs_ints++] = (i64)((CString *)GET_PTR(arg))->val;
            else
                stack[i_args_stack++] = (i64)((CString *)GET_PTR(arg))->val;
        }
    }

    i64 ret = 0;

    asm volatile("movq (%3), %%rdi\n\t"
            "movq 0x8(%3), %%rsi\n\t"
            "movq 0x10(%3), %%rdx\n\t"
            "movq 0x18(%3), %%rcx\n\t"
            "movq 0x20(%3), %%r8\n\t"
            "movq 0x28(%3), %%r9\n\t"
            "movq 0x30(%3), %%xmm0\n\t"
            "movq 0x38(%3), %%xmm1\n\t"
            "movq 0x40(%3), %%xmm2\n\t"
            "movq 0x48(%3), %%xmm3\n\t"
            "movq 0x50(%3), %%xmm4\n\t"
            "movq 0x58(%3), %%xmm5\n\t"
            "movq 0x60(%3), %%xmm6\n\t"
            "movq 0x68(%3), %%xmm7\n\t"
            "callq *%1"
            : /* output */ "=a" (ret)
            : /* input */ "r" (ptr), "r" (arg_count), "r" (regs)
            : /* clobbers - a that a function call can change */
            "rcx", "rdx", "rsi", "rdi", "r8", "r9", "r10", "r11",
            "xmm0", "xmm1", "xmm2", "xmm3", "xmm4", "xmm5",
            "xmm6", "xmm7", "xmm8", "xmm9", "xmm10", "xmm11",
            "xmm12", "xmm13", "xmm14", "xmm15", "memory"
                );

    return MAKE_INTEGER(ret);
}

obj f_define_c_callback(CEnvironment *env, obj args)
{
    if (IS_SYMBOL(CAR(args)))
    {
        /* function must be bound to this symbol */
        CCCallback *c_obj = (CCCallback *)allocateHeap(sizeof(CCCallback), &globalHeap);
        c_obj->type = &tCCalbackType;
        c_obj->ref_count = 1;
        c_obj->f = eval(CAR(CDR(args)), env);
        if (!IS_FUNCTION(c_obj->f))
        {
            writeError("second argument not a function\n");
            return nil;
        }

        initEnvironment(&c_obj->env);
        i64 addr_eval_body = (i64)&eval_body;
        i64 obj_f_body = (i64)(((CFunction *)GET_PTR(c_obj->f))->body);
        i64 addr_env = (i64)&c_obj->env;
        i64 addr_env_call_stack = (i64)c_obj->env.call_stack;
        obj arglist = ((CFunction *)GET_PTR(c_obj->f))->arglist;
        i64 num_args = ListLength(arglist);

        for (i64 i = 0; i < num_args; i++)
        {
            c_obj->env.call_stack[i][1] = GetNth(arglist, i);
        }

        c_obj->env.call_stack_pos = num_args + 2;
        c_obj->env.call_stack[num_args][0] = MAKE_INTEGER(0);
        c_obj->env.call_stack[num_args][1] = MAKE_INTEGER(0);
        c_obj->env.call_stack[num_args + 1][0] = MAKE_INTEGER(num_args);
        c_obj->env.call_stack[num_args + 1][1] = c_obj->f;
        c_obj->env.call_stack_frame = num_args;
        c_obj->env.call_stack_bindings_start = 0;
        c_obj->env.call_stack_bindings_end = num_args + 2;

        /* code has to call the associated lisp function using eval */
        /*
           .intel_syntax noprefix

func_temp:
push rbp
mov rbp, rsp
sub rsp, 0x10
mov QWORD PTR [rbp - 0x8], rbx

mov rax, 0x1234567890abcdef
mov rbx, 0x1234567890abcdef

cmp rax, 0
jle perform_call
shl rdi, 2
mov QWORD PTR [rbx], rdi

cmp rax, 1
jle perform_call
shl rsi, 2
mov QWORD PTR [rbx + 0x10], rsi

cmp rax, 2
jle perform_call
shl rdx, 2
mov QWORD PTR [rbx + 0x20], rdx

cmp rax, 3
jle perform_call
shl rcx, 2
mov QWORD PTR [rbx + 0x30], rcx

cmp rax, 4
jle perform_call
shl r8, 2
mov QWORD PTR [rbx + 0x40], r8

cmp rax, 5
jle perform_call
shl r9, 2
mov QWORD PTR [rbx + 0x50], r9

cmp rax, 6
jle perform_call
mov rcx, QWORD PTR [rbp + 0x10]
shl rcx, 2
mov QWORD PTR [rbx + 0x60], rcx

cmp rax, 7
jle perform_call
mov rcx, QWORD PTR [rbp + 0x18]
shl rcx, 2
mov QWORD PTR [rbx + 0x70], rcx

cmp rax, 8
jle perform_call
mov rcx, QWORD PTR [rbp + 0x20]
shl rcx, 2
mov QWORD PTR [rbx + 0x80], rcx

cmp rax, 9
jle perform_call
mov rcx, QWORD PTR [rbp + 0x28]
shl rcx, 2
mov QWORD PTR [rbx + 0x90], rcx

perform_call:
mov rdi, 0x1234567890abcdef
mov rsi, 0x1234567890abcdef
mov rdx, 0x1234567890abcdef

        mov rcx, 0x1234567890abcdef
            call rcx
            shr rax, 2

            mov rbx, QWORD PTR [rbp - 0x8]
            add rsp, 0x10
            pop rbp
            ret
            */
#define INSERT_I64_BYTES(x) ((u8 *)&x)[0], ((u8 *)&x)[1], ((u8 *)&x)[2], ((u8 *)&x)[3], ((u8 *)&x)[4], ((u8 *)&x)[5], ((u8 *)&x)[6], ((u8 *)&x)[7]
            u8 code[] = { 0x55, /* push rbp */
                0x48, 0x89, 0xe5, /* mov rbp, rsp */
                0x48, 0x83, 0xec, 0x10,            /* sub    rsp,0x10 */
                0x48, 0x89, 0x5d, 0xf8,            /* mov    QWORD PTR [rbp-0x8],rbx */
                /* set up environment structure with register / stack values */
                0x48, 0xb8, INSERT_I64_BYTES(num_args), //0xef, 0xcd, 0xab, 0x90, 0x78, 0x56, 0x34, 0x12, /* movabs rax,0x1234567890abcdef */
                0x48, 0xbb, INSERT_I64_BYTES(addr_env_call_stack), //0xef, 0xcd, 0xab, 0x90, 0x78, 0x56, 0x34, 0x12, /* movabs rbx,0x1234567890abcdef */

                0x48, 0x83, 0xf8, 0x00,             /* cmp    rax,0x0 */
                0x0f, 0x8e, 0xa3, 0x00, 0x00, 0x00,       /* jle    cd <perform_call> */

                0x48, 0xc1, 0xe7, 0x02,           /* shl    rdi,0x2 */
                0x48, 0x89, 0x3b,                /* mov    QWORD PTR [rbx],rdi */

                0x48, 0x83, 0xf8, 0x01,             /* cmp    rax,0x1 */
                0x0f, 0x8e, 0x92, 0x00, 0x00, 0x00,       /* jle    c2 <perform_call> */
                0x48, 0xc1, 0xe6, 0x02,           /* shl    rsi,0x2 */
                0x48, 0x89, 0x73, 0x10,             /* mov    QWORD PTR [rbx+0x10],rsi */

                0x48, 0x83, 0xf8, 0x02,             /* cmp    rax,0x2 */
                0x0f, 0x8e, 0x80, 0x00, 0x00, 0x00,       /* jle    c2 <perform_call> */
                0x48, 0xc1, 0xe2, 0x02,           /* shl    rdx,0x2 */
                0x48, 0x89, 0x53, 0x20,             /* mov    QWORD PTR [rbx+0x20],rdx */

                0x48, 0x83, 0xf8, 0x03,             /* cmp    rax,0x3 */
                0x7e, 0x72,                   /* jle    c2 <perform_call> */
                0x48, 0xc1, 0xe1, 0x02,           /* shl    rcx,0x2 */
                0x48, 0x89, 0x4b, 0x30,             /* mov    QWORD PTR [rbx+0x30],rcx */

                0x48, 0x83, 0xf8, 0x04,             /* cmp    rax,0x4 */
                0x7e, 0x64,                   /* jle    c2 <perform_call> */
                0x49, 0xc1, 0xe0, 0x02,             /* shl    r8,0x2 */
                0x4c, 0x89, 0x43, 0x40,             /* mov    QWORD PTR [rbx+0x40],r8 */

                0x48, 0x83, 0xf8, 0x05,             /* cmp    rax,0x5 */
                0x7e, 0x56,                   /* jle    c2 <perform_call> */
                0x49, 0xc1, 0xe1, 0x02,             /* shl    r9,0x2 */
                0x4c, 0x89, 0x4b, 0x50,             /* mov    QWORD PTR [rbx+0x50],r9 */

                0x48, 0x83, 0xf8, 0x06,             /* cmp    rax,0x6 */
                0x7e, 0x48,                   /* jle    c2 <perform_call> */
                0x48, 0x8b, 0x4d, 0x10,             /* mov    rcx,QWORD PTR [rbp+0x10] */
                0x48, 0xc1, 0xe1, 0x02,             /* shl    rcx,0x2 */
                0x48, 0x89, 0x4b, 0x60,             /* mov    QWORD PTR [rbx+0x60],rcx */

                0x48, 0x83, 0xf8, 0x07,             /* cmp    rax,0x7 */
                0x7e, 0x36,                   /* jle    c2 <perform_call> */
                0x48, 0x8b, 0x4d, 0x18,             /* mov    rcx,QWORD PTR [rbp+0x18] */
                0x48, 0xc1, 0xe1, 0x02,             /* shl    rcx,0x2 */
                0x48, 0x89, 0x4b, 0x70,             /* mov    QWORD PTR [rbx+0x70],rcx */

                0x48, 0x83, 0xf8, 0x08,             /* cmp    rax,0x8 */
                0x7e, 0x24,                   /* jle    c2 <perform_call> */
                0x48, 0x8b, 0x4d, 0x20,             /* mov    rcx,QWORD PTR [rbp+0x20] */
                0x48, 0xc1, 0xe1, 0x02,             /* shl    rcx,0x2 */
                0x48, 0x89, 0x8b, 0x80, 0x00, 0x00, 0x00,    /* mov    QWORD PTR [rbx+0x80],rcx */

                0x48, 0x83, 0xf8, 0x09,             /* cmp    rax,0x9 */
                0x7e, 0x0f,                   /* jle    c2 <perform_call> */
                0x48, 0x8b, 0x4d, 0x28,             /* mov    rcx,QWORD PTR [rbp+0x28] */
                0x48, 0xc1, 0xe1, 0x02,             /* shl    rcx,0x2 */
                0x48, 0x89, 0x8b, 0x90, 0x00, 0x00, 0x00,    /* mov    QWORD PTR [rbx+0x90],rcx */

                /* perform_call: */
                0x48, 0xbf, INSERT_I64_BYTES(obj_f_body), //0xef, 0xcd, 0xab, 0x90, 0x78, 0x56, 0x34, 0x12, /* movabs rdi,0x1234567890abcdef */
                0x48, 0xbe, INSERT_I64_BYTES(addr_env), //0xef, 0xcd, 0xab, 0x90, 0x78, 0x56, 0x34, 0x12, /* movabs rsi,0x1234567890abcdef */
                0x48, 0xb9, INSERT_I64_BYTES(addr_eval_body), //0xef, 0xcd, 0xab, 0x90, 0x78, 0x56, 0x34, 0x12, /* movabs rcx,0x1234567890abcdef */
                0xff, 0xd1,                   /* call rcx */
                0x48, 0xc1, 0xe8, 0x02,             /* shr rax,0x2 */ /* convert rax to integer */
                0x48, 0x8b, 0x5d, 0xf8,            /* mov    rbx,QWORD PTR [rbp-0x8] */
                0x48, 0x83, 0xc4, 0x10,            /* add    rsp,0x10 */
                0x5d, /* pop rbp */
                0xc3 /* ret */
            };
        moveMemory(c_obj->code, code, sizeof(code));

        obj c = OBJ_FROM_PTR(c_obj, 0x03);

        set_symbol(inc_ref(CAR(args)), c);
        return inc_ref(c);
    }

    writeError("Arguments incorrect type");

    return nil;
}

obj f_ccallback(CEnvironment *env)
{
    /* return address of the c function that invokes the code */
    if (IS_OF_TYPE(GET_ARG(env, 0), &tCCalbackType))
    {
        CCCallback *c_obj = (CCCallback *)GET_PTR(GET_ARG(env, 0));

        return MAKE_INTEGER((i64)&c_obj->code);
    }

    writeError("Arguments incorrect type");

    return nil;
}

obj f_load_c_library(CEnvironment *env)
{
    obj library_name = GET_ARG(env,0);

    if (IS_OF_TYPE(library_name, &tStringType))
    {
        CString *sLibraryName = (CString *)GET_PTR(library_name);

        char library[256];
        if (sLibraryName->length < sizeof(library))
        {
            moveMemory(library, sLibraryName->val, sLibraryName->length);
            library[sLibraryName->length] = 0;

            void *lib = dlopen(library, RTLD_NOW | RTLD_LOCAL);
            if (lib == 0)
            {
                writeNullTerminated(1, dlerror());
                write(1,"\n",1);
                return nil;
            }

            return MAKE_INTEGER((i64)lib);
        }
        else
        {
            return nil;
        }
    }
    else
    {
        writeError("Arguments not strings");
        return nil;
    }

    return nil;
}

obj f_load_symbol(CEnvironment *env)
{
    i64 return_val = 0;
    obj library_pointer = GET_ARG(env,0);
    obj library_function = GET_ARG(env,1);

    if (IS_INTEGER(library_pointer) && IS_OF_TYPE(library_function, &tStringType))
    {
        CString *sFunctionName = (CString *)GET_PTR(library_function);

        char function[256];
        if (sFunctionName->length < sizeof(function))
        {
            moveMemory(function, sFunctionName->val, sFunctionName->length);
            function[sFunctionName->length] = 0;

            void *lib = (void *)GET_INTEGER(library_pointer);

            void *symbol = dlsym(lib, function);
            if (!symbol) return nil;

            return MAKE_INTEGER((i64)symbol);
        }
        else return nil;
    }
    else
    {
        writeError("Arguments integer and string");
        return nil;
    }

    return MAKE_INTEGER(return_val);
}

obj f_define_c_function(CEnvironment *env)
{
    obj library_pointer = GET_ARG(env,0);
    obj library_function = GET_ARG(env,1);

    if (IS_INTEGER(library_pointer) && IS_OF_TYPE(library_function, &tStringType))
    {
        CString *sFunctionName = (CString *)GET_PTR(library_function);
        char function[256];

        if (sFunctionName->length < sizeof(function))
        {
            moveMemory(function, sFunctionName->val, sFunctionName->length);
            function[sFunctionName->length] = 0;

            void *lib = (void *)GET_INTEGER(library_pointer);
            void *symbol = dlsym(lib, function);

            if (symbol)
            {
                obj bind_symbol = make_symbol(function, -1);
                obj argtypes = (GET_COUNT(env) > 2) ? GET_ARG(env,2) : nil;
                obj fun = make_function(5, symbol, nil, argtypes);
                set_symbol_function(bind_symbol, fun);
                //dec_ref(bind_symbol);
                return inc_ref(fun);
            }
            else
            {
                writeError("Symbol failed to load");
                writeNullTerminated(2,function);
                return nil;
            }
        }
    }

    writeError("Arguments incorrect type");

    return nil;
}

obj readInput(CEnvironment *env, CParseStatus *status, i64 fd, i64 readAll, i64 waitInput);

void initParseStatus(CParseStatus *status, const char *fileName)
{
    copyStringSafe(status->fileName, fileName, sizeof(status->fileName));
    status->state = PARSE_STATE_READ_NEXT_TOKEN;
    status->tempBufferPos = 0;
    status->tempBufferLarge = 0;
    status->file_line = 1;
    status->depth = 0;
    status->stack[0] = nil;
    status->stack_last[0] = nil;
    status->quote_stack[0] = 0;
}

obj loadFile(CEnvironment *env, const char *fileName)
{
    obj ret = nil;
    i64 nFd = openFile(fileName, 0, 0);

    CParseStatus parseStatus;
    initParseStatus(&parseStatus, fileName);

    if (nFd >= 0)
    {
        ret = readInput(env, &parseStatus, nFd, 1, 0);
        closeFile(nFd);
    }
    else
    {
        writeNullTerminated(1, "Failed to open file\n");
    }

    return ret;
}

obj f_load(CEnvironment *env)
{
    obj fileName = GET_ARG(env,0);

    char tmp[1024];
    i64 len = ((CString *)GET_PTR(fileName))->length;
    moveMemory(tmp, ((CString *)GET_PTR(fileName))->val, len);
    tmp[len] = '\0';

    return loadFile(env, tmp);
}

obj f_process_lisp(CEnvironment *env)
{
    return readInput(env, &globalParseStatus, 0, 0, 0);
}

obj f_room(CEnvironment *env)
{
    printHeap(&globalHeap);
    return nil;
}

#define NUMERIC_FUNCTION(name) \
    obj f_##name(CEnvironment *env) \
{ \
    obj arg0 = GET_ARG(env,0); \
    \
    if (IS_REAL(arg0))\
    {\
        return MAKE_REAL(name(GET_REAL(arg0))); \
    } \
    else if (IS_INTEGER(arg0))\
    {\
        return MAKE_REAL(name((double)GET_INTEGER(arg0))); \
    } \
    else \
    { \
        writeNullTerminated(1,"Not a number\n"); \
    } \
    \
    return nil; \
}

NUMERIC_FUNCTION(sin)
NUMERIC_FUNCTION(cos)
NUMERIC_FUNCTION(tan)
NUMERIC_FUNCTION(exp)

obj f_mod(CEnvironment *env)
{
    obj arg0 = GET_ARG(env,0);
    obj arg1 = GET_ARG(env,1);

    if (IS_INTEGER(arg0) && IS_INTEGER(arg1))
    {
        return MAKE_INTEGER(GET_INTEGER(arg0) % GET_INTEGER(arg1));
    }
    else if (IS_NUMBER(arg0) && IS_NUMBER(arg1))
    {
        return MAKE_REAL(fmod(GET_DOUBLE_VALUE(arg0, 0.0), GET_DOUBLE_VALUE(arg1, 0.0)));
    }
    else
    {
        writeNullTerminated(1,"Arguments not numbers\n");
        return nil;
    }
}

obj f_get_time(CEnvironment *env)
{
    struct timeval tv;
    gettimeofday(&tv, NULL);

    return MAKE_REAL((double)tv.tv_sec + (double)tv.tv_usec / 1e6);
}

i64 random_seed = 0;

unsigned long int GetRandom(void)
{
    random_seed += 0x283794123A1293FULL;
    random_seed *= 0x172839412737123ULL;
    random_seed ^= (random_seed << 17);
    random_seed ^= (random_seed >> 13);
    random_seed ^= (random_seed << 23);

    return (unsigned long int)(random_seed ^ (random_seed >> 17)) ^ (random_seed << 19);
}

obj f_random_seed(CEnvironment *env)
{
    obj arg0 = GET_ARG(env,0);

    if (IS_INTEGER(arg0))
    {
        random_seed = GET_INTEGER(arg0);
        return nil;
    }
    else
    {
        writeError("Argument not a number\n");
        return nil;
    }
}

obj f_random(CEnvironment *env)
{
    obj arg0 = GET_ARG(env,0);

    if (GET_COUNT(env) < 1)
    {
        return MAKE_REAL((double)GetRandom() / (double)0xffffffffffffffffull);
    }
    else if (IS_INTEGER(arg0))
    {
        i64 i = GET_INTEGER(arg0);
        if (i >= 0)
            return MAKE_INTEGER(GetRandom() % (unsigned long int)i);
        else
            return MAKE_INTEGER(-(GetRandom() % (unsigned long int)(-i)));
    }
    else if (IS_REAL(arg0))
    {
        return MAKE_REAL(((double)GetRandom() / (double)0xffffffffffffffffull) * GET_REAL(arg0));
    }
    else
    {
        writeError("Argument not a number\n");
        return MAKE_INTEGER(0);
    }
}

obj f_print_address(CEnvironment *env)
{
    char tmp[4] = "   ";
    obj arg0 = GET_ARG(env,0);
    obj arg1 = GET_ARG(env,1);

    if (IS_INTEGER(arg0) && IS_INTEGER(arg1))
    {
        i64 addr = GET_INTEGER(arg0);
        i64 count = GET_INTEGER(arg1);

        u8 *memory = (u8 *)addr;

        for (i64 i = 0; i < count; i += 16)
        {
            writeNumberHex(1, addr + i);
            write(1, ":", 1);

            for (i64 j = 0; j < 16; j++)
            {
                if ((i + j) >= count)
                    break;

                printHex(memory[i + j], &tmp[1], 2);
                write(1, tmp, 3);
            }

            write(1, " |", 2);
            for (i64 j = 0; j < 16; j++)
            {
                if ((i + j) >= count)
                    break;

                char c = memory[i + j];
                if (c == 0)
                    c = ' ';
                else if (c < ' ' || c >= 127)
                    c = '.';

                write(1, &c, 1);
            }

            if (i + 16 <= count)
                write(1,"|", 1);

            write(1, "\n", 1);
        }

        return nil;
    }
    else
    {
        writeError("Argument not a number\n");
        return MAKE_INTEGER(0);
    }
}

void initLisp(void)
{
    nil = make_symbol("n", -1);
    set_symbol(nil, inc_ref(nil));

    symbol_true = make_symbol("y", 1);
    set_symbol(symbol_true, inc_ref(symbol_true));

    symbol_quote = make_symbol("quote", -1);
    symbol_i64 = make_symbol("i64", -1);
    symbol_f64 = make_symbol("f64", -1);

    set_symbol_function(make_symbol("+", -1), make_function(1,&f_plus, nil, nil));
    set_symbol_function(make_symbol("*", -1), make_function(1,&f_multiply, nil, nil));
    set_symbol_function(make_symbol("-", -1), make_function(1,&f_minus, nil, nil));
    set_symbol_function(make_symbol("/", -1), make_function(1,&f_divide, nil, nil));
    set_symbol_function(make_symbol("int/", -1), make_function(1,&f_int_divide, nil, nil));
    set_symbol_function(make_symbol("const", -1), make_function(2,&f_const, nil, nil));
    set_symbol_function(make_symbol("set", -1), make_function(2,&f_set, nil, nil));
    set_symbol_function(make_symbol("=", -1), make_function(2,&f_equals, nil, nil));
    set_symbol_function(make_symbol("not", -1), make_function(1,&f_not, nil, nil));
    set_symbol_function(make_symbol("and", -1), make_function(2,&f_and, nil, nil));
    set_symbol_function(make_symbol("or", -1), make_function(2,&f_or, nil, nil));
    set_symbol_function(make_symbol("<", -1), make_function(2,&f_less, nil, nil));
    set_symbol_function(make_symbol(">", -1), make_function(2,&f_more, nil, nil));
    set_symbol_function(make_symbol("<=", -1), make_function(2,&f_less_eq, nil, nil));
    set_symbol_function(make_symbol(">=", -1), make_function(2,&f_more_eq, nil, nil));
    set_symbol_function(make_symbol("list", -1), make_function(1,&f_list, nil, nil));
    set_symbol_function(make_symbol("add-to-list", -1), make_function(1,&f_add_to_list, nil, nil));
    set_symbol_function(make_symbol("first", -1), make_function(1,&f_first, nil, nil));
    set_symbol_function(make_symbol("rest", -1), make_function(1,&f_rest, nil, nil));
    set_symbol_function(symbol_quote, make_function(2,&f_quote, nil, nil));
    set_symbol_function(make_symbol("if", -1), make_function(2,&f_if, nil, nil));
    set_symbol_function(make_symbol("do", -1), make_function(2,&f_do, nil, nil));
    set_symbol_function(make_symbol("while", -1), make_function(2,&f_while, nil, nil));
    set_symbol_function(make_symbol("loop", -1), make_function(2,&f_loop, nil, nil));
    set_symbol_function(make_symbol("print", -1), make_function(1,&f_print, nil, nil));
    set_symbol_function(make_symbol("hex", -1), make_function(1,&f_hex, nil, nil));
    set_symbol_function(make_symbol("function", -1), make_function(2,&f_function, nil, nil));
    set_symbol_function(make_symbol("symbol-function", -1), make_function(1,&f_symbol_function, nil, nil));
    set_symbol_function(make_symbol("print-environment", -1), make_function(1,&f_print_environment, nil, nil));
    set_symbol_function(make_symbol("load-library", -1), make_function(1,&f_load_c_library, nil, nil));
    set_symbol_function(make_symbol("load-symbol", -1), make_function(1,&f_load_symbol, nil, nil));
    set_symbol_function(make_symbol("define-c-function", -1), make_function(1,&f_define_c_function, nil, nil));
    set_symbol_function(make_symbol("define-c-callback", -1), make_function(2,&f_define_c_callback, nil, nil));
    set_symbol_function(make_symbol("ccallback", -1), make_function(1,&f_ccallback, nil, nil));
    set_symbol_function(make_symbol("type", -1), make_function(1,&f_type, nil, nil));
    set_symbol_function(make_symbol("quit", -1), make_function(1,&f_quit, nil, nil));
    set_symbol_function(make_symbol("load", -1), make_function(1,&f_load, nil, nil));
    set_symbol_function(make_symbol("process-lisp", -1), make_function(1,&f_process_lisp, nil, nil));
    set_symbol_function(make_symbol("room", -1), make_function(1,&f_room, nil, nil));
    set_symbol_function(make_symbol("sin", -1), make_function(1,&f_sin, nil, nil));
    set_symbol_function(make_symbol("cos", -1), make_function(1,&f_cos, nil, nil));
    set_symbol_function(make_symbol("tan", -1), make_function(1,&f_tan, nil, nil));
    set_symbol_function(make_symbol("exp", -1), make_function(1,&f_exp, nil, nil));
    set_symbol(make_symbol("pi", -1), MAKE_REAL(3.141592653589793));
    set_symbol(make_symbol("e", -1), MAKE_REAL(2.718281828459045));
    set_symbol_function(make_symbol("mod", -1), make_function(1,&f_mod, nil, nil));
    set_symbol_function(make_symbol("get-time", -1), make_function(1,&f_get_time, nil, nil));
    set_symbol_function(make_symbol("random-seed", -1), make_function(1,&f_random_seed, nil, nil));
    set_symbol_function(make_symbol("random", -1), make_function(1,&f_random, nil, nil));
    set_symbol_function(make_symbol("print-address", -1), make_function(1,&f_print_address, nil, nil));
}

obj readInput(CEnvironment *env, CParseStatus *status, i64 fd, i64 readAll, i64 waitInput)
{
    fd_set readfd;
    struct timeval timeout;
    obj ret = nil;

    char input[24];
    i64 forceEnd = 0;

    i64 number_bytes;
read_input:
    if (waitInput == 0)
    {
        setMemory(&timeout, 0, sizeof(timeout));
        FD_ZERO(&readfd);
        FD_SET(fd, &readfd);

        if (select(fd + 1, &readfd, 0, 0, &timeout) <= 0)
            return ret;
    }

    number_bytes = read(fd, input, sizeof(input));

#if 0
    writeNullTerminated(2,"bytes read:");
    writeNumber(2,number_bytes);
    write(2,"\n",1);
#endif

    if (number_bytes <= 0)
        return ret;

    forceEnd = (number_bytes == sizeof(input)) ? 0 : 1;

    status->start = input;
    status->current = status->start;
    status->end = input + number_bytes;

next_parse:
    if (parse(status, forceEnd))
    {
        obj o = status->return_val;
        /*writeNullTerminated(1,"In:"); printo(1, o); write(1,"\n",1);*/
        obj r = eval(o, env);
        set_symbol(make_symbol("%", -1), inc_ref(r));
        printo(1, r); write(1,"\n",1);
        dec_ref(o);
        if (ret != nil)
            dec_ref(ret);
        ret = r;

        if (status->current != status->end)
            goto next_parse;
    }
    else
    {
        if (status->errorCode)
        {
            writeError("Parse error:");
            writeNullTerminated(2, getErrorMessage(status->errorCode));
            write(2,"\n",1);
            writeNullTerminated(2,status->fileName);
            write(2,":",1);
            writeNumber(2,status->file_line);
            write(2,"\n",1);
        }
        else
        {
            goto read_input;
        }
    }

    if (readAll)
        goto read_input;
}

char *openFileName;

void __start(void)
{
    initHeap(&globalHeap);

    initLisp();

    CEnvironment env;
    initEnvironment(&env);

    initParseStatus(&globalParseStatus, "stdin");

    if (openFileName)
    {
        loadFile(&env, openFileName);
    }

    dec_ref(readInput(&env, &globalParseStatus, 0, 0, 1));

    quitProcess(0);
}

void main(int argc, char *argv[])
{
    if (argc > 1)
        openFileName = argv[1];

    __start();
}
