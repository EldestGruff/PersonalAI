# CI/CD Setup Guide

**Last Updated:** 2026-01-20

## Purpose

Automate testing and builds to catch bugs early and ship faster. CI/CD (Continuous Integration / Continuous Deployment) is essential for maintaining quality as a solo developer.

---

## What is CI/CD?

### Continuous Integration (CI)
**Run tests automatically on every code change**

**Benefits:**
- Catch bugs before merging
- Ensure tests always pass
- No "forgot to run tests" mistakes
- Build confidence in changes

### Continuous Deployment (CD)
**Automatically build and distribute app**

**Benefits:**
- Consistent builds
- Faster TestFlight releases
- Less manual work
- Reproducible releases

---

## CI/CD for Solo Developers

**You don't need everything day 1:**

### Phase 1: Basic CI (Week 1)
- Run tests on every push to main
- Block PRs if tests fail

### Phase 2: Build Automation (Month 1-2)
- Automated TestFlight builds on tag
- Version number bumping

### Phase 3: Full Pipeline (Month 3+)
- Automated App Store submission
- Release notes generation
- Slack/Discord notifications

**Start simple, automate incrementally**

---

## Recommended Tool: GitHub Actions

**Why GitHub Actions?**
- Free for public repos
- 2000 minutes/month for private repos (plenty for solo dev)
- Easy YAML configuration
- Good documentation
- Integrates with GitHub

**Alternatives:**
- CircleCI (2500 credits/month free)
- Bitrise (iOS-focused, limited free tier)
- GitLab CI (if using GitLab)
- Xcode Cloud (Apple's solution, $15/month after free tier)

**Recommendation:** GitHub Actions (you're already on GitHub)

---

## Phase 1: Basic CI Setup

### Goal: Run tests on every push

### Step 1: Create Workflow File

**Create directory:**
```bash
mkdir -p .github/workflows
```

**Create `.github/workflows/test.yml`:**

```yaml
name: Run Tests

on:
  push:
    branches: [ main, develop ]
  pull_request:
    branches: [ main, develop ]

jobs:
  test:
    name: Test on iOS 18
    runs-on: macos-14  # macOS Sonoma with Xcode 15

    steps:
      - name: Checkout code
        uses: actions/checkout@v4

      - name: Select Xcode version
        run: sudo xcode-select -s /Applications/Xcode_15.2.app/Contents/Developer

      - name: Show Xcode version
        run: xcodebuild -version

      - name: Run tests
        run: |
          xcodebuild test \
            -scheme STASH \
            -destination 'platform=iOS Simulator,name=iPhone 15 Pro,OS=17.2' \
            -enableCodeCoverage YES \
            | xcpretty && exit ${PIPESTATUS[0]}

      - name: Upload code coverage
        uses: codecov/codecov-action@v4
        with:
          fail_ci_if_error: false
```

**What this does:**
1. Runs on every push to main/develop
2. Runs on every pull request
3. Checks out code
4. Selects Xcode 15.2
5. Runs full test suite
6. Uploads coverage to Codecov (optional)

### Step 2: Install xcpretty (Optional)

**xcpretty** makes Xcode output readable in CI logs.

**In your local dev environment:**
```bash
gem install xcpretty
```

**Or skip it** - not required, just makes logs prettier.

### Step 3: Commit and Push

```bash
git add .github/workflows/test.yml
git commit -m "Add CI workflow to run tests"
git push
```

### Step 4: Verify in GitHub

1. Go to your repo on GitHub
2. Click "Actions" tab
3. Should see "Run Tests" workflow running
4. Wait for it to complete (5-10 min first time)
5. ✅ Green check = tests passed
6. ❌ Red X = tests failed, click to see why

### Step 5: Add Status Badge to README

**Get badge URL:**
1. GitHub repo → Actions → Select workflow
2. Click "..." → "Create status badge"
3. Copy markdown

**Add to README.md:**
```markdown
# STASH

![Tests](https://github.com/yourusername/personal-ai-ios/actions/workflows/test.yml/badge.svg)

A context-aware thought capture system...
```

**Now you have a badge showing test status!**

---

## Phase 2: Automated TestFlight Builds

### Goal: Push to TestFlight on git tag

### Prerequisites

1. **App Store Connect API Key**
2. **Code Signing Certificates & Profiles**
3. **Fastlane installed**

### Step 1: Create App Store Connect API Key

1. Go to [App Store Connect](https://appstoreconnect.apple.com)
2. Users and Access → Keys → App Store Connect API
3. Click "+" to create new key
4. Name: "GitHub Actions"
5. Access: Admin (or App Manager)
6. Download key (`.p8` file)
7. Note: Key ID and Issuer ID

### Step 2: Add Secrets to GitHub

**In your GitHub repo:**
1. Settings → Secrets and variables → Actions
2. New repository secret:
   - `APP_STORE_CONNECT_API_KEY_ID`: Your Key ID
   - `APP_STORE_CONNECT_ISSUER_ID`: Your Issuer ID
   - `APP_STORE_CONNECT_API_KEY`: Contents of `.p8` file (base64 encoded)

**To base64 encode the .p8 file:**
```bash
base64 -i AuthKey_XXXXXXXXXX.p8 | pbcopy
# Now paste into GitHub secret
```

### Step 3: Set Up Code Signing

**Option A: Fastlane Match (Recommended)**

Match stores certificates in git repo (private).

```bash
# Install fastlane
brew install fastlane

# Initialize match
fastlane match init

# Select storage mode: git
# Enter private GitHub repo URL (create a new private repo for certs)

# Generate certificates
fastlane match appstore --app_identifier com.yourname.STASH
```

**Option B: Manual (Simpler for solo dev)**

1. Export certificates from Xcode
2. Add as GitHub secrets (more complex, not recommended)

### Step 4: Create Fastlane Configuration

**Install Fastlane:**
```bash
cd your-project-directory
fastlane init
```

**Follow prompts:**
- Choose option 2: "Automate beta distribution to TestFlight"
- Enter Apple ID
- Enter app identifier: com.yourname.STASH

**Edit `fastlane/Fastfile`:**

```ruby
default_platform(:ios)

platform :ios do
  desc "Push a new beta build to TestFlight"
  lane :beta do
    # Increment build number
    increment_build_number(xcodeproj: "STASH.xcodeproj")

    # Set up code signing
    setup_ci if ENV['CI']

    match(
      type: "appstore",
      readonly: true,
      app_identifier: "com.yourname.STASH"
    )

    # Build app
    build_app(
      scheme: "STASH",
      export_method: "app-store",
      export_options: {
        provisioningProfiles: {
          "com.yourname.STASH" => "match AppStore com.yourname.STASH"
        }
      }
    )

    # Upload to TestFlight
    upload_to_testflight(
      skip_waiting_for_build_processing: true,
      api_key_path: "AuthKey.p8"
    )

    # Commit version bump
    commit_version_bump(
      message: "Bump build number",
      xcodeproj: "STASH.xcodeproj"
    )

    push_to_git_remote
  end
end
```

### Step 5: Create TestFlight Workflow

**Create `.github/workflows/testflight.yml`:**

```yaml
name: Deploy to TestFlight

on:
  push:
    tags:
      - 'v*.*.*-beta*'  # Trigger on tags like v1.2.0-beta1

jobs:
  deploy:
    name: Build and Upload to TestFlight
    runs-on: macos-14

    steps:
      - name: Checkout code
        uses: actions/checkout@v4
        with:
          fetch-depth: 0  # Fetch all history for version bumping

      - name: Select Xcode
        run: sudo xcode-select -s /Applications/Xcode_15.2.app/Contents/Developer

      - name: Install Fastlane
        run: gem install fastlane

      - name: Create API Key file
        run: |
          mkdir -p ~/.appstoreconnect/private_keys
          echo "${{ secrets.APP_STORE_CONNECT_API_KEY }}" | base64 -d > AuthKey.p8

      - name: Set up Match
        env:
          MATCH_PASSWORD: ${{ secrets.MATCH_PASSWORD }}
          MATCH_GIT_BASIC_AUTHORIZATION: ${{ secrets.MATCH_GIT_BASIC_AUTH }}
        run: echo "Match configured"

      - name: Run Fastlane Beta Lane
        env:
          FASTLANE_APPLE_APPLICATION_SPECIFIC_PASSWORD: ${{ secrets.FASTLANE_PASSWORD }}
          APP_STORE_CONNECT_API_KEY_ID: ${{ secrets.APP_STORE_CONNECT_API_KEY_ID }}
          APP_STORE_CONNECT_ISSUER_ID: ${{ secrets.APP_STORE_CONNECT_ISSUER_ID }}
          MATCH_PASSWORD: ${{ secrets.MATCH_PASSWORD }}
        run: fastlane beta

      - name: Notify success
        if: success()
        run: echo "🚀 TestFlight build uploaded successfully!"

      - name: Notify failure
        if: failure()
        run: echo "❌ TestFlight build failed!"
```

### Step 6: Trigger TestFlight Build

**Create a tag and push:**
```bash
git tag v1.0.0-beta1
git push origin v1.0.0-beta1
```

**GitHub Actions will:**
1. Check out code
2. Run Fastlane
3. Build app
4. Upload to TestFlight
5. Bump version and commit

**Check progress:**
- GitHub → Actions tab
- Wait 15-30 minutes
- Check App Store Connect → TestFlight

---

## Phase 3: Full Automation

### Add More Workflows

#### Lint and Code Quality

**Create `.github/workflows/lint.yml`:**

```yaml
name: Lint

on: [push, pull_request]

jobs:
  swiftlint:
    runs-on: macos-14
    steps:
      - uses: actions/checkout@v4

      - name: Install SwiftLint
        run: brew install swiftlint

      - name: Run SwiftLint
        run: swiftlint --strict
```

**Requires adding SwiftLint config** (`.swiftlint.yml`)

#### Automated Releases

**Trigger on version tags:**

```yaml
name: Release

on:
  push:
    tags:
      - 'v*.*.*'  # v1.2.0

jobs:
  release:
    runs-on: macos-14
    steps:
      - uses: actions/checkout@v4

      - name: Create GitHub Release
        uses: actions/create-release@v1
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
        with:
          tag_name: ${{ github.ref }}
          release_name: Release ${{ github.ref }}
          body: |
            See CHANGELOG.md for details
          draft: false
          prerelease: false

      # Then run Fastlane to submit to App Store
```

---

## Cost and Resource Usage

### GitHub Actions Minutes

**Free tier:**
- Public repos: Unlimited
- Private repos: 2000 minutes/month

**Typical usage:**
- Test run: ~5 minutes
- TestFlight build: ~15 minutes
- With 10 commits/week + 2 TestFlight builds/month: ~80 min/month

**Well within free tier for solo dev**

### macOS Runners

**Note:** macOS minutes count as 10x Linux minutes

**Example:**
- 1 macOS minute = 10 Linux minutes
- 5 min test run = 50 minutes of your quota

**Still plenty for solo dev**

---

## Notifications

### Slack Notifications (Optional)

**Add to workflow:**

```yaml
- name: Notify Slack
  if: always()
  uses: 8398a7/action-slack@v3
  with:
    status: ${{ job.status }}
    text: 'TestFlight build ${{ job.status }}'
    webhook_url: ${{ secrets.SLACK_WEBHOOK }}
```

### Email Notifications

GitHub automatically emails you on workflow failures.

**Configure:**
1. GitHub Settings → Notifications
2. Enable "Actions: Send notifications for failed workflows"

---

## Troubleshooting Common Issues

### Tests Fail in CI but Pass Locally

**Cause:** Environment differences

**Fix:**
- Check Xcode version (might differ)
- Check simulator version
- Check for race conditions (timing-dependent tests)

### Code Signing Fails

**Cause:** Certificates not accessible

**Fix:**
- Verify secrets are set correctly
- Check Match password
- Regenerate certificates if needed

### Build Times Out

**Cause:** 60 minute timeout on GitHub Actions

**Fix:**
- Optimize build (reduce dependencies)
- Use caching (cache Derived Data)

**Example caching:**

```yaml
- name: Cache DerivedData
  uses: actions/cache@v3
  with:
    path: ~/Library/Developer/Xcode/DerivedData
    key: ${{ runner.os }}-derived-data-${{ hashFiles('**/Package.resolved') }}
```

---

## Best Practices

### 1. Keep Workflows Fast
- Run only necessary tests in CI
- Use caching
- Parallelize when possible

### 2. Fail Fast
- Run quick tests first
- Cancel redundant runs
- Set timeouts

### 3. Secure Secrets
- Never commit secrets
- Use GitHub Secrets
- Rotate API keys periodically

### 4. Monitor Usage
- Check Actions minutes usage monthly
- Optimize if approaching limits

### 5. Document Workflows
- Comment complex steps
- Link to docs in workflow files

---

## Local Testing of CI

**Test workflows locally with `act`:**

```bash
# Install act
brew install act

# Run workflow locally
act push

# Run specific job
act -j test
```

**Limitations:**
- Can't fully simulate macOS runner
- Good for debugging YAML syntax

---

## Workflow Templates

### Minimal CI (Just Tests)

```yaml
name: Test
on: [push]
jobs:
  test:
    runs-on: macos-14
    steps:
      - uses: actions/checkout@v4
      - run: xcodebuild test -scheme STASH -destination 'platform=iOS Simulator,name=iPhone 15 Pro'
```

### PR Checks

```yaml
name: PR Checks
on: [pull_request]
jobs:
  test:
    runs-on: macos-14
    steps:
      - uses: actions/checkout@v4
      - run: xcodebuild test -scheme STASH -destination 'platform=iOS Simulator,name=iPhone 15 Pro'

  lint:
    runs-on: macos-14
    steps:
      - uses: actions/checkout@v4
      - run: brew install swiftlint && swiftlint
```

---

## Next Steps

1. **Set up basic CI** (test workflow)
2. **Add status badge** to README
3. **Test by making a commit**
4. **Plan TestFlight automation** (Phase 2)
5. **Install Fastlane** locally
6. **Set up Match** for code signing
7. **Create TestFlight workflow**
8. **Test with beta tag**

---

## Success Metrics

**Your CI/CD is working when:**

✅ Tests run automatically on every push
✅ You trust the CI results as much as local tests
✅ TestFlight builds upload without manual work
✅ You spend less time on release logistics
✅ Bugs are caught before merging

---

**Recommended reading:**
- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [Fastlane Documentation](https://docs.fastlane.tools/)
- [Xcode Cloud vs GitHub Actions](https://www.donnywals.com/xcode-cloud-vs-github-actions/)

---

This completes the operations setup! You now have:
1. ✅ GitHub Issues for tracking
2. ✅ Support workflow for customers
3. ✅ Release process for shipping
4. ✅ Monitoring for visibility
5. ✅ CI/CD for automation

**Go back to [OPERATIONS_OVERVIEW.md](./OPERATIONS_OVERVIEW.md) for the big picture.**
