#!/usr/bin/env node

const { spawnSync } = require("node:child_process");
const path = require("node:path");

const rootDir = path.resolve(__dirname, "..");

const ACTIONS = {
    i: ["scripts/install-skills.sh"],
    install: ["scripts/install-skills.sh"],
    u: ["scripts/uninstall-skills.sh"],
    uninstall: ["scripts/uninstall-skills.sh"],
};

function printHelp() {
    console.log("jcs - just-common-skills");
    console.log("");
    console.log("Global installation to all AI assistants:");
    console.log("  jcs i               # Install to all AI assistants");
    console.log("  jcs i --force       # Force install without confirmation");
    console.log("  jcs u               # Uninstall from all AI assistants");
    console.log("  jcs u --force       # Force uninstall without confirmation");
    console.log("");
    console.log("Targets:");
    console.log("  • ~/.claude/skills    (Claude Code)");
    console.log("  • ~/.github/skills    (GitHub Copilot)");
    console.log("  • ~/.codex/skills     (Codex)");
    console.log("  • ~/.cursor/skills    (Cursor / OpenAI)");
    console.log("  • ~/.gemini/skills    (Google Gemini)");
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