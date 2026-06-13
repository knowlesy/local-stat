# Contributing to LocalStat

Thank you for your interest in contributing to LocalStat! This guide will help you get started.

---

## 📋 Prerequisites

- **macOS 14.0+** (Sonoma or later)
- **Xcode 15+** with Swift 5.9+
- **Git** for version control

## 🚀 Getting Started

1. **Fork** the repository on GitHub
2. **Clone** your fork locally:
   ```bash
   git clone https://github.com/<your-username>/local-stat.git
   cd local-stat
   ```
3. **Build** the project:
   ```bash
   swift build
   ```
4. **Run tests** to make sure everything passes:
   ```bash
   swift test
   ```

## 🌿 Branch Naming

Use descriptive branch names with a prefix:

- `feature/add-gpu-monitoring` – New features
- `fix/memory-leak-timer` – Bug fixes
- `docs/update-readme` – Documentation changes
- `refactor/extract-theme-protocol` – Code refactoring

## 💻 Development Workflow

1. Create a new branch from `main`:
   ```bash
   git checkout -b feature/your-feature-name
   ```
2. Make your changes, following the code style guidelines below
3. Test your changes locally
4. Commit with clear, descriptive messages:
   ```bash
   git commit -m "feat: add network throughput monitoring"
   ```
5. Push to your fork and open a Pull Request

## 🎨 Code Style

- **Indentation**: 4 spaces (enforced by `.editorconfig`)
- **Line endings**: LF (Unix-style)
- **Swift conventions**: Follow [Swift API Design Guidelines](https://www.swift.org/documentation/api-design-guidelines/)
- **Access control**: Use the most restrictive access level possible
- **Documentation**: Add doc comments for public APIs using `///` syntax

## 📝 Commit Messages

We follow [Conventional Commits](https://www.conventionalcommits.org/):

| Prefix     | Usage                          |
|------------|--------------------------------|
| `feat:`    | New feature                    |
| `fix:`     | Bug fix                        |
| `docs:`    | Documentation only             |
| `style:`   | Code style (no logic changes)  |
| `refactor:`| Code refactoring               |
| `test:`    | Adding or updating tests       |
| `chore:`   | Build process or tooling       |

## 🔀 Pull Request Process

1. Ensure your PR targets the `main` branch
2. Fill out the PR template (if provided)
3. Link any related issues using `Closes #123` syntax
4. Ensure CI checks pass (build + tests)
5. Request a review from a maintainer
6. Address any feedback promptly

## 🐛 Reporting Issues

When opening an issue, please include:

- **macOS version** and **hardware** (Intel/Apple Silicon)
- **Steps to reproduce** the issue
- **Expected behavior** vs **actual behavior**
- **Screenshots** or logs if applicable

## 🧪 Testing

- Write tests for new features and bug fixes
- Run the full test suite before submitting:
  ```bash
  swift test
  ```
- Aim for meaningful test coverage, not just line coverage

## 📦 Building the App Bundle

To create a distributable `.app` bundle:

```bash
chmod +x scripts/bundle.sh
./scripts/bundle.sh
```

The built app will be at `build/LocalStat.app`.

---

## 📜 License

By contributing, you agree that your contributions will be licensed under the [MIT License](LICENSE).
