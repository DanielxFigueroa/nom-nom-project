---
name: nom-nom-github-issue
description: Analyze and build feature based on GitHub issue.
---

# Invoked as: /nom-nom-github-issue <issue\*#>

Please analyze and fix the GitHub issue: $ARGUMENT.

## Behavior

Follow these steps:

### PLAN

1. Use issue_read via github Plugins to get the issue details
2. Understand the problem described in the issue
3. Ask clarifying questions if necessary
4. Understand the prior art for this issue
   - Search the notepads directory for previous thoughts related to the issue
   - Search Pull Requests to see if you can find history on this issue
   - Search the codebase for relevant files
5. Think hard about how to break down the issue into a series of small, managable tasks.
6. Document your plan in a new a notepad
   - Include the issue name in the filename
   - Include a link to the issue in the notepad

### CREATE CODE

- Create a new branch for the issue
- Solve the issue in small, manageable steps, accordiing to your plan
- If the issue involves reading and applying migrations to the supabase database, priortize using the supabase Plugins tools.
- Once all tasks are implemented, create an independent Jest unit test for the new feature
- Commit changes to the GitHub repository, with a clear prefix that Antigravtiy CLI and the model made the commit (e.g. [`AGY:Gemini-3.5-Flash`])

### TEST

- Use chrome-devtools tools or playwright via Plugins to test any changes made to the UI or the frontend
- Run the full test suite to ensure you haven't broken anything.
- If the tests are failing, fix them
- Once you ensure that all tests are passing, move on to the next step.

### DEPLOY

- Open a Pull Request and request a review.

Remember to use GitHub Plugins for all GitHub-related tasks. Remember to use Supabase Plugins for all Supabase-related tasks.
