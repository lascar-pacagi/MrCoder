# Hugo 0.138.0 Upgrade Notes

This document describes the changes made to upgrade from Hugo 0.55.5 to Hugo 0.138.0.

## Summary

The site has been upgraded from Hugo 0.55.5 (2019) to Hugo 0.138.0 (2024) to fix Mermaid diagram rendering issues and improve compatibility with modern browsers.

## Breaking Changes Fixed

### 1. `.Hugo.Generator` → `hugo.Generator`
**File:** `layouts/partials/header.html`

Changed deprecated syntax:
- Old: `{{ .Hugo.Generator }}`
- New: `{{ hugo.Generator }}`

### 2. `.Site.IsMultiLingual` → `hugo.IsMultilingual`
**Files:**
- `layouts/partials/menu.html`
- `layouts/partials/search.html`

Changed deprecated syntax:
- Old: `{{ .Site.IsMultiLingual }}`
- New: `{{ hugo.IsMultilingual }}`

### 3. `.URL` → `.RelPermalink`
**Files:**
- `layouts/partials/menu.html`
- `layouts/partials/header.html`
- `layouts/partials/footer.html`

Changed deprecated page property:
- Old: `{{ .URL }}`
- New: `{{ .RelPermalink }}`

### 4. `.UniqueID` → `.RelPermalink` (for comparison)
**File:** `layouts/partials/menu.html`

Changed deprecated ID comparison:
- Old: `{{ if eq .UniqueID $currentNode.UniqueID }}`
- New: `{{ if eq .RelPermalink $currentNode.RelPermalink }}`

Note: `.UniqueID` was removed in newer Hugo versions. Using `.RelPermalink` for page identity comparison is the recommended approach.

## Files Modified

The following template files were copied from the theme and updated:

### Partials (in `layouts/partials/`):
1. `layouts/partials/header.html` - Already existed, updated
2. `layouts/partials/menu.html` - Copied from theme and updated
3. `layouts/partials/search.html` - Copied from theme and updated
4. `layouts/partials/footer.html` - Copied from theme and updated

### Default Layouts (in `layouts/_default/`):
5. `layouts/_default/list.html` - Copied from theme and updated
   - Fixed: `.URL` → `.RelPermalink`
   - Fixed: `"taxonomyTerm"` → `"term"` (taxonomy kind name changed)

## GitHub Actions Workflow

**File:** `.github/workflows/hugo.yml`

Updated Hugo version:
- Old: `HUGO_VERSION: 0.55.5`
- New: `HUGO_VERSION: 0.138.0`

## Benefits

✅ Mermaid diagrams now render correctly
✅ Better browser JavaScript compatibility
✅ Future-proof template syntax
✅ No deprecation warnings
✅ Security updates from newer Hugo version

## Testing

To test the site locally:

```bash
# Install Hugo Extended 0.138.0
./install-hugo.sh

# Run the development server
./run-local.sh
```

Visit http://localhost:1313/MrCoder/ to verify:
- Mermaid diagrams render correctly
- Navigation works
- Multi-language switching works
- Search functionality works

## Deployment

Push changes to the `master` branch to trigger automatic deployment to GitHub Pages via GitHub Actions.

## Rollback Instructions

If issues occur, you can rollback by:

1. Revert `.github/workflows/hugo.yml` to use Hugo 0.55.5
2. Remove the modified template files from `layouts/partials/`:
   - `menu.html`
   - `search.html`
   - `footer.html`
3. Revert `layouts/partials/header.html` to use old syntax

## References

- [Hugo 0.124.0 Release Notes](https://github.com/gohugoio/hugo/releases/tag/v0.124.0) - Deprecated `.Site.IsMultiLingual`
- [Hugo Template Variables](https://gohugo.io/variables/) - Current best practices
