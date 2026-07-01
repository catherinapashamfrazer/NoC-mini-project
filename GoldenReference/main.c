#include "noc_golden.h"

#include <errno.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

static int parse_u8(const char *text, uint8_t *value)
{
    char *end = NULL;
    long parsed;

    errno = 0;
    parsed = strtol(text, &end, 0);
    if (errno != 0 || end == text || *end != '\0' || parsed < 0 || parsed > 255)
    {
        return -1;
    }

    *value = (uint8_t)parsed;
    return 0;
}

static int run_self_test(void)
{
    static const noc_route_t expected[2][2][4] = {
        {
            {NOC_ROUTE_LOCAL, NOC_ROUTE_EAST,  NOC_ROUTE_SOUTH, NOC_ROUTE_EAST},
            {NOC_ROUTE_WEST,  NOC_ROUTE_LOCAL,  NOC_ROUTE_WEST,   NOC_ROUTE_SOUTH}
        },
        {
            {NOC_ROUTE_NORTH, NOC_ROUTE_EAST,  NOC_ROUTE_LOCAL,  NOC_ROUTE_EAST},
            {NOC_ROUTE_WEST,  NOC_ROUTE_NORTH, NOC_ROUTE_WEST,   NOC_ROUTE_LOCAL}
        }
    };

    for (uint8_t y = 0; y < 2; ++y)
    {
        for (uint8_t x = 0; x < 2; ++x)
        {
            for (uint8_t dest = 0; dest < 4; ++dest)
            {
                noc_route_result_t actual = noc_route_xy(x, y, dest);

                if (actual.route != expected[y][x][dest] || actual.local_hit != (dest == ((y << 1) | x)))
                {
                    fprintf(stderr,
                            "Mismatch at x=%u y=%u dest=%u: route=%s local_hit=%d\n",
                            x,
                            y,
                            dest,
                            noc_route_name(actual.route),
                            actual.local_hit ? 1 : 0);
                    return 1;
                }
            }
        }
    }

    puts("Self-test passed: all 16 XY routing cases match the golden model.");
    return 0;
}

static void print_sweep(void)
{
    puts("x,y,dest,route,local_hit");
    for (uint8_t y = 0; y < 2; ++y)
    {
        for (uint8_t x = 0; x < 2; ++x)
        {
            for (uint8_t dest = 0; dest < 4; ++dest)
            {
                noc_route_result_t result = noc_route_xy(x, y, dest);
                printf("%u,%u,%u,%s,%u\n",
                       x,
                       y,
                       dest,
                       noc_route_name(result.route),
                       result.local_hit ? 1u : 0u);
            }
        }
    }
}

static int print_packet_route(uint8_t x, uint8_t y, uint8_t packet)
{
    noc_route_result_t result = noc_route_packet(x, y, packet);

    printf("packet=0x%02X dest=%u route=%s local_hit=%u\n",
           packet,
           noc_packet_dest(packet),
           noc_route_name(result.route),
           result.local_hit ? 1u : 0u);
    return 0;
}

static int compare_file(const char *path)
{
    FILE *stream = fopen(path, "r");
    char line[256];
    unsigned long line_no = 0;

    if (stream == NULL)
    {
        perror(path);
        return 1;
    }

    while (fgets(line, sizeof(line), stream) != NULL)
    {
        char *cursor = line;
        char *end = NULL;
        long x;
        long y;
        long dest;
        long expected;
        noc_route_result_t actual;

        ++line_no;

        while (*cursor == ' ' || *cursor == '\t')
        {
            ++cursor;
        }

        if (*cursor == '\0' || *cursor == '\n' || *cursor == '#')
        {
            continue;
        }

        errno = 0;
        x = strtol(cursor, &end, 0);
        if (errno != 0 || end == cursor)
        {
            fprintf(stderr, "Line %lu: invalid x value\n", line_no);
            fclose(stream);
            return 1;
        }

        cursor = end;
        y = strtol(cursor, &end, 0);
        if (errno != 0 || end == cursor)
        {
            fprintf(stderr, "Line %lu: invalid y value\n", line_no);
            fclose(stream);
            return 1;
        }

        cursor = end;
        dest = strtol(cursor, &end, 0);
        if (errno != 0 || end == cursor)
        {
            fprintf(stderr, "Line %lu: invalid dest value\n", line_no);
            fclose(stream);
            return 1;
        }

        cursor = end;
        expected = strtol(cursor, &end, 0);
        if (errno != 0 || end == cursor)
        {
            fprintf(stderr, "Line %lu: invalid expected route value\n", line_no);
            fclose(stream);
            return 1;
        }

        actual = noc_route_xy((uint8_t)x, (uint8_t)y, (uint8_t)dest);
        if ((long)actual.route != expected)
        {
            fprintf(stderr,
                    "Line %lu mismatch: x=%ld y=%ld dest=%ld expected=%ld got=%s\n",
                    line_no,
                    x,
                    y,
                    dest,
                    expected,
                    noc_route_name(actual.route));
            fclose(stream);
            return 1;
        }
    }

    fclose(stream);
    puts("Comparison passed.");
    return 0;
}

static void usage(const char *program)
{
    fprintf(stderr,
            "Usage:\n"
            "  %s --self-test\n"
            "  %s --sweep\n"
            "  %s --packet <value> [--x <0|1>] [--y <0|1>]\n"
            "  %s --compare <file>\n",
            program,
            program,
            program,
            program);
}

int main(int argc, char **argv)
{
    if (argc == 2 && strcmp(argv[1], "--self-test") == 0)
    {
        return run_self_test();
    }

    if (argc == 2 && strcmp(argv[1], "--sweep") == 0)
    {
        print_sweep();
        return 0;
    }

    if (argc >= 3 && strcmp(argv[1], "--compare") == 0)
    {
        return compare_file(argv[2]);
    }

    if (argc >= 3 && strcmp(argv[1], "--packet") == 0)
    {
        uint8_t packet;
        uint8_t x = 0;
        uint8_t y = 0;

        if (parse_u8(argv[2], &packet) != 0)
        {
            fprintf(stderr, "Invalid packet value: %s\n", argv[2]);
            return 1;
        }

        for (int index = 3; index < argc; ++index)
        {
            if (strcmp(argv[index], "--x") == 0 && index + 1 < argc)
            {
                if (parse_u8(argv[++index], &x) != 0 || x > 1)
                {
                    fprintf(stderr, "Invalid x value\n");
                    return 1;
                }
            }
            else if (strcmp(argv[index], "--y") == 0 && index + 1 < argc)
            {
                if (parse_u8(argv[++index], &y) != 0 || y > 1)
                {
                    fprintf(stderr, "Invalid y value\n");
                    return 1;
                }
            }
            else
            {
                usage(argv[0]);
                return 1;
            }
        }

        return print_packet_route(x, y, packet);
    }

    usage(argv[0]);
    return 1;
}