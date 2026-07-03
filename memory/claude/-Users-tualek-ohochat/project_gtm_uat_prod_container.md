---
name: project-gtm-uat-prod-container
description: "oho-web-app GTM plugin loads the production GTM container for both production and UAT environments — this is intentional, not a bug"
metadata: 
  node_type: memory
  type: project
  originSessionId: 61574a4f-6f4e-413c-8a63-4ed24fc9c31d
---

In `oho-web-app/plugins/gtm.js`, UAT environment loads the **production** GTM container (the `if (env == "production" || env == "uat")` branch). The previous UAT-only container/auth was removed.

**Why:** Analytics owner approved sharing the prod container with UAT. They filter UAT vs prod traffic by **domain** inside GTM, so a separate container is unnecessary.

**How to apply:** Do not flag this as an issue in future reviews. If someone proposes splitting UAT back out into its own container, surface this prior decision before agreeing.
