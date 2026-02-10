# Salesforce Support Case Update – Finalizing Error

**Use this text when replying to your case about the Metadata API deploy failure.**

---

**Subject:** Update to case – deploy fails in both production and sandbox (same error)

---

**Message:**

Update to our case about: "Metadata API request failed: Missing message metadata.transfer:Finalizing for locale en_US."

We have confirmed the following:

• The same error occurs when deploying to our PRODUCTION org and to our SANDBOX org. So this is not specific to one org.

• We cannot complete any deployment via Salesforce CLI (sf project deploy start) to either org. Components and tests succeed; the failure happens at the finalization step every time.

• We tried deploying with SF_USE_METADATA_REST_API=true; the CLI still reported using the SOAP API and the same error occurred.

• We have no translation metadata in our project, and our org does not have the Translations entity available. Encoding is standard.

We are blocked from deploying our fixes (including critical Apex changes) to both production and sandbox. We need to use Change Sets or manual editing as workarounds until this is fixed.

Please escalate or have the platform team add or fix the missing metadata.transfer:Finalizing message for locale en_US so that Metadata API deployments can complete in our orgs.

Reference deploy IDs:
• Production: 0AfPC0000024oQ50AI (example)
• Sandbox (NWFBSandbox): 0AfO500000YzfViKAJ
