Thanks for trying out the setup guide and for the great questions! Let me address both issues:

**Issue 1: \"code --version\" not recognized**

This is a common issue that happens when VS Code isn't added to your system PATH during installation. Here's the quick fix:

1. Open VS Code manually (from Start Menu or desktop shortcut)
2. Press `Ctrl+Shift+P` to open the Command Palette
3. Type \"Shell Command: Install 'code' command in PATH\" and select it
4. Restart your terminal/PowerShell and try `code --version` again

That should resolve it!

**Issue 2: entity-etl-service not appearing in GitHub search**

Good catch! The direct link works because you have access to the repository, but it may not appear in search results due to GitHub Enterprise's search indexing settings for that specific repo. This is controlled at the repository or organization level and isn't something we can change.

The good news is the direct link works perfectly, so please continue using the links in the document to access the repositories. I'll make a note to verify all repo names and update the document if needed.

Let me know if you run into any other issues!

Best,
Santosh
