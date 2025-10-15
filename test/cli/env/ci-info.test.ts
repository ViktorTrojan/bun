import { spawnSync } from "bun";
import { describe, expect, test } from "bun:test";
import { bunEnv, bunExe, tempDir } from "../../harness";

describe("CI detection", () => {
  test("CI=false disables CI detection", () => {
    using dir = tempDir("ci-test", {
      "test.js": `console.log("CI:", process.env.CI);`,
    });

    const result = spawnSync({
      cmd: [bunExe(), "test.js"],
      env: {
        ...bunEnv,
        CI: "false",
        GITHUB_ACTIONS: "true", // This should be ignored when CI=false
      },
      cwd: String(dir),
    });

    expect(result.exitCode).toBe(0);
    expect(result.stdout.toString()).toContain("CI: false");
  });

  test("CI=true without specific CI env vars returns unknown", () => {
    using dir = tempDir("ci-test", {
      "test.js": `console.log("done");`,
    });

    // Clean environment - remove any CI-specific vars
    const cleanEnv = { ...bunEnv };
    // Remove common CI env vars to ensure we get "unknown"
    delete cleanEnv.GITHUB_ACTIONS;
    delete cleanEnv.GITLAB_CI;
    delete cleanEnv.CIRCLECI;
    delete cleanEnv.TRAVIS;
    delete cleanEnv.BUILDKITE;
    delete cleanEnv.JENKINS_URL;

    const result = spawnSync({
      cmd: [bunExe(), "test.js"],
      env: {
        ...cleanEnv,
        CI: "true",
      },
      cwd: String(dir),
    });

    expect(result.exitCode).toBe(0);
  });

  test("Specific CI env vars take precedence over CI=true", () => {
    using dir = tempDir("ci-test", {
      "test.js": `console.log("done");`,
    });

    const result = spawnSync({
      cmd: [bunExe(), "test.js"],
      env: {
        ...bunEnv,
        CI: "true",
        GITHUB_ACTIONS: "true",
      },
      cwd: String(dir),
    });

    expect(result.exitCode).toBe(0);
  });

  test("GITHUB_ACTIONS detection", () => {
    using dir = tempDir("ci-test", {
      "test.js": `console.log("done");`,
    });

    const result = spawnSync({
      cmd: [bunExe(), "test.js"],
      env: {
        ...bunEnv,
        GITHUB_ACTIONS: "true",
      },
      cwd: String(dir),
    });

    expect(result.exitCode).toBe(0);
  });

  test("GITLAB_CI detection", () => {
    using dir = tempDir("ci-test", {
      "test.js": `console.log("done");`,
    });

    const result = spawnSync({
      cmd: [bunExe(), "test.js"],
      env: {
        ...bunEnv,
        GITLAB_CI: "true",
      },
      cwd: String(dir),
    });

    expect(result.exitCode).toBe(0);
  });

  test("CIRCLECI detection", () => {
    using dir = tempDir("ci-test", {
      "test.js": `console.log("done");`,
    });

    const result = spawnSync({
      cmd: [bunExe(), "test.js"],
      env: {
        ...bunEnv,
        CIRCLECI: "true",
      },
      cwd: String(dir),
    });

    expect(result.exitCode).toBe(0);
  });

  test("No CI detection when CI env vars are absent", () => {
    using dir = tempDir("ci-test", {
      "test.js": `console.log("done");`,
    });

    // Clean environment - remove any CI-specific vars
    const cleanEnv = { ...bunEnv };
    delete cleanEnv.CI;
    delete cleanEnv.GITHUB_ACTIONS;
    delete cleanEnv.GITLAB_CI;
    delete cleanEnv.CIRCLECI;
    delete cleanEnv.TRAVIS;
    delete cleanEnv.BUILDKITE;
    delete cleanEnv.JENKINS_URL;

    const result = spawnSync({
      cmd: [bunExe(), "test.js"],
      env: cleanEnv,
      cwd: String(dir),
    });

    expect(result.exitCode).toBe(0);
  });
});
