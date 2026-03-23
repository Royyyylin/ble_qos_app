# Fix 6 Known Issues Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Fix 6 known issues found during device verification — STATUS polling, RSSI updates, scanner restart, roster deduplication, HA pair display, and throughput N/A display.
**Bounded Context(s):** BLE Transport, Telemetry Metrics, Fleet Overview, Device Roster, HA Monitoring
**Architecture:** Infrastructure layer (metrics polling), Application layer (roster filtering), Presentation layer (dashboard/HA/scanner UI). Changes touch providers and UI widgets — no domain model changes needed.
**Tech Stack:** Flutter, Riverpod, flutter_blue_plus, GATT
**Domain Model:** docs/architecture/APP_ARCHITECTURE.md
**Research Brief:** N/A
**Assumptions:**
- Issue #2 (RSSI 1s update) is already working correctly — EMA smoothing is expected behavior
- HA error state = "no HA pair configured" (single GW without HA pairing)
- tpBps=0 means non-TP mode (firmware doesn't fill throughput field)
- GoRouter is used with MaterialApp.router (for RouteObserver registration)

**Propagation Checklist:**
- [x] Files sharing STATUS polling pattern: `metrics_provider.dart` (statusStreamProvider, deviceInfoProvider already polls)
- [x] Config keys affected: none
- [x] Subprocess callers that need update: `ed_roster_provider.dart` still reads edStatusMap from indexed notify (unchanged)

**EDIT_BLOCK Validation:**
- [x] Every ANCHOR verified unique in target file (post prior edits)
- [x] Cross-task anchor dependencies noted (Section 3 depends on Section 1)
- [x] CREATE_FILE provides complete file content (N/A — no new files)
- [x] REPLACE anchors include ALL lines being removed
- [x] No EDIT_BLOCK relies on nearest-match or semantic search

---

## Issue → Task Mapping

| Issue | Description | Section | Tasks |
|-------|------------|---------|-------|
| #1 | Dashboard STATUS polling every 2s | Section 1 | 1-2 |
| #2 | Fleet Overview RSSI 1s update | Section 4 | 10 (verified as working) |
| #3 | Scanner restart scan on return | Section 4 | 8-9 |
| #4 | Roster filter out EDs already in roster | Section 2 | 3-4 |
| #5 | HA show 'No HA pair' instead of waiting | Section 3 | 7 |
| #6 | Throughput show N/A when tpBps=0 | Section 3 | 5-6 |

## Layer 1: Domain

No domain model changes needed.

## Layer 2: Application

### Task 3: Add Test for Discovered ED Filtering
See: `sections/section-02-roster-filter.md`

### Task 4: Filter Discovered EDs Already in Firmware Roster
See: `sections/section-02-roster-filter.md`

## Layer 3: Infrastructure

### Task 1: Add STATUS Polling Stream Provider
See: `sections/section-01-status-polling.md`

### Task 2: Keep edStatusMap Notify Subscription Active
See: `sections/section-01-status-polling.md`

## Layer 4: Presentation

### Task 5: Add Throughput N/A Test
See: `sections/section-03-presentation-dashboard-ha.md`

### Task 6: Fix Throughput to Show N/A When tpBps=0
See: `sections/section-03-presentation-dashboard-ha.md`

### Task 7: HA Tab Shows 'No HA Pair' Instead of Waiting Forever
See: `sections/section-03-presentation-dashboard-ha.md`

### Task 8: Add RouteAware Mixin for Scan Lifecycle
See: `sections/section-04-scanner-lifecycle.md`

### Task 9: Register RouteObserver in App Navigation
See: `sections/section-04-scanner-lifecycle.md`

### Task 10: Verify RSSI Update Frequency (Issue #2)
See: `sections/section-04-scanner-lifecycle.md`

---

## Execution Order

Sections 1, 2, and 4 can run in parallel. Section 3 depends on Section 1.

```
Section 1 (STATUS polling) ──→ Section 3 (Dashboard/HA UI)
Section 2 (Roster filter)  ──→ (independent)
Section 4 (Scanner lifecycle) → (independent)
```
