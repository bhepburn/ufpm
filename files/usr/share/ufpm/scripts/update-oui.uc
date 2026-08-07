#!/usr/bin/env ucode
'use strict';

// Downloads the four IEEE OUI CSV sources and compiles each one into its own
// binary hash table under /usr/share/ufpm/db/:
//   oui.bin  oui28.bin  oui36.bin  iab.bin
//
// Called at service boot (blocking — failure prevents daemon start).
// Requires: uclient-fetch, ucode-mod-fs

import { popen } from "fs";
let uht = require("uht");

const DB_DIR = "/usr/share/ufpm/db";

const SOURCES = [
	{ url: "http://standards-oui.ieee.org/oui/oui.csv",       name: "oui",   prefix: "mac-oui"   },
	{ url: "https://standards-oui.ieee.org/oui28/mam.csv",    name: "oui28", prefix: "mac-oui28" },
	{ url: "https://standards-oui.ieee.org/oui36/oui36.csv",  name: "oui36", prefix: "mac-oui36" },
	{ url: "https://standards-oui.ieee.org/iab/iab.csv",      name: "iab",   prefix: "mac-iab"   },
];

// Parse an IEEE assignment CSV stream and return a signature → [{vendor}] map.
// f is a popen handle streaming CSV from uclient-fetch stdout.
function parse_csv(f, prefix, url) {
	if (!f) {
		warn(`ufpm: cannot open stream for ${url}\n`);
		return null;
	}

	// Locate column indices from the header row
	let header = f.read("line");
	if (!header) {
		warn(`ufpm: empty response for ${url}\n`);
		return null;
	}

	let cols = split(rtrim(header, "\r\n"), ",");
	let idx_assignment = -1;
	let idx_org = -1;
	for (let i = 0; i < length(cols); i++) {
		let col = trim(cols[i], '"');
		if (col == "Assignment")             idx_assignment = i;
		else if (col == "Organization Name") idx_org = i;
	}

	if (idx_assignment < 0 || idx_org < 0) {
		warn(`ufpm: unexpected CSV header in ${url}\n`);
		return null;
	}

	let signatures = {};
	let line;
	while ((line = f.read("line")) != null) {
		line = rtrim(line, "\r\n");
		if (!length(line))
			continue;

		let fields = split(line, ",");
		if (length(fields) <= max(idx_assignment, idx_org))
			continue;

		let oui    = lc(trim(fields[idx_assignment], '"'));
		let vendor = replace(trim(fields[idx_org], '" '), '"', '');

		if (!length(oui) || !length(vendor))
			continue;

		let sig = `${prefix}-${oui}|1`;
		signatures[sig] ??= [];
		push(signatures[sig], { vendor });
	}

	return signatures;
}

// ── main ────────────────────────────────────────────────────────────────────

let ok = true;

for (let src in SOURCES) {
	let db_path = `${DB_DIR}/${src.name}.bin`;

	warn(`ufpm: fetching ${src.url}\n`);
	let f = popen(`uclient-fetch -q -O - '${src.url}'`, "r");
	let signatures = parse_csv(f, src.prefix, src.url);
	if (f) f.close();

	if (!signatures || !length(keys(signatures))) {
		warn(`ufpm: no data parsed from ${src.url}\n`);
		ok = false;
		continue;
	}

	uht.mark_hashtable(signatures);
	uht.save(db_path, signatures);
	warn(`ufpm: wrote ${db_path}\n`);
}

exit(ok ? 0 : 1);
