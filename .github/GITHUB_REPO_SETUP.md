# GitHub Repository Setup

**You need to create a GitHub repository to use the issue tracking system**

---

## Quick Setup Steps

### Step 1: Create GitHub Repository

1. **Go to GitHub:** https://github.com
2. **Sign in** (or create account if needed)
3. **Click "+" in top right** → "New repository"
4. **Configure repository:**
   - **Repository name:** `personal-ai-ios` (or your preferred name)
   - **Description:** "Context-aware thought capture and intelligent organization system for iOS"
   - **Visibility:**
     - **Private** (recommended for now) - Only you can see it
     - **Public** - Anyone can see it (good if you want community contributions)
   - **Initialize repository:**
     - ❌ **DO NOT** check "Add a README file"
     - ❌ **DO NOT** check "Add .gitignore"
     - ❌ **DO NOT** choose a license yet
   - Click **"Create repository"**

### Step 2: Connect Your Local Repository

GitHub will show you instructions. Use the **"push an existing repository"** option:

```bash
# Add GitHub as remote origin
git remote add origin https://github.com/YOUR_USERNAME/personal-ai-ios.git

# Rename branch to main (if needed - GitHub's new default)
git branch -M main

# Push everything to GitHub
git push -u origin main
```

**Replace `YOUR_USERNAME` with your GitHub username!**

### Step 3: Verify Upload

1. Refresh your GitHub repository page
2. You should see all your files:
   - `.github/` folder with issue templates
   - `docs/` folder with documentation
   - `CHANGELOG.md`
   - `README.md`
   - And all your source code

### Step 4: Test Issue Templates

1. Go to your repo on GitHub
2. Click **"Issues"** tab
3. Click **"New issue"**
4. You should see three template options:
   - 🐛 Bug Report
   - ✨ Feature Request
   - ❓ Support Question

If you see them, templates are working! ✅

---

## Using SSH Instead of HTTPS (Optional, More Secure)

If you want to use SSH keys (recommended for security):

### Check if you have SSH key

```bash
ls -la ~/.ssh
# Look for id_ed25519.pub or id_rsa.pub
```

### Generate SSH key (if needed)

```bash
ssh-keygen -t ed25519 -C "your_email@example.com"
# Press Enter for default location
# Set a passphrase (or leave blank)
```

### Add SSH key to GitHub

```bash
# Copy your public key
cat ~/.ssh/id_ed25519.pub | pbcopy
# (Key is now in your clipboard)
```

1. Go to GitHub → Settings → SSH and GPG keys
2. Click "New SSH key"
3. Paste your key
4. Save

### Use SSH remote URL

```bash
# If you already added HTTPS remote, change it:
git remote set-url origin git@github.com:YOUR_USERNAME/personal-ai-ios.git

# Or add it fresh:
git remote add origin git@github.com:YOUR_USERNAME/personal-ai-ios.git

# Push
git push -u origin main
```

---

## Troubleshooting

### "Permission denied (publickey)"
- You need to set up SSH key (see above)
- Or use HTTPS URL instead

### "Repository not found"
- Check your username is correct in the URL
- Make sure repository exists on GitHub
- If private repo, make sure you're logged in

### "Failed to push some refs"
- GitHub repo might not be empty
- Use `git push -f origin main` to force push (⚠️ only if you're sure)

### "Branch main doesn't exist"
- Your branch might be called `master` instead
- Use: `git push -u origin master`
- Or rename: `git branch -M main` then push

---

## What's Next After Pushing?

Once your code is on GitHub:

1. **Create labels** (see `.github/LABELS.md`)
2. **Set up project board** (see `.github/PROJECT_BOARD_SETUP.md`)
3. **Create initial issues** (see `.github/INITIAL_ISSUES.md`)
4. **Start using the system!**

Go back to `.github/BUSINESS_SYSTEMS_SETUP_GUIDE.md` for the full checklist.

---

## Making Your Repo Public vs. Private

### Private Repo (Current)
**Pros:**
- Code stays private
- Can work without others seeing
- Good for early development

**Cons:**
- No community contributions
- Can't share easily
- GitHub Actions minutes limited on free tier

### Public Repo
**Pros:**
- Free unlimited GitHub Actions
- Community can contribute
- Good for portfolio
- Can share progress easily

**Cons:**
- Anyone can see your code
- Need to be careful about secrets (API keys, etc.)

**You can change this later:** Repo Settings → Danger Zone → Change visibility

---

## Quick Reference

**Check remote:**
```bash
git remote -v
```

**Push to GitHub:**
```bash
git push origin main
# or
git push origin master
```

**Pull from GitHub:**
```bash
git pull origin main
```

**Clone on another machine:**
```bash
git clone https://github.com/YOUR_USERNAME/personal-ai-ios.git
```
