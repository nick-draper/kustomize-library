# Offline shields

These SVGs are the badges for this repository. The root README links to them with a relative path, so the page renders without `img.shields.io`.

Copy this directory into another repository and edit `manifest.tsv`. Each row is one badge.

| Column | Meaning |
| --- | --- |
| `file` | SVG filename written next to this file |
| `label` | Left-hand text |
| `message` | Right-hand text |
| `color` | Hex color without `#` |
| `logo` | Optional [simple-icons](https://simpleicons.org/) slug |
| `logoColor` | Optional logo color |

`label` and `message` are separate columns. They are sent as the `static/v1` query, so a hyphen in either value needs no special encoding.

Refresh the files while online:

```bash
./badges/refresh.sh
```

Commit the SVGs. Later renders use the files.

Leave request-time shields, such as GitHub last-commit, out of the manifest. Shields fills those in on each request, and a saved copy keeps stale text.
