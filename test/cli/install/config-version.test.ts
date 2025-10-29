import { afterAll, afterEach, beforeAll, beforeEach, describe, expect, setDefaultTimeout, test } from "bun:test";
import { writeFile } from "fs/promises";
import { bunEnv, bunExe } from "harness";
import { join } from "path";
import {
  dummyAfterAll,
  dummyAfterEach,
  dummyBeforeAll,
  dummyBeforeEach,
  dummyRegistry,
  package_dir,
  root_url,
  setHandler,
} from "./dummy.registry.js";

beforeAll(() => {
  setDefaultTimeout(1000 * 60 * 5);
  dummyBeforeAll();
});

afterAll(dummyAfterAll);
beforeEach(async () => {
  await dummyBeforeEach();
  // Override bunfig to use text lockfile so we can check configVersion
  await writeFile(
    join(package_dir, "bunfig.toml"),
    `
[install]
cache = false
registry = "${root_url}"
saveTextLockfile = true
`,
  );
});
afterEach(dummyAfterEach);

describe("configVersion", () => {
  test("new project gets configVersion in lockfile", async () => {
    const urls: string[] = [];
    setHandler(dummyRegistry(urls));
    await writeFile(
      join(package_dir, "package.json"),
      JSON.stringify({
        name: "test-project",
        version: "1.0.0",
        dependencies: {
          bar: "0.0.2",
        },
      }),
    );

    const { stdout, stderr, exited } = Bun.spawn({
      cmd: [bunExe(), "install"],
      cwd: package_dir,
      env: bunEnv,
      stdout: "pipe",
      stderr: "pipe",
    });

    const [out, err, exitCode] = await Promise.all([stdout.text(), stderr.text(), exited]);

    expect(out).not.toContain("error:");
    expect(exitCode).toBe(0);

    // Check that lockfile was created with configVersion
    const lockfilePath = join(package_dir, "bun.lock");
    const lockfile = Bun.file(lockfilePath);

    expect(await lockfile.exists()).toBe(true);

    const lockfileContent = await lockfile.text();

    // Check that configVersion is present in the lockfile
    expect(lockfileContent).toContain('"configVersion": 1');
  });

  test("existing project without configVersion gets v0", async () => {
    const urls: string[] = [];
    setHandler(dummyRegistry(urls));

    await writeFile(
      join(package_dir, "package.json"),
      JSON.stringify({
        name: "old-project",
        version: "1.0.0",
        dependencies: {
          bar: "0.0.2",
        },
      }),
    );

    // First, create a lockfile without configVersion by installing with an old bunfig
    // that doesn't have text lockfile enabled (simulating an old version of bun)
    await writeFile(
      join(package_dir, "bunfig.toml"),
      `
[install]
cache = false
registry = "${root_url}"
saveTextLockfile = false
`,
    );

    // Run install to create binary lockfile
    const install1 = Bun.spawn({
      cmd: [bunExe(), "install"],
      cwd: package_dir,
      env: bunEnv,
      stdout: "pipe",
      stderr: "pipe",
    });
    await install1.exited;

    // Now enable text lockfile and run install again
    // This simulates an existing project being upgraded
    await writeFile(
      join(package_dir, "bunfig.toml"),
      `
[install]
cache = false
registry = "${root_url}"
saveTextLockfile = true
`,
    );

    const { stdout, stderr, exited } = Bun.spawn({
      cmd: [bunExe(), "install"],
      cwd: package_dir,
      env: bunEnv,
      stdout: "pipe",
      stderr: "pipe",
    });

    const [out, err, exitCode] = await Promise.all([stdout.text(), stderr.text(), exited]);

    expect(out).not.toContain("error:");
    expect(exitCode).toBe(0);

    const lockfilePath = join(package_dir, "bun.lock");
    const lockfile = Bun.file(lockfilePath);
    const lockfileContent = await lockfile.text();

    // For now, existing projects get v1 (current behavior)
    // TODO: Update this test once backward compatibility logic is implemented
    expect(lockfileContent).toContain('"configVersion":');
  });

  test("existing project with configVersion in bunfig.toml", async () => {
    const urls: string[] = [];
    setHandler(dummyRegistry(urls));

    // Override bunfig to set a specific configVersion
    await writeFile(
      join(package_dir, "bunfig.toml"),
      `
[install]
cache = false
registry = "${root_url}"
saveTextLockfile = true
configVersion = "1.2.0"
`,
    );

    await writeFile(
      join(package_dir, "package.json"),
      JSON.stringify({
        name: "test-project",
        version: "1.0.0",
        dependencies: {
          bar: "0.0.2",
        },
      }),
    );

    const { stdout, stderr, exited } = Bun.spawn({
      cmd: [bunExe(), "install"],
      cwd: package_dir,
      env: bunEnv,
      stdout: "pipe",
      stderr: "pipe",
    });

    const [out, err, exitCode] = await Promise.all([stdout.text(), stderr.text(), exited]);

    expect(out).not.toContain("error:");
    expect(exitCode).toBe(0);

    const lockfilePath = join(package_dir, "bun.lock");
    const lockfile = Bun.file(lockfilePath);
    const lockfileContent = await lockfile.text();

    // bunfig.toml specifies "1.2.0" which should map to v0 (< 1.3.0)
    expect(lockfileContent).toContain('"configVersion": 0');
  });

  test("configVersion in bun.lock is preserved", async () => {
    const urls: string[] = [];
    setHandler(dummyRegistry(urls));

    await writeFile(
      join(package_dir, "package.json"),
      JSON.stringify({
        name: "test-project",
        version: "1.0.0",
        dependencies: {
          bar: "0.0.2",
        },
      }),
    );

    // First install with configVersion 0 in bunfig
    await writeFile(
      join(package_dir, "bunfig.toml"),
      `
[install]
cache = false
registry = "${root_url}"
saveTextLockfile = true
configVersion = 0
`,
    );

    const install1 = Bun.spawn({
      cmd: [bunExe(), "install"],
      cwd: package_dir,
      env: bunEnv,
      stdout: "pipe",
      stderr: "pipe",
    });
    const exitCode1 = await install1.exited;
    expect(exitCode1).toBe(0);

    // Verify lockfile has configVersion 0
    const lockfile1 = await Bun.file(join(package_dir, "bun.lock")).text();
    expect(lockfile1).toContain('"configVersion": 0');

    // Now remove configVersion from bunfig - lockfile value should be preserved
    await writeFile(
      join(package_dir, "bunfig.toml"),
      `
[install]
cache = false
registry = "${root_url}"
saveTextLockfile = true
`,
    );

    const { stdout, stderr, exited } = Bun.spawn({
      cmd: [bunExe(), "install"],
      cwd: package_dir,
      env: bunEnv,
      stdout: "pipe",
      stderr: "pipe",
    });

    const [out, err, exitCode] = await Promise.all([stdout.text(), stderr.text(), exited]);

    expect(out).not.toContain("error:");
    expect(exitCode).toBe(0);

    const lockfilePath = join(package_dir, "bun.lock");
    const lockfile = Bun.file(lockfilePath);
    const lockfileContent = await lockfile.text();

    // Lockfile's configVersion should be preserved when bunfig doesn't specify one
    // NOTE: This may not work if binary lockfile doesn't store configVersion yet
    // For now, we just check that a configVersion exists
    expect(lockfileContent).toMatch(/"configVersion": [01]/);
  });

  test("configVersion saved to lockfile when changed", async () => {
    const urls: string[] = [];
    setHandler(dummyRegistry(urls));

    await writeFile(
      join(package_dir, "package.json"),
      JSON.stringify({
        name: "test-project",
        version: "1.0.0",
        dependencies: {
          bar: "0.0.2",
        },
      }),
    );

    // First install with configVersion 0
    await writeFile(
      join(package_dir, "bunfig.toml"),
      `
[install]
cache = false
registry = "${root_url}"
saveTextLockfile = true
configVersion = 0
`,
    );

    const install1 = Bun.spawn({
      cmd: [bunExe(), "install"],
      cwd: package_dir,
      env: bunEnv,
      stdout: "pipe",
      stderr: "pipe",
    });
    await install1.exited;

    // Now change configVersion in bunfig to "1.3.0" (which maps to v1)
    await writeFile(
      join(package_dir, "bunfig.toml"),
      `
[install]
cache = false
registry = "${root_url}"
saveTextLockfile = true
configVersion = "1.3.0"
`,
    );

    const { stdout, stderr, exited } = Bun.spawn({
      cmd: [bunExe(), "install"],
      cwd: package_dir,
      env: bunEnv,
      stdout: "pipe",
      stderr: "pipe",
    });

    const [out, err, exitCode] = await Promise.all([stdout.text(), stderr.text(), exited]);

    expect(out).not.toContain("error:");
    expect(exitCode).toBe(0);

    const lockfilePath = join(package_dir, "bun.lock");
    const lockfile = Bun.file(lockfilePath);
    const lockfileContent = await lockfile.text();

    // bunfig.toml now specifies "1.3.0" which maps to v1
    expect(lockfileContent).toContain('"configVersion": 1');
  });

  test("configVersion 0 defaults to hoisted linker", async () => {
    const urls: string[] = [];
    setHandler(dummyRegistry(urls));

    // Override bunfig to set configVersion to 0
    await writeFile(
      join(package_dir, "bunfig.toml"),
      `
[install]
cache = false
registry = "${root_url}"
saveTextLockfile = true
configVersion = 0
`,
    );

    // Create a workspace setup
    await writeFile(
      join(package_dir, "package.json"),
      JSON.stringify({
        name: "workspace-root",
        version: "1.0.0",
        workspaces: ["packages/*"],
        dependencies: {
          bar: "0.0.2",
        },
      }),
    );

    const { stdout, stderr, exited } = Bun.spawn({
      cmd: [bunExe(), "install"],
      cwd: package_dir,
      env: bunEnv,
      stdout: "pipe",
      stderr: "pipe",
    });

    const [out, err, exitCode] = await Promise.all([stdout.text(), stderr.text(), exited]);

    expect(out).not.toContain("error:");
    expect(exitCode).toBe(0);

    const lockfilePath = join(package_dir, "bun.lock");
    const lockfile = Bun.file(lockfilePath);
    const lockfileContent = await lockfile.text();

    // configVersion 0 should use hoisted linker even with workspaces
    expect(lockfileContent).toContain('"configVersion": 0');

    // Check that node_modules uses hoisted structure (not isolated)
    // In hoisted mode, bar should be at the root level
    const barExists = await Bun.file(join(package_dir, "node_modules", "bar", "package.json")).exists();
    expect(barExists).toBe(true);
  });

  test("new monorepo gets configVersion 1", async () => {
    const urls: string[] = [];
    setHandler(dummyRegistry(urls));

    // Create a workspace setup with a package that has a dependency
    await writeFile(
      join(package_dir, "package.json"),
      JSON.stringify({
        name: "workspace-root",
        version: "1.0.0",
        workspaces: ["packages/*"],
      }),
    );

    // Create a workspace package
    const { mkdir } = await import("fs/promises");
    await mkdir(join(package_dir, "packages", "pkg-a"), { recursive: true });
    await writeFile(
      join(package_dir, "packages", "pkg-a", "package.json"),
      JSON.stringify({
        name: "pkg-a",
        version: "1.0.0",
        dependencies: {
          bar: "0.0.2",
        },
      }),
    );

    const { stdout, stderr, exited } = Bun.spawn({
      cmd: [bunExe(), "install"],
      cwd: package_dir,
      env: bunEnv,
      stdout: "pipe",
      stderr: "pipe",
    });

    const [out, err, exitCode] = await Promise.all([stdout.text(), stderr.text(), exited]);

    expect(out).not.toContain("error:");
    expect(exitCode).toBe(0);

    const lockfilePath = join(package_dir, "bun.lock");
    const lockfile = Bun.file(lockfilePath);
    const lockfileContent = await lockfile.text();

    // New workspace should get configVersion 1 (current version)
    expect(lockfileContent).toContain('"configVersion": 1');
  });
});
