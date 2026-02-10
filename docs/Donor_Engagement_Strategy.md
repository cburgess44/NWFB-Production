# NWFB Donor Engagement Strategy

*Working Document - February 2026*

---

## Donor Segmentation (Buckets)

| Bucket | Definition | Goal |
|--------|------------|------|
| **Standard** | 1-5 gifts, unsolicited | Convert to Repeater |
| **Repeaters** | 5+ gifts, irregular | Convert to Recurring |
| **Recurring** | Active recurring gift | Upgrade amount |
| **Major** | $X,XXX+ cumulative or single | Steward, retain |
| **Prospects** | Known, haven't given yet | First gift |
| **Whales** | Potential major (foundations, estates) | Cultivate |

---

## Data Capture - Questions to Answer

| Source | Currently in SF? | How? |
|--------|-----------------|------|
| Website donations | ? | Classy/Stripe/? → SF |
| Event donations | ? | Manual/Platform? |
| Mail-in checks | ? | Manual entry? |
| Foundation grants | ? | ? |
| In-kind gifts | ? | ? |

### Key Questions:
- Are donations made via Website being populated in SF?
- Donations made outside of website - how are these contacts and donations getting into SF?

---

## Response Tiers (Draft)

| Gift Level | Response | Who | When |
|------------|----------|-----|------|
| < $100 | Auto email + annual thank you | System/Lane | Immediate |
| $100-499 | Personal email | Lane/Matt | 48 hrs |
| $500-999 | Phone call | Matt/Jeremy | 1 week |
| $1,000+ | Handwritten note + call | Jeremy | 48 hrs |
| $5,000+ | Visit + board acknowledgment | Jeremy + Board | ASAP |

### Questions:
- What is the level of response and by whom?
- Is there a tier level of response?
- Who is engaging here (Lane, Matt, Jeremy...?)

---

## Giving Patterns to Track

- **Random** - unsolicited gifts
- **Targeted campaigns** - response to specific asks
- **Event related** - galas, fundraisers, etc.

---

## The Objective

> Get them to give again, hopefully with increasing $ as they can. Respond to all.

---

## What Salesforce Can Do

1. **Auto-segment donors** with formula fields or flows based on giving history
2. **Auto-create tasks** when donation comes in (right person, right tier)
3. **Track all touchpoints** (Contact Reports we built)
4. **Dashboard by segment** showing who needs attention
5. **Campaign tracking** to see which asks convert

---

## Types of Donors (High Level)

- **Those we know** - existing Contacts in Salesforce
- **Those we don't know yet** - prospects, event attendees, website visitors

---

## Next Steps

- [ ] Answer data capture questions above
- [ ] Confirm response tier thresholds and assignments
- [ ] Define major donor threshold ($1K? $5K?)
- [ ] Identify donation platforms in use
- [ ] Build Salesforce automation to support tiers

---

## Technical Implementation (Completed in Sandbox)

- ✅ Contact_Report__c object (9 custom fields)
- ✅ Log Contact Report flow
- ✅ Auto-update Contact on new report
- ✅ Log Contact quick action
- ✅ Fundraiser permission set
- ✅ Contact Reports tab & report type
- ✅ Needs_Outreach__c formula field
- ⏳ Reports & Dashboard (in progress)
- ⏳ Donor segmentation fields (to build)
- ⏳ Auto-task creation on donation (to build)
