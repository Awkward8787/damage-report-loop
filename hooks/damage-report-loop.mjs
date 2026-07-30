#!/usr/bin/env node

import { readFile } from "node:fs/promises";
import process from "node:process";

const statePath = ".cursor/damage-reports/loop-state.json";

async function main() {
  let input = {};
  try {
    const chunks = [];
    for await (const chunk of process.stdin) chunks.push(chunk);
    const raw = Buffer.concat(chunks).toString("utf8").trim();
    if (raw) input = JSON.parse(raw);
  } catch {
    process.stdout.write("{}\n");
    return;
  }

  if (input.status && input.status !== "completed") {
    process.stdout.write("{}\n");
    return;
  }

  let state;
  try {
    state = JSON.parse(await readFile(statePath, "utf8"));
  } catch {
    process.stdout.write("{}\n");
    return;
  }

  const terminalStates = new Set(["clear", "blocked", "maxed"]);
  const maxIterations = Math.max(
    1,
    Math.min(Number(state.max_iterations ?? 5), 10),
  );
  const loopCount = Number(input.loop_count ?? state.iteration ?? 0);

  if (
    state.active !== true ||
    terminalStates.has(String(state.status ?? "").toLowerCase()) ||
    loopCount >= maxIterations
  ) {
    process.stdout.write("{}\n");
    return;
  }

  const remaining = Array.isArray(state.remaining_ids)
    ? state.remaining_ids.join(", ")
    : "unresolved findings";

  const followup = [
    `Continue damage-report-loop iteration ${loopCount + 1}/${maxIterations}.`,
    `Current state: ${state.status ?? "running"}.`,
    `Remaining: ${remaining || "re-audit required"}.`,
    "Read .cursor/damage-reports/loop-state.json and latest.md, verify the report head SHA, then continue the bounded audit-fix-test cycle.",
    "Stop and set active=false if the result is clear, blocked, or maxed.",
  ].join(" ");

  process.stdout.write(`${JSON.stringify({ followup_message: followup })}\n`);
}

main().catch(() => {
  process.stdout.write("{}\n");
});
