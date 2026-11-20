# Troubleshooting

Real bugs hit during development, and how they were fixed.

---

## GitHub API returns 422 on file update

**Symptom:** Commit node fails with `422 Unprocessable Entity` when trying to update an existing file.

**Cause:** GitHub's API requires the current file `sha` when overwriting an existing file. Without it, the API assumes you're trying to create a file that already exists.

**Fix:** Add a `GET` request before every `PUT` to fetch the current sha:
```js
// GET the file first
const fileResp = await fetch('https://api.github.com/repos/.../contents/' + path, ...);
const sha = fileResp.json().sha || undefined;

// Then PUT with sha
body: { message, content, sha }  // sha || undefined creates on first run, updates on subsequent
```

---

## n8n `$input.all()` with positional indexing breaks on merge nodes

**Symptom:** `$input.all()[0]` returns unexpected data or throws after a Merge node.

**Cause:** n8n's merge node passes items from multiple upstream nodes. Positional indexing assumes a specific order that isn't guaranteed.

**Fix:** Always read upstream nodes by name:
```js
// Wrong
const tier1 = $input.all()[0].json;

// Correct
const tier1 = $('Tier 1 - Core Application').first().json;
```

---

## Groq rate limit: 6000 TPM exceeded

**Symptom:** `The service is receiving too many requests` on T2, T3, or T4 nodes.

**Cause:** Multiple Groq calls fired back-to-back exhaust the 6000 tokens-per-minute limit.

**Fix:** Add 30-second Wait nodes between consecutive Groq calls. The follow-up scheduler also splits by follow-up type across 4 triggers (9:00/9:30/10:00/10:30) so each run only processes ~5 items instead of 20+.

---

## CORS error when calling webhook from local file

**Symptom:** `Access to fetch blocked by CORS policy` when opening `index.html` via `file://`.

**Cause:** Browsers block cross-origin requests from `file://` origins. n8n's default config doesn't include CORS headers.

**Fix 1:** Add `N8N_CORS_ALLOWED_ORIGINS=*` to `docker-compose.yml` environment.  
**Fix 2:** Serve the HTML via a local server (VS Code Live Server, `python -m http.server`).

---

## n8n Webhook node rejects request: "responseMode is not valid"

**Symptom:** Webhook returns `{"code":0,"message":"The response mode 'immediatelyAfter' is not valid!"}`.

**Cause:** `immediatelyAfter` is not a valid `responseMode` value in this version of n8n.

**Fix:** Remove the `responseMode` parameter entirely from the Webhook node, n8n uses `lastNode` by default.

---

## `$('Job Form')` throws when triggered via webhook

**Symptom:** `Cannot assign to read only property 'name' of object 'Error: Node 'Job Form' hasn't been executed'`

**Cause:** Code node references `$('Job Form')` as a fallback, but n8n throws (not returns null) when referencing a node that didn't run in this execution path.

**Fix:** Remove the `|| $('Job Form').first().json['Job Description']` fallback. The `Job Input` Set node normalizes field names from both trigger sources, downstream nodes only need to read `$('Job Input')`.

---

## Follow-up scheduler generates all types instead of filtering

**Symptom:** Scheduler sends day_3, day_7, day_30, and day_90 emails for every company instead of just today's type.

**Cause:** `Parse Follow-Up Dates` had a `// TEMP TEST` comment that bypassed the `=== today` date filter.

**Fix:** Restore the date filter. Add time-based type filter:
```js
const now = new Date();
const hour = now.getHours();
const minute = now.getMinutes();
let typeFilter = null;
if (hour === 9 && minute < 30)  typeFilter = 'day_3';
else if (hour === 9)             typeFilter = 'day_7';
else if (hour === 10 && minute < 30) typeFilter = 'day_30';
else if (hour === 10)            typeFilter = 'day_90';
if (typeFilter) followupsNeeded = followupsNeeded.filter(f => f.followup_type === typeFilter);
```

---

## Gmail Auto-Labeler: false `REPLIED` on first recruiter outreach

**Symptom:** First email sent to a recruiter gets labeled `REPLIED` instead of `WAITING FOR RESPONSE`.

**Cause:** The `isReply` detection was checking whether the thread already had a job-search label. Since the thread already had `FROM_RECRUITER` from an earlier incoming message, the outgoing first-contact email was misidentified as a reply to an existing thread.

**Fix:** Use subject `Re:` prefix only for `isReply` detection on outgoing emails:
```js
// Wrong, thread labels cause false positives
const isReply = threadHasJobLabel;

// Correct, only trust the subject prefix for outgoing emails
const isReply = subject.startsWith('re:');
```

---

## Gmail API: case-sensitive field names cause silent failures

**Symptom:** Email classification produces wrong results, `from`, `to`, `subject` fields read as empty even when the email has them.

**Cause:** Gmail API returns `From`, `To`, `Subject` with capital letters, and `labels` as an array of `{id, name}` objects, not `labelIds`. Code expecting lowercase keys or a flat `labelIds` array silently gets `undefined`.

**Fix:** Always use capital field names and map the labels array:
```js
const from = item.From || '';           // capital F
const to = item.To || '';               // capital T
const labelIds = (item.labels || []).map(l => l.id);  // not item.labelIds
```

---

## Gmail Auto-Labeler: switching to thread resource breaks downstream nodes

**Symptom:** Nodes after the Gmail node stop receiving data or throw ID-related errors after switching from message to thread fetch mode.

**Cause:** The Gmail node's thread resource returns a different ID format than the message resource. Downstream nodes (Clear All, Apply Label) were built expecting message IDs, thread IDs are not interchangeable.

**Fix:** Keep fetching by message, then deduplicate by `threadId` in the `Fix Logic` Code node. Run the node in "Run Once for All Items" mode so `$input.all()` has access to all messages for deduplication in a single pass:
```js
// Fix Logic node, mode: "Run Once for All Items"
const items = $input.all();
// group by threadId, keep newest message per thread
const byThread = {};
for (const item of items) {
  const tid = item.json.threadId;
  if (!byThread[tid] || item.json.internalDate > byThread[tid].json.internalDate) {
    byThread[tid] = item;
  }
}
```

---

## Email Listener: Gmail Trigger fires on emails sent to self (workflow notifications)

**Symptom:** n8n notification emails (sent from your address to your address) get classified as recruiter emails and trigger false notifications.

**Cause:** The Gmail Trigger had no filter to exclude self-sent emails.

**Fix:** Add `-from:your_email@gmail.com` to the Gmail Trigger filter query, and add an explicit check in the Classify Email node:
```js
if (fromEmail === MY_EMAIL && toEmail === MY_EMAIL) {
    return { label: ID_N8N, ... };
}
```

---

## `now is not defined` in Parse Follow-Up Dates

**Symptom:** `ReferenceError: now is not defined` at line where `now.getHours()` is called.

**Cause:** The time-based type filter code referenced `now` before declaring it. `today` was declared at the top of the node as a string (`new Date().toISOString().split('T')[0]`) but `now` as a Date object was never declared.

**Fix:**
```js
const now = new Date();   // add this line before the filter block
const hour = now.getHours();
const minute = now.getMinutes();
```

---

## Render free tier: wait nodes die and scheduled triggers miss their window

**Symptom:** Workflows using Wait nodes complete only the first part and then silently stop. Scheduled triggers (cron) don't fire at their expected time.

**Cause:** Render's free tier puts the container to sleep after ~15 minutes of inactivity. When it wakes up, n8n starts fresh with no execution state. Wait nodes work by saving execution state and resuming later, if the container sleeps between the pause and the resume, that state is gone. Scheduled triggers need a running process to fire, if the container is asleep at 9:00am, the trigger simply doesn't run.

**Why this matters for this project specifically:** The main workflow has 8+ wait nodes (15 to 25 seconds each) spread across the tier chain. The follow-up scheduler has 4 cron triggers. The Gmail labeler runs every 30 minutes. None of these work reliably on a free-tier host that sleeps.

**Fix:** Run n8n locally on Docker (`docker compose up -d`) so the process stays permanently alive as long as the machine is on. The tradeoff is the webhook is only accessible while your laptop is running, which is fine for personal use.

**Correct cloud fix (when needed):** Render paid tier, a DigitalOcean Droplet (~$6/month), or Railway, any host that keeps the container permanently alive without sleep periods.
