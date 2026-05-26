#!/usr/bin/env node

const { spawnSync } = require("node:child_process");
const path = require("node:path");

const rootDir = path.resolve(__dirname, "..");

const ACTIONS = {
    i: ["scripts/quick-install.sh"],
    install: ["scripts/quick-install.sh"],
    inject: ["scripts/inject-current-project.sh"],
    u: ["scripts/uninstall-skills.sh"],
    uninstall: ["scripts/uninstall-skills.sh"],
};

function printHelp() {
    console.log("jcs - just-common-skills");
    console.log("");
    console.log("Usage:");
    console.log("  jcs i");
    console.log("  jcs inject <projectPath> [--force] [--reference-entry]");
    console.log("  jcs u [--force] [--with-vscode-prompts]");
}

const [, , cmd, ...args] = process.argv;

if (!cmd || cmd === "-h" || cmd === "--help" || cmd === "help") {
    printHelp();
    process.exit(0);
}

const action = ACTIONS[cmd];
if (!action) {
    console.error(`Unknown command: ${cmd}`);
    printHelp();
    process.exit(1);
}

const scriptPath = path.join(rootDir, action[0]);
const result = spawnSync("bash", [scriptPath, ...args], {
    cwd: rootDir,
    stdio: "inherit",
});

if (typeof result.status === "number") {
    process.exit(result.status);
}

process.exit(1);