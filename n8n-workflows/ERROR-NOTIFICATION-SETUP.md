# n8n Centralized Error Notification Setup

This workflow automatically sends you an email whenever any n8n workflow fails.

## 📋 What It Does

- **Catches all workflow failures** using the Error Trigger node
- **Extracts detailed error information** (workflow name, failed node, error message, stack trace)
- **Sends a formatted HTML email** with:
  - Workflow and execution details
  - Error message and failed node
  - Full stack trace (collapsible)
  - Quick action buttons to view the workflow and execution in n8n

## 🚀 Setup Instructions

### Step 1: Import the Workflow

1. Open n8n (http://localhost:5678)
2. Click **"Add workflow"** → **"Import from File"**
3. Select: `Centralized Error Notification.json`
4. Click **"Import"**

### Step 2: Configure Email Settings (Already Done)

The workflow is already configured to use your existing SMTP credentials:
- **From/To Email**: golickmybutt@gmail.com
- **SMTP Credentials**: "SMTP account" (ID: DCxuQPQ2OqheCxzi)

✅ **No changes needed** - it uses the same email setup as your Docker Health Monitor

### Step 3: Link to Your Workflows

**IMPORTANT**: You must link this error workflow to each of your existing workflows.

#### Option A: Manual (Recommended for Understanding)

For each workflow you want to monitor:

1. Open the workflow in n8n
2. Click the **workflow name** at the top → **"Workflow settings"**
3. Scroll down to **"Error Workflow"**
4. Select **"Centralized Error Notification"** from the dropdown
5. Click **"Save"**

#### Option B: Automatic (Using n8n API)

Create a helper workflow that automatically links all workflows:

```bash
# This would require n8n API credentials with workflows.read and workflows.update permissions
# See the centralized error management template for implementation
```

### Step 4: Activate the Error Workflow

**IMPORTANT**: Unlike normal workflows, you DO NOT need to activate this workflow manually.

The Error Trigger workflow will:
- ✅ Automatically activate when you save it
- ✅ Run automatically when any linked workflow fails
- ✅ Not appear in the "Active workflows" list (this is normal)

## 📊 What the Email Looks Like

When a workflow fails, you'll receive an email with:

```
❌ n8n Workflow Failed: [Workflow Name]

📋 Workflow Information
┌─────────────────┬──────────────────────────┐
│ Workflow        │ Docker Health Monitor    │
│ Workflow ID     │ XjNG1PhI6t5MdwS1        │
│ Execution ID    │ 12345                    │
│ Execution Mode  │ trigger                  │
│ Time            │ 01/13/2026, 02:15:30 PM  │
└─────────────────┴──────────────────────────┘

🚨 Error Details
┌─────────────────┬──────────────────────────┐
│ Failed Node     │ SSH - Run Monitor Script │
│ Error Message   │ Connection timeout       │
└─────────────────┴──────────────────────────┘

📄 Stack Trace (click to expand)
[Full error stack trace]

🔧 Quick Actions
[View Workflow] [View Execution]
```

## 🔗 Workflows to Link

Link this error workflow to:

- ✅ **Docker Health Monitor** - Your health monitoring workflow
- ✅ **Gitea Daily Backup** - Your Gitea backup workflow
- ✅ **Karakeep Daily Backup** - Your Karakeep backup workflow
- ✅ **Budget Export - Main** - Your main budget export
- ✅ **Budget Export - GF** - Your GF budget export
- ✅ **Youtube Aggregator** - Your YouTube RSS workflow
- ✅ **News Aggregator** - Your news RSS workflow
- ✅ **SPYI & QQQI 19a Downloader** - Your SEC filing downloader
- ✅ **Karakeep Daily Podcast Generation** - Your podcast generator
- ✅ **Karakeep Bookmark Cleanup** - Your bookmark cleanup
- ✅ **Obsidian Monthly Summary Generator** - Your monthly summary generator

## 🧪 Testing

To test if it's working:

1. Create a simple test workflow with an intentional error
2. Link this error workflow to it
3. Run the test workflow
4. Check your email for the error notification

**Test Workflow Example:**
```
Trigger (Manual) → HTTP Request (to invalid URL) → Should Fail
```

## 🛠️ Customization

### Change Email Recipient

Edit the **"Send Error Email"** node:
- Change `toEmail` to your desired email address

### Change Email Format

Edit the **"Format Error Details"** node:
- Modify the HTML in the `html` variable
- Add/remove information fields
- Change colors, fonts, or layout

### Add Additional Notifications

Add more nodes after "Format Error Details":
- Slack notification
- Discord webhook
- SMS via Twilio
- PagerDuty alert

## 📝 Error Data Available

The Error Trigger provides this data:

```javascript
{
  "workflow": {
    "id": "workflow-id",
    "name": "Workflow Name"
  },
  "execution": {
    "id": "execution-id",
    "mode": "trigger", // or "manual"
  },
  "node": {
    "name": "Failed Node Name",
    "type": "n8n-nodes-base.httpRequest"
  },
  "error": {
    "message": "Error message",
    "stack": "Full stack trace"
  }
}
```

## 🔍 Troubleshooting

### Not Receiving Emails

1. **Check if workflows are linked**:
   - Open each workflow → Settings → Error Workflow should show "Centralized Error Notification"

2. **Check email credentials**:
   - Open the workflow → Click "Send Error Email" node
   - Verify SMTP credentials are configured

3. **Test email manually**:
   - Open the workflow
   - Click "Execute Workflow"
   - You should receive a test email (will show as execution mode: "manual")

### Error Workflow Not Triggering

- Error workflows DON'T need to be activated manually
- They activate automatically when linked to another workflow
- They only trigger when a linked workflow actually fails

### Quick Action Links Don't Work

- Update the base URL in "Format Error Details" node
- Change `http://localhost:5678` to your actual n8n URL
- For remote access: `http://your-ip:5678` or your domain

## 📚 Additional Resources

- [n8n Error Workflows Documentation](https://blog.n8n.io/creating-error-workflows-in-n8n/)
- [Centralized Error Management Template](https://n8n.io/workflows/4519-centralized-n8n-error-management-system-with-automated-email-alerts-via-gmail/)
- [Error Trigger Node Docs](https://docs.n8n.io/integrations/builtin/core-nodes/n8n-nodes-base.errortrigger/)

## 💡 Best Practices

1. **Link to all production workflows** - Don't skip test workflows
2. **Monitor your email** - Set up a filter/label for n8n errors
3. **Fix errors promptly** - Don't let them pile up
4. **Review patterns** - If the same workflow keeps failing, investigate root cause
5. **Keep this workflow simple** - Don't add complex logic that could fail itself

## 🎯 Next Steps

After setup, you should:
1. ✅ Import the workflow
2. ✅ Link it to all your existing workflows
3. ✅ Test with a dummy failing workflow
4. ✅ Create email filter/label for "n8n Workflow Failed"
5. ✅ Document which workflows are critical vs nice-to-have
