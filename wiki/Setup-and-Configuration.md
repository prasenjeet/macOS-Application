# Setup & Configuration

## Requirements

| Requirement | Minimum version |
|---|---|
| macOS | 13.0 Ventura |
| Xcode | 15.0 |
| Swift | 5.9 |

No external dependencies or package managers are required.

---

## Clone & Build

```bash
# Clone the repository
git clone git@github.com:prasenjeet/macOS-Application.git
cd macOS-Application

# Create the source folder
mkdir -p ~/Downloads/Claude

# (Optional) copy sample files to test immediately
cp SampleHTMLFiles/*.html ~/Downloads/Claude/

# Open in Xcode
open HTMLBookViewer.xcodeproj
```

In Xcode:
1. Select the `HTMLBookViewer` scheme in the toolbar
2. Choose your Mac as the run destination
3. Press `⌘R` to build and run

---

## Source Folder

The app reads HTML files from:

```
~/Downloads/Claude/
```

Place any `.html` or `.htm` file in this folder. The app scans it flat (no subdirectory recursion) and groups files automatically.

**Naming convention for grouping:**

Files are grouped into books by the first two words of the base filename. Use hyphens or underscores as separators:

```
swift-tutorial-01.html  ┐
swift-tutorial-02.html  ├─► Book: "Swift Tutorial"
swift-tutorial-03.html  ┘

python-basics-intro.html  ┐
python-basics-loops.html  ├─► Book: "Python Basics"
python-basics-functions.html ┘
```

---

## Sandbox & Permissions

The app is built with App Sandbox enabled. The entitlement that allows `~/Downloads` access is declared in `Info.plist`:

```xml
<key>NSDownloadsFolderUsageDescription</key>
<string>HTMLBookViewer reads HTML files from the Claude folder inside
your Downloads folder to display them as book pages.</string>
```

On first launch macOS will show a permission dialog. Grant access to `~/Downloads` when prompted.

---

## Running Sample Files

Three sample HTML files are included in `SampleHTMLFiles/`:

```bash
ls SampleHTMLFiles/
# chapter1.html  chapter2.html  chapter3.html

cp SampleHTMLFiles/*.html ~/Downloads/Claude/
```

After copying, click the `↺` refresh button in the app toolbar (or relaunch the app) to reload the library.

---

## Build Settings

| Setting | Location | Default |
|---|---|---|
| Deployment target | `project.pbxproj` → `MACOSX_DEPLOYMENT_TARGET` | `13.0` |
| Swift version | `project.pbxproj` → `SWIFT_VERSION` | `5.0` |
| Bundle identifier | `project.pbxproj` → `PRODUCT_BUNDLE_IDENTIFIER` | `com.example.HTMLBookViewer` |
| Min window size | `HTMLBookViewerApp.swift` → `.frame(minWidth:minHeight:)` | `960 × 640` |

---

## Troubleshooting

| Symptom | Likely cause | Fix |
|---|---|---|
| Library is empty on launch | `~/Downloads/Claude/` folder doesn't exist | `mkdir ~/Downloads/Claude` |
| Files not showing after copy | Scanner ran before files were copied | Click `↺` refresh in toolbar |
| Permission dialog not shown | App was denied in System Settings | System Settings → Privacy & Security → Files and Folders → re-enable |
| Page shows blank content | HTML references assets outside its folder | Move all assets next to the HTML file |
| Console: "Error scanning Downloads/Claude" | Folder missing or permissions denied | Check folder exists and app has Downloads access |
