# OLH Prisestimat

Internal Oslo Lagerhotell price estimator (3PL, cross-docking), same prices and maths as the website.
`app/estimate.js` is a copy of the website's `src/estimate.js` (olh-website repo); the date in the footer says when it was taken.

- **Install:** Code > Download ZIP, unpack, double-click `Install.cmd` (copies `app/` to `%LOCALAPPDATA%\OLH Prisestimat`, desktop shortcut runs `launcher.ps1`, which updates from GitHub and opens the page as an Edge app window). See `LES MEG.txt`.
- **Prices change:** copy the website's `src/estimate.js` into `app/` (strip customer names from comments: public repo), update the footer date in `app/Prisestimat.html`, run `toolselease.ps1 <new version>`, commit and push. Installed copies update the next time they open.
