#ifndef NOC_GOLDEN_H
#define NOC_GOLDEN_H

#include <stdbool.h>
#include <stdint.h>

typedef enum {
    NOC_ROUTE_LOCAL = 0,
    NOC_ROUTE_WEST  = 1,
    NOC_ROUTE_EAST  = 2,
    NOC_ROUTE_NORTH = 3,
    NOC_ROUTE_SOUTH = 4
} noc_route_t;

typedef struct {
    noc_route_t route;
    bool local_hit;
} noc_route_result_t;

noc_route_result_t noc_route_xy(uint8_t x, uint8_t y, uint8_t dest);
uint8_t noc_packet_dest(uint8_t packet);
noc_route_result_t noc_route_packet(uint8_t x, uint8_t y, uint8_t packet);
const char *noc_route_name(noc_route_t route);

#endif