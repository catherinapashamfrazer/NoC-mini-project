# Routing Analysis

This project currently implements a deterministic, dimension-order style route selection in [Design/2(Routing_logic).v](Design/2(Routing_logic).v). The router inspects the destination field and chooses a single next hop before forwarding packets through [Design/3(Router).v](Design/3(Router).v) and [Design/5(NoC_top).v](Design/5(NoC_top).v).

## Basic XY routing

Basic XY routing always resolves the X coordinate first and only then resolves Y. In practice, that means a packet moves horizontally until it reaches the correct column, then vertically until it reaches the destination row.

### Strengths

- Very small hardware cost.
- Easy to verify and reason about.
- Deterministic path selection, so debugging is straightforward.
- Naturally avoids many routing ambiguities because every packet follows the same rule.

### Limits

- No congestion awareness.
- No alternate path when one link is busy.
- Can create hotspots if many packets share the same shortest path.
- Latency depends heavily on traffic pattern, not just distance.

## Simple advanced routing ideas

These are modest extensions that are still simple enough for a small NoC.

### 1. Turn-model routing

Turn-model schemes forbid certain direction changes to guarantee deadlock freedom while allowing more than one legal route. Examples include west-first, north-last, and odd-even style rules.

### 2. Congestion-aware adaptive routing

The router keeps more than one legal output and picks the least congested one using local fullness or credit information. This can reduce contention but needs extra control logic and link-state visibility.

### 3. Minimal adaptive routing

The router chooses among only the shortest paths that still reduce Manhattan distance. This keeps paths efficient while allowing limited flexibility around busy links.

### 4. Randomized tie-breaking

When two shortest directions are equally valid, the router picks one pseudorandomly. This is cheap and can spread load better than fixed tie-breaking, but it is less deterministic.

## Comparison summary

| Approach | Path choice | Hardware cost | Congestion handling | Determinism |
| --- | --- | --- | --- | --- |
| Basic XY | One fixed shortest path | Low | None | High |
| Turn-model | Several legal shortest paths | Low to medium | Limited | Medium |
| Congestion-aware adaptive | Multiple candidate paths | Medium to high | Good | Medium |
| Randomized tie-break | Shortest path with random choice | Low | Light | Low to medium |

## What this means for the current design

The current code is closest to strict XY routing: the destination bits are decoded into a single route decision, and the top-level logic forwards packets based on that fixed next hop. That makes the design compact and easy to test, but it does not yet exploit any of the simple advanced ideas above.

If the goal is to improve performance later, the smallest useful step would be to add one extra legal direction choice at each hop and use a local congestion signal to break ties. That would keep the design understandable while moving it beyond pure XY routing.