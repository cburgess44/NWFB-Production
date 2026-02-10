# NWFB Production: Deploy & Improvement Checklist

Step-by-step with checkboxes. Work in order; check off each item as you complete it.

---

## Requirement: Salesforce CLI version

**Use Salesforce CLI 2.101.5 or later.** Older versions fail at deploy finalization with:  
`Missing message metadata.transfer:Finalizing for locale en_US`  
Check version: `sf version`. Upgrade: `sf update`.

---

## Phase 1: Get the test suite green

Do this first. Don’t move to Phase 2 until all tests pass.

### 1.1 – Run the full test suite

- [x] Open terminal and go to project folder:
  ```bash
  cd "/Users/christopherburgess/NWFB Production/NWFB-Production"
  ```
- [x] Run all tests (use `nwfb-prod` or `NWFBSandbox`):
  ```bash
  sf apex run test --test-level RunLocalTests --target-org nwfb-prod --result-format human --wait 15
  ```
- [x] Wait for the run to finish and note the result: **Passing: 164 | Failing: 22 | Total: 186**

### 1.2 – If any tests failed: log them

- [x] In the output, find the **"Test Failures"** section.
- [x] Copy each failing test into the table below (or your own list).

**Failure log (edit this as you fix):**

| # | Test Class | Test Method | Error (short) | Fixed? |
|---|------------|-------------|---------------|--------|
| 1 | AR_OverdueServicesControllerTest | setupTestData | Service Duplicate Address Detection – Too many SOQL: 101 | [ ] |
| 2 | AR_OverdueServicesControllerTest | testAgingClassAssignment | (same – setupTestData) | [ ] |
| 3 | AR_OverdueServicesControllerTest | testDateFallbackLogic | (same) | [ ] |
| 4 | AR_OverdueServicesControllerTest | testDateFallbackToCreatedDate | (same) | [ ] |
| 5 | AR_OverdueServicesControllerTest | testDifferentAgingBuckets | (same) | [ ] |
| 6 | AR_OverdueServicesControllerTest | testEmailTemplateWrapper | (same) | [ ] |
| 7 | AR_OverdueServicesControllerTest | testGetEmailTemplates | (same) | [ ] |
| 8 | AR_OverdueServicesControllerTest | testGetOverdueServices | (same) | [ ] |
| 9 | AR_OverdueServicesControllerTest | testLogCollectionCall | (same) | [ ] |
| 10 | AR_OverdueServicesControllerTest | testMultipleCollectionCalls | (same) | [ ] |
| 11 | AR_OverdueServicesControllerTest | testRecordFullPayment | (same) | [ ] |
| 12 | AR_OverdueServicesControllerTest | testRecordPayment | (same) | [ ] |
| 13 | AR_OverdueServicesControllerTest | testSendAgencySummaryEmail | (same) | [ ] |
| 14 | AR_OverdueServicesControllerTest | testSendAgencySummaryEmailNoContact | (same) | [ ] |
| 15 | AR_OverdueServicesControllerTest | testSendAgencySummaryEmailNoServices | (same) | [ ] |
| 16 | AR_OverdueServicesControllerTest | testServiceRenderedDateTakesPriority | (same) | [ ] |
| 17 | AR_OverdueServicesControllerTest | testServiceWrapperFields | (same) | [ ] |
| 18 | AR_OverdueServicesControllerTest | testUpdateCollectionsStatus | (same) | [ ] |
| 19 | AR_OverdueServicesControllerTest | testUpdateCollectionsStatusNoNotes | (same) | [ ] |
| 20 | AR_OverdueServicesControllerTest | testWriteOffBalance | (same) | [ ] |
| 21 | AR_OverdueServicesControllerTest | testWriteOffPartialBalance | (same) | [ ] |
| 22 | AR_OverdueServicesControllerTest | testWriteOffWithExistingPaid | (same) | [ ] |

**Why they fail:** The **Service Duplicate Address Detection** flow is still **Active in production**. When tests insert Service__c records, that flow runs and hits the 101 SOQL limit. Your local project has the flow set to Inactive and Apex duplicate detection, but that hasn’t been deployed yet.

### 1.3 – Fix or bypass the failures

**For this run:** All 22 failures were from the **Service Duplicate Address Detection** flow still being Active in the org. Fastest fix:

- [x] In **production** (nwfb-prod): **Setup → Flows →** open **Service Duplicate Address Detection** → **Deactivate** (or set status to Inactive). That stops the flow from running when tests insert Service__c, so tests can pass.
- [x] Re-run the full suite:
  ```bash
  sf apex run test --test-level RunLocalTests --target-org nwfb-prod --result-format human --wait 15
  ```
- [x] Confirm **Failing: 0**. Then continue to Phase 2 (deploy). The deploy will push the Apex duplicate detection and the flow metadata as **Inactive**, so duplicate detection keeps working and the flow stays off.

(If you prefer to fix in code instead: add a test-only bypass so the flow doesn’t run in test context; that requires a deployable change and may still need the flow off in the org first to get tests green.)

### 1.4 – Phase 1 complete

- [x] Full test run shows **Failing: 0** (all tests pass).

---

## Phase 2: Deploy to production

Only start Phase 2 when Phase 1 is complete (all tests pass).

### 2.1 – Confirm what you’re deploying

- [x] List what’s in this release (e.g. SMS → most recent Service, Duplicate address in Apex, flow deactivated).
- [x] Optional: add a one-line note in **Changelog** below.

### 2.2 – Deploy

- [x] Run deploy (full or specific components). **Requires CLI 2.101.5+** (see top of doc).
- [x] Deploy to prod: `sf project deploy start --metadata "ApexClass:TaskDao" --metadata "ApexClass:ServiceSelector" --metadata "ApexClass:ServiceDao" --target-org nwfb-prod`
- [x] Deploy to sandbox (optional, for sync): same command with `--target-org NWFBSandbox`
- [x] Deploy completed successfully.

### 2.3 – Verify in production

- [x] Spot-check: new SMS links to the correct (most recent) Service.
- [x] Spot-check: new Client Request at same address gets duplicate flag when expected.
- [x] Mark this release as shipped (e.g. check off in Backlog below).

### 2.4 – Phase 2 complete

- [x] Code is in production and verified.

---

## Phase 3: Definition of “done” (for future work)

From now on, an improvement is **done** only when:

- [ ] Code/metadata is implemented and committed.
- [ ] Full test suite passes (same command as 1.1).
- [ ] It’s deployed to production (or explicitly moved to Backlog with a reason).

If tests are still failing or it’s not deployed, keep it in **In progress** or **Backlog**, not Done.

---

## Phase 4: Backlog (what to work on)

Keep one list. Update the checkboxes and notes as you go.

### To deploy (ready once tests are green)

- [x] SMS links to most recent Service (TaskDao + ServiceSelector)
- [x] Duplicate address detection in Apex + flow deactivated (ServiceDao + ServiceSelector + Flow)

### In progress

- [x] Get test suite green (Phase 1)

### Backlog (later)

- [ ] Update Last Contact on related Service – optimize or add test bypass if needed
- [ ] ___________________________________________
- [ ] ___________________________________________

---

## Changelog (optional)

| Date | What shipped |
|------|----------------|
| Feb 2026 | SMS → most recent Service (TaskDao, ServiceSelector); Duplicate address detection in Apex (ServiceDao). Flow remains off in prod. **CLI 2.101.5+ required for deploy.** |
| | |

---

## Quick reference commands

| Goal | Command |
|------|--------|
| **Check CLI version (need 2.101.5+)** | `sf version` |
| **Upgrade CLI** | `sf update` |
| Run all tests | `sf apex run test --test-level RunLocalTests --target-org nwfb-prod --result-format human --wait 15` |
| Run tests (save JSON) | `sf apex run test --test-level RunLocalTests --target-org nwfb-prod --result-format json --output-dir ./test-results --wait 15` |
| Run one test class | `sf apex run test --tests AR_OverdueServicesControllerTest --target-org nwfb-prod --result-format human --wait 5` |
| Deploy everything | `sf project deploy start --source-dir force-app/main/default --target-org nwfb-prod` |
| List orgs | `sf org list` |

---

**Order to work:** Phase 1 (all checkboxes) → Phase 2 (all checkboxes) → use Phase 3 + Phase 4 for every future improvement.
