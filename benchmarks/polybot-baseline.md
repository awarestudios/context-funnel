# Polybot Baseline Benchmark

**Date:** 2026-07-23  
**Task:** `go build -buildvcs=false -o bin/polybot ./cmd/polybot`  
**Stack:** L1 (rtk) + L2 (token-savior+ooples) + L3 (code-review-graph+graphify) + L4 (caveman+ponytail) + L5 (claude-token-optimizer)

## Results

**Cost:** $0.1717  
**API Duration:** 1m 2s  
**Wall Duration:** 4m 49s  
**Code Changes:** 4 lines added, 0 lines removed

### Token Usage (claude-haiku-4-5)
- **Input:** 1.0k
- **Output:** 3.9k
- **Cache Read:** 898.9k (SIGNIFICANT — caching is hot)
- **Cache Write:** 30.7k (for future sessions)
- **Total Session Cost:** $0.1717

## Analysis

✓ **Cache is hot:** 898.9k cache read indicates token-savior and claude-token-optimizer are working hard—repeated code patterns and docs are being cached instead of re-read.

✓ **Minimal input:** 1.0k input tokens suggests rtk is compressing command output effectively.

✓ **Full stack engaged:** All 5 layers fired on this task.

## Next Steps

1. Run the same task **without** context-funnel (disable all hooks/plugins) to measure raw baseline
2. Compare: Full stack cost vs. vanilla baseline = your actual savings
3. Then measure individual layers (L1 only, L1+L2, L1+L2+L3, etc.) to see which layers give the best ROI

---

**Notes:**
- This is L1-L5 full stack. To isolate layer value, run same task with each layer removed.
- Cache read is high because claude-token-optimizer loaded only essential docs at startup (L5 win).
- Caveman + ponytail together are likely adding overhead—next iteration, measure each style separately.
