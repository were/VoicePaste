- Read `./docs/README.md` for the goal of this repository.
- This project is purely written in `Swift`, the native language for Mac OS UI.
- Use the command below to build (you can replace `Release` with `Debug` for debugging):
```bash
xcodebuild \
  -scheme VoicePaste \
  -configuration Release \
  -destination 'platform=macOS' \
  build
```
