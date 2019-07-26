#include <stdio.h>
#include <stdbool.h>
#include "main.h"

int main(void)
{
    int bit_num = 0;

    printf("Hello World!\n");
    /* Little or Big Endian */
    printf("Endian Type: %s-endian\n", (is_little_endian()) ? "Little" : "Big");
    /* 64-bit or 32-bit */
    get_bit_num(&bit_num);
    printf("Bit: %d-bit\n", bit_num);
    /* Sizeof */
    printf("Sizeof {int, long, long long, void*, size_t, off_t}: "
        "{%u, %u, %u, %u, %u, %u}\n",
        (unsigned int) sizeof(int), (unsigned int) sizeof(long),
        (unsigned int) sizeof(long long), (unsigned int) sizeof(void *),
        (unsigned int) sizeof(size_t), (unsigned int) sizeof(off_t));
    /* ARCH */
    return 0;
}

bool is_little_endian()
{
    bool is_little = false;
    int n = 1;

    /* if true, little endian */
    if (*(char *)&n == 1) {
        is_little = true;
    }
    return is_little;
}

/*
 * how to find if the machine is 32bit or 64bit
 * https://stackoverflow.com/questions/2401756
 */
bool get_bit_num(int *bit_num)
{
    bool status = true;
    int p_size = sizeof(void*);

    switch (p_size) {
    case 4:
    case 8:
        *bit_num = p_size * 8;
        break;
    default:
        status = false;
    }
    return status;
}
