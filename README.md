# MrCoder

A Hugo-based educational website about compilers and programming.

## Prerequisites

- [Hugo Extended](https://gohugo.io/installation/) version 0.138.0 or later
- Git (for cloning submodules)

## Running Locally

### Quick Start (Easiest Method)

```bash
# 1. Install Hugo (on Linux/macOS)
./install-hugo.sh

# 2. Run the site
./run-local.sh
```

The site will be available at: **http://localhost:1313/MrCoder/**

### Manual Setup

**1. Install Hugo Extended**

On Ubuntu/Debian:
```bash
wget https://github.com/gohugoio/hugo/releases/download/v0.138.0/hugo_extended_0.138.0_linux-amd64.deb
sudo dpkg -i hugo_extended_0.138.0_linux-amd64.deb
```

On macOS:
```bash
brew install hugo
```

On Windows:
```bash
# Using Chocolatey
choco install hugo-extended

# Or download from:
# https://github.com/gohugoio/hugo/releases/tag/v0.138.0
```

**2. Initialize Theme Submodule**

```bash
git submodule update --init --recursive
```

**3. Run the Development Server**

```bash
hugo server
```

The site will be available at: **http://localhost:1313/MrCoder/**

### 4. Build for Production

To generate the static site in the `public/` directory:

```bash
hugo --gc --minify
```

## Project Structure

```
MrCoder/
├── content/          # Markdown content files
│   ├── compiler/     # Compiler-related content
│   └── ...
├── static/           # Static files (images, etc.)
├── themes/           # Hugo theme
│   └── hugo-theme-learn/
├── config.toml       # Hugo configuration
└── public/           # Generated site (created after build)
```

## Configuration

The site is configured via [config.toml](config.toml):
- Base URL: `https://lascar-pacagi.github.io/MrCoder/`
- Default language: French (fr)
- Theme: hugo-theme-learn

## Deployment

The site is automatically deployed to GitHub Pages via GitHub Actions when changes are pushed to the `master` branch. See [.github/workflows/hugo.yml](.github/workflows/hugo.yml) for details.

## Troubleshooting

### Mermaid diagrams not rendering

If Mermaid diagrams are not displaying:
1. Make sure you're using Hugo Extended version
2. Clear your browser cache
3. Check browser console (F12) for JavaScript errors

### Theme not loading

If the theme is missing:
```bash
git submodule update --init --recursive
```

### Port already in use

If port 1313 is already in use:
```bash
hugo server -p 1314
```

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test locally with `hugo server`
5. Submit a pull request

## License

See repository for license information.
