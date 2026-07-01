#include "noc_golden.h"

#include <stddef.h>

noc_route_result_t noc_route_xy(uint8_t x, uint8_t y, uint8_t dest)
{
    noc_route_result_t result;

    result.route = NOC_ROUTE_LOCAL;
    result.local_hit = false;

    if (dest == ((y << 1) | x))
    {
        result.local_hit = true;
    }
    else if ((dest & 1u) > (x & 1u))
    {
        result.route = NOC_ROUTE_EAST;
    }
    else if ((dest & 1u) < (x & 1u))
    {
        result.route = NOC_ROUTE_WEST;
    }
    else if (((dest >> 1) & 1u) > (y & 1u))
    {
        result.route = NOC_ROUTE_SOUTH;
    }
    else
    {
        result.route = NOC_ROUTE_NORTH;
    }

    return result;
}

uint8_t noc_packet_dest(uint8_t packet)
{
    return (uint8_t)((packet >> 6) & 0x3u);
}

noc_route_result_t noc_route_packet(uint8_t x, uint8_t y, uint8_t packet)
{
    return noc_route_xy(x, y, noc_packet_dest(packet));
}

const char *noc_route_name(noc_route_t route)
{
    switch (route)
    {
        case NOC_ROUTE_LOCAL: return "LOCAL";
        case NOC_ROUTE_WEST:  return "WEST";
        case NOC_ROUTE_EAST:  return "EAST";
        case NOC_ROUTE_NORTH: return "NORTH";
        case NOC_ROUTE_SOUTH: return "SOUTH";
        default:               return "UNKNOWN";
    }
}