const Options = @This();

log_level: LogLevel = .default,
global: bool = false,

global_bin_dir: std.fs.Dir = bun.FD.invalid.stdDir(),
explicit_global_directory: string = "",
/// destination directory to link bins into
// must be a variable due to global installs and bunx
bin_path: stringZ = bun.pathLiteral("node_modules/.bin"),

did_override_default_scope: bool = false,
scope: Npm.Registry.Scope = undefined,

registries: Npm.Registry.Map = .{},
cache_directory: string = "",
enable: Enable = .{},
do: Do = .{},
positionals: []const string = &[_]string{},
update: Update = .{},
dry_run: bool = false,
link_workspace_packages: bool = true,
remote_package_features: Features = .{
    .optional_dependencies = true,
},
local_package_features: Features = .{
    .optional_dependencies = true,
    .dev_dependencies = true,
    .workspaces = true,
},
patch_features: union(enum) {
    nothing: struct {},
    patch: struct {},
    commit: struct {
        patches_dir: string,
    },
} = .{ .nothing = .{} },

filter_patterns: []const string = &.{},
pack_destination: string = "",
pack_filename: string = "",
pack_gzip_level: ?string = null,
json_output: bool = false,

max_retry_count: u16 = 5,
min_simultaneous_requests: usize = 4,

max_concurrent_lifecycle_scripts: usize,

publish_config: PublishConfig = .{},

ca: []const string = &.{},
ca_file_name: string = &.{},

// if set to `false` in bunfig, save a binary lockfile
save_text_lockfile: ?bool = null,

lockfile_only: bool = false,

// `bun pm version` command options
git_tag_version: bool = true,
allow_same_version: bool = false,
preid: string = "",
message: ?string = null,
force: bool = false,

// `bun pm why` command options
top_only: bool = false,
depth: ?usize = null,

/// isolated installs (pnpm-like) or hoisted installs (yarn-like, original)
node_linker: NodeLinker = .auto,

public_hoist_pattern: ?bun.install.PnpmMatcher = null,
hoist_pattern: ?bun.install.PnpmMatcher = null,

// Security scanner module path
security_scanner: ?[]const u8 = null,

// Minimum release age in ms (security feature)
// Only install packages published at least N ms ago
minimum_release_age_ms: ?f64 = null,
// Packages to exclude from minimum release age checking
minimum_release_age_excludes: ?[]const []const u8 = null,

/// Override CPU architecture for optional dependencies filtering
cpu: Npm.Architecture = .current,
/// Override OS for optional dependencies filtering
os: Npm.OperatingSystem = .current,

// from bunfig.toml
config_version: ?ConfigVersion = null,

pub const ConfigVersion = enum(u64) {
    v0,
    v1,

    pub const current: ConfigVersion = .v1;

    pub fn forLockfile(this: ?ConfigVersion) u64 {
        return @intFromEnum(this orelse current);
    }

    pub fn fromExpr(expr: bun.ast.Expr) OOM!?ConfigVersion {
        switch (expr.data) {
            .e_string => {
                const config_version_str = expr.data.e_string.slice(bun.default_allocator);

                if (bun_config_versions.get(config_version_str)) |config_version| {
                    return config_version;
                }

                // const config_version_sliced = semver.SlicedString.init(config_version_str, config_version_str);
                // const config_version_range = try semver.Query.parse(bun.default_allocator, config_version_str, config_version_sliced);

                // for (bun_versions) |version_info| {
                //     const version, const config_version = version_info;
                //     const v = semver.Version.parseUTF8(version).version.min();
                //     if (config_version_range.satisfies(v, version, config_version_str)) {
                //         return config_version;
                //     }
                // }

                // if nothing matches default to current
                return .current;
            },
            .e_number => {
                const config_version = expr.data.e_number.value;
                return fromNum(config_version);
            },
            else => {},
        }
        return null;
    }

    pub fn fromNum(config_version: anytype) ?ConfigVersion {
        if (config_version == 0) {
            return .v0;
        } else if (config_version == 1) {
            return .v1;
        }

        if (config_version > @intFromEnum(current)) {
            return current;
        }

        return null;
    }
};

const bun_config_versions = bun.ComptimeStringMap(ConfigVersion, .{
    .{ "1.3.2", ConfigVersion.v1 },
    .{ "1.3.1", ConfigVersion.v1 },
    .{ "1.3.0", ConfigVersion.v1 },
    .{ "1.2.23", ConfigVersion.v0 },
    .{ "1.2.22", ConfigVersion.v0 },
    .{ "1.2.21", ConfigVersion.v0 },
    .{ "1.2.20", ConfigVersion.v0 },
    .{ "1.2.19", ConfigVersion.v0 },
    .{ "1.2.18", ConfigVersion.v0 },
    .{ "1.2.17", ConfigVersion.v0 },
    .{ "1.2.16", ConfigVersion.v0 },
    .{ "1.2.15", ConfigVersion.v0 },
    .{ "1.2.14", ConfigVersion.v0 },
    .{ "1.2.13", ConfigVersion.v0 },
    .{ "1.2.12", ConfigVersion.v0 },
    .{ "1.2.11", ConfigVersion.v0 },
    .{ "1.2.10", ConfigVersion.v0 },
    .{ "1.2.9", ConfigVersion.v0 },
    .{ "1.2.8", ConfigVersion.v0 },
    .{ "1.2.7", ConfigVersion.v0 },
    .{ "1.2.6", ConfigVersion.v0 },
    .{ "1.2.5", ConfigVersion.v0 },
    .{ "1.2.4", ConfigVersion.v0 },
    .{ "1.2.3", ConfigVersion.v0 },
    .{ "1.2.2", ConfigVersion.v0 },
    .{ "1.2.1", ConfigVersion.v0 },
    .{ "1.2.0", ConfigVersion.v0 },
    .{ "1.1.45", ConfigVersion.v0 },
    .{ "1.1.44", ConfigVersion.v0 },
    .{ "1.1.43", ConfigVersion.v0 },
    .{ "1.1.42", ConfigVersion.v0 },
    .{ "1.1.41", ConfigVersion.v0 },
    .{ "1.1.40", ConfigVersion.v0 },
    .{ "1.1.39", ConfigVersion.v0 },
    .{ "1.1.38", ConfigVersion.v0 },
    .{ "1.1.37", ConfigVersion.v0 },
    .{ "1.1.36", ConfigVersion.v0 },
    .{ "1.1.35", ConfigVersion.v0 },
    .{ "1.1.34", ConfigVersion.v0 },
    .{ "1.1.33", ConfigVersion.v0 },
    .{ "1.1.32", ConfigVersion.v0 },
    .{ "1.1.31", ConfigVersion.v0 },
    .{ "1.1.30", ConfigVersion.v0 },
    .{ "1.1.29", ConfigVersion.v0 },
    .{ "1.1.28", ConfigVersion.v0 },
    .{ "1.1.27", ConfigVersion.v0 },
    .{ "1.1.26", ConfigVersion.v0 },
    .{ "1.1.25", ConfigVersion.v0 },
    .{ "1.1.24", ConfigVersion.v0 },
    .{ "1.1.23", ConfigVersion.v0 },
    .{ "1.1.22", ConfigVersion.v0 },
    .{ "1.1.21", ConfigVersion.v0 },
    .{ "1.1.20", ConfigVersion.v0 },
    .{ "1.1.19", ConfigVersion.v0 },
    .{ "1.1.18", ConfigVersion.v0 },
    .{ "1.1.17", ConfigVersion.v0 },
    .{ "1.1.16", ConfigVersion.v0 },
    .{ "1.1.15", ConfigVersion.v0 },
    .{ "1.1.14", ConfigVersion.v0 },
    .{ "1.1.13", ConfigVersion.v0 },
    .{ "1.1.12", ConfigVersion.v0 },
    .{ "1.1.11", ConfigVersion.v0 },
    .{ "1.1.10", ConfigVersion.v0 },
    .{ "1.1.9", ConfigVersion.v0 },
    .{ "1.1.8", ConfigVersion.v0 },
    .{ "1.1.7", ConfigVersion.v0 },
    .{ "1.1.6", ConfigVersion.v0 },
    .{ "1.1.5", ConfigVersion.v0 },
    .{ "1.1.4", ConfigVersion.v0 },
    .{ "1.1.3", ConfigVersion.v0 },
    .{ "1.1.2", ConfigVersion.v0 },
    .{ "1.1.1", ConfigVersion.v0 },
    .{ "1.1.0", ConfigVersion.v0 },
    .{ "1.0.36", ConfigVersion.v0 },
    .{ "1.0.35", ConfigVersion.v0 },
    .{ "1.0.34", ConfigVersion.v0 },
    .{ "1.0.33", ConfigVersion.v0 },
    .{ "1.0.32", ConfigVersion.v0 },
    .{ "1.0.31", ConfigVersion.v0 },
    .{ "1.0.30", ConfigVersion.v0 },
    .{ "1.0.29", ConfigVersion.v0 },
    .{ "1.0.28", ConfigVersion.v0 },
    .{ "1.0.27", ConfigVersion.v0 },
    .{ "1.0.26", ConfigVersion.v0 },
    .{ "1.0.25", ConfigVersion.v0 },
    .{ "1.0.24", ConfigVersion.v0 },
    .{ "1.0.23", ConfigVersion.v0 },
    .{ "1.0.22", ConfigVersion.v0 },
    .{ "1.0.21", ConfigVersion.v0 },
    .{ "1.0.20", ConfigVersion.v0 },
    .{ "1.0.19", ConfigVersion.v0 },
    .{ "1.0.18", ConfigVersion.v0 },
    .{ "1.0.17", ConfigVersion.v0 },
    .{ "1.0.16", ConfigVersion.v0 },
    .{ "1.0.15", ConfigVersion.v0 },
    .{ "1.0.14", ConfigVersion.v0 },
    .{ "1.0.13", ConfigVersion.v0 },
    .{ "1.0.12", ConfigVersion.v0 },
    .{ "1.0.11", ConfigVersion.v0 },
    .{ "1.0.10", ConfigVersion.v0 },
    .{ "1.0.9", ConfigVersion.v0 },
    .{ "1.0.8", ConfigVersion.v0 },
    .{ "1.0.7", ConfigVersion.v0 },
    .{ "1.0.6", ConfigVersion.v0 },
    .{ "1.0.5", ConfigVersion.v0 },
    .{ "1.0.4", ConfigVersion.v0 },
    .{ "1.0.3", ConfigVersion.v0 },
    .{ "1.0.2", ConfigVersion.v0 },
    .{ "1.0.1", ConfigVersion.v0 },
    .{ "1.0.0", ConfigVersion.v0 },
    .{ "0.8.1", ConfigVersion.v0 },
    .{ "0.8.0", ConfigVersion.v0 },
    .{ "0.7.3", ConfigVersion.v0 },
    .{ "0.7.2", ConfigVersion.v0 },
    .{ "0.7.1", ConfigVersion.v0 },
    .{ "0.7.0", ConfigVersion.v0 },
    .{ "0.6.14", ConfigVersion.v0 },
    .{ "0.6.13", ConfigVersion.v0 },
    .{ "0.6.12", ConfigVersion.v0 },
    .{ "0.6.11", ConfigVersion.v0 },
    .{ "0.6.10", ConfigVersion.v0 },
    .{ "0.6.9", ConfigVersion.v0 },
    .{ "0.6.8", ConfigVersion.v0 },
    .{ "0.6.7", ConfigVersion.v0 },
    .{ "0.6.6", ConfigVersion.v0 },
    .{ "0.6.5", ConfigVersion.v0 },
    .{ "0.6.4", ConfigVersion.v0 },
    .{ "0.6.3", ConfigVersion.v0 },
    .{ "0.6.2", ConfigVersion.v0 },
    .{ "0.6.1", ConfigVersion.v0 },
    .{ "0.6.0", ConfigVersion.v0 },
    .{ "0.5.9", ConfigVersion.v0 },
    .{ "0.5.8", ConfigVersion.v0 },
    .{ "0.5.7", ConfigVersion.v0 },
    .{ "0.5.6", ConfigVersion.v0 },
    .{ "0.5.5", ConfigVersion.v0 },
    .{ "0.5.4", ConfigVersion.v0 },
    .{ "0.5.3", ConfigVersion.v0 },
    .{ "0.5.2", ConfigVersion.v0 },
    .{ "0.5.1", ConfigVersion.v0 },
    .{ "0.5.0", ConfigVersion.v0 },
    .{ "0.4.0", ConfigVersion.v0 },
    .{ "0.3.0", ConfigVersion.v0 },
    .{ "0.2.2", ConfigVersion.v0 },
    .{ "0.2.1", ConfigVersion.v0 },
    .{ "0.2.0", ConfigVersion.v0 },
    .{ "0.1.13", ConfigVersion.v0 },
    .{ "0.1.12", ConfigVersion.v0 },
    .{ "0.1.11", ConfigVersion.v0 },
    .{ "0.1.10", ConfigVersion.v0 },
    .{ "0.1.9", ConfigVersion.v0 },
    .{ "0.1.8", ConfigVersion.v0 },
    .{ "0.1.7", ConfigVersion.v0 },
    .{ "0.1.6", ConfigVersion.v0 },
    .{ "0.1.5", ConfigVersion.v0 },
    .{ "0.1.4", ConfigVersion.v0 },
    .{ "0.1.3", ConfigVersion.v0 },
    .{ "0.1.2", ConfigVersion.v0 },
    .{ "0.1.1", ConfigVersion.v0 },
    .{ "0.1.0", ConfigVersion.v0 },
    .{ "0.0.83", ConfigVersion.v0 },
    .{ "0.0.82", ConfigVersion.v0 },
    .{ "0.0.81", ConfigVersion.v0 },
    .{ "0.0.80", ConfigVersion.v0 },
    .{ "0.0.79", ConfigVersion.v0 },
    .{ "0.0.78", ConfigVersion.v0 },
    .{ "0.0.77", ConfigVersion.v0 },
    .{ "0.0.76", ConfigVersion.v0 },
    .{ "0.0.75", ConfigVersion.v0 },
    .{ "0.0.74", ConfigVersion.v0 },
    .{ "0.0.73", ConfigVersion.v0 },
    .{ "0.0.72", ConfigVersion.v0 },
    .{ "0.0.71", ConfigVersion.v0 },
    .{ "0.0.70", ConfigVersion.v0 },
    .{ "0.0.69", ConfigVersion.v0 },
    .{ "0.0.68", ConfigVersion.v0 },
    .{ "0.0.66", ConfigVersion.v0 },
    .{ "0.0.65", ConfigVersion.v0 },
    .{ "0.0.64", ConfigVersion.v0 },
    .{ "0.0.63", ConfigVersion.v0 },
    .{ "0.0.62", ConfigVersion.v0 },
    .{ "0.0.61", ConfigVersion.v0 },
    .{ "0.0.60", ConfigVersion.v0 },
    .{ "0.0.59", ConfigVersion.v0 },
    .{ "0.0.58", ConfigVersion.v0 },
    .{ "0.0.57", ConfigVersion.v0 },
    .{ "0.0.56", ConfigVersion.v0 },
    .{ "0.0.55", ConfigVersion.v0 },
    .{ "0.0.54", ConfigVersion.v0 },
    .{ "0.0.53", ConfigVersion.v0 },
    .{ "0.0.52", ConfigVersion.v0 },
    .{ "0.0.51", ConfigVersion.v0 },
    .{ "0.0.50", ConfigVersion.v0 },
    .{ "0.0.49", ConfigVersion.v0 },
    .{ "0.0.48", ConfigVersion.v0 },
    .{ "0.0.46", ConfigVersion.v0 },
    .{ "0.0.45", ConfigVersion.v0 },
    .{ "0.0.44", ConfigVersion.v0 },
    .{ "0.0.43", ConfigVersion.v0 },
    .{ "0.0.42", ConfigVersion.v0 },
    .{ "0.0.41", ConfigVersion.v0 },
    .{ "0.0.40", ConfigVersion.v0 },
    .{ "0.0.39", ConfigVersion.v0 },
    .{ "0.0.38", ConfigVersion.v0 },
    .{ "0.0.37", ConfigVersion.v0 },
    .{ "0.0.36", ConfigVersion.v0 },
    .{ "0.0.35", ConfigVersion.v0 },
    .{ "0.0.34", ConfigVersion.v0 },
    .{ "0.0.32", ConfigVersion.v0 },
    .{ "0.0.31", ConfigVersion.v0 },
    .{ "0.0.30", ConfigVersion.v0 },
    .{ "0.0.29", ConfigVersion.v0 },
    .{ "0.0.28", ConfigVersion.v0 },
    .{ "0.0.27", ConfigVersion.v0 },
    .{ "0.0.26", ConfigVersion.v0 },
    .{ "0.0.25", ConfigVersion.v0 },
    .{ "0.0.24", ConfigVersion.v0 },
    .{ "0.0.23", ConfigVersion.v0 },
    .{ "0.0.22", ConfigVersion.v0 },
    .{ "0.0.21", ConfigVersion.v0 },
    .{ "0.0.20", ConfigVersion.v0 },
    .{ "0.0.19", ConfigVersion.v0 },
    .{ "0.0.18", ConfigVersion.v0 },
    .{ "0.0.17", ConfigVersion.v0 },
    .{ "0.0.16", ConfigVersion.v0 },
    .{ "0.0.15", ConfigVersion.v0 },
});

pub const PublishConfig = struct {
    access: ?Access = null,
    tag: string = "",
    otp: string = "",
    auth_type: ?AuthType = null,
    tolerate_republish: bool = false,
};

pub const Access = enum {
    public,
    restricted,

    const map = bun.ComptimeEnumMap(Access);

    pub fn fromStr(str: string) ?Access {
        return map.get(str);
    }
};

pub const AuthType = enum {
    legacy,
    web,

    const map = bun.ComptimeEnumMap(AuthType);

    pub fn fromStr(str: string) ?AuthType {
        return map.get(str);
    }
};

pub fn shouldPrintCommandName(this: *const Options) bool {
    return this.log_level != .silent and this.do.summary;
}

pub const LogLevel = enum {
    default,
    verbose,
    silent,
    quiet,
    default_no_progress,
    verbose_no_progress,

    pub inline fn isVerbose(this: LogLevel) bool {
        return switch (this) {
            .verbose_no_progress, .verbose => true,
            else => false,
        };
    }
    pub inline fn showProgress(this: LogLevel) bool {
        return switch (this) {
            .default, .verbose => true,
            else => false,
        };
    }
};

pub const NodeLinker = enum(u8) {
    // If workspaces are used: isolated
    // If not: hoisted
    // Used when nodeLinker is absent from package.json/bun.lock/bun.lockb
    auto,

    hoisted,
    isolated,

    pub fn fromStr(input: string) ?NodeLinker {
        if (strings.eqlComptime(input, "hoisted")) {
            return .hoisted;
        }
        if (strings.eqlComptime(input, "isolated")) {
            return .isolated;
        }
        return null;
    }
};

pub const Update = struct {
    development: bool = false,
    optional: bool = false,
    peer: bool = false,
};

pub fn openGlobalDir(explicit_global_dir: string) !std.fs.Dir {
    if (bun.env_var.BUN_INSTALL_GLOBAL_DIR.get()) |home_dir| {
        return try std.fs.cwd().makeOpenPath(home_dir, .{});
    }

    if (explicit_global_dir.len > 0) {
        return try std.fs.cwd().makeOpenPath(explicit_global_dir, .{});
    }

    if (bun.env_var.BUN_INSTALL.get()) |home_dir| {
        var buf: bun.PathBuffer = undefined;
        var parts = [_]string{ "install", "global" };
        const path = Path.joinAbsStringBuf(home_dir, &buf, &parts, .auto);
        return try std.fs.cwd().makeOpenPath(path, .{});
    }

    if (bun.env_var.XDG_CACHE_HOME.get() orelse bun.env_var.HOME.get()) |home_dir| {
        var buf: bun.PathBuffer = undefined;
        var parts = [_]string{ ".bun", "install", "global" };
        const path = Path.joinAbsStringBuf(home_dir, &buf, &parts, .auto);
        return try std.fs.cwd().makeOpenPath(path, .{});
    }

    return error.@"No global directory found";
}

pub fn openGlobalBinDir(opts_: ?*const Api.BunInstall) !std.fs.Dir {
    if (bun.env_var.BUN_INSTALL_BIN.get()) |home_dir| {
        return try std.fs.cwd().makeOpenPath(home_dir, .{});
    }

    if (opts_) |opts| {
        if (opts.global_bin_dir) |home_dir| {
            if (home_dir.len > 0) {
                return try std.fs.cwd().makeOpenPath(home_dir, .{});
            }
        }
    }

    if (bun.env_var.BUN_INSTALL.get()) |home_dir| {
        var buf: bun.PathBuffer = undefined;
        var parts = [_]string{
            "bin",
        };
        const path = Path.joinAbsStringBuf(home_dir, &buf, &parts, .auto);
        return try std.fs.cwd().makeOpenPath(path, .{});
    }

    if (bun.env_var.XDG_CACHE_HOME.get() orelse bun.env_var.HOME.get()) |home_dir| {
        var buf: bun.PathBuffer = undefined;
        var parts = [_]string{
            ".bun",
            "bin",
        };
        const path = Path.joinAbsStringBuf(home_dir, &buf, &parts, .auto);
        return try std.fs.cwd().makeOpenPath(path, .{});
    }

    return error.@"Missing global bin directory: try setting $BUN_INSTALL";
}

pub fn load(
    this: *Options,
    allocator: std.mem.Allocator,
    log: *logger.Log,
    env: *DotEnv.Loader,
    maybe_cli: ?CommandLineArguments,
    bun_install_: ?*Api.BunInstall,
    subcommand: Subcommand,
) bun.OOM!void {
    var base = Api.NpmRegistry{
        .url = "",
        .username = "",
        .password = "",
        .token = "",
        .email = "",
    };
    if (bun_install_) |config| {
        if (config.default_registry) |registry| {
            base = registry;
        }
        if (config.link_workspace_packages) |link_workspace_packages| {
            this.link_workspace_packages = link_workspace_packages;
        }
    }

    if (base.url.len == 0) base.url = Npm.Registry.default_url;
    this.scope = try Npm.Registry.Scope.fromAPI("", base, allocator, env);
    defer {
        this.did_override_default_scope = this.scope.url_hash != Npm.Registry.default_url_hash;
    }
    if (bun_install_) |config| {
        if (config.config_version) |config_version| {
            this.config_version = config_version;
        }

        if (config.cache_directory) |cache_directory| {
            this.cache_directory = cache_directory;
        }

        if (config.scoped) |scoped| {
            for (scoped.scopes.keys(), scoped.scopes.values()) |name, *registry_| {
                var registry = registry_.*;
                if (registry.url.len == 0) registry.url = base.url;
                try this.registries.put(allocator, Npm.Registry.Scope.hash(name), try Npm.Registry.Scope.fromAPI(name, registry, allocator, env));
            }
        }

        if (config.ca) |ca| {
            switch (ca) {
                .list => |ca_list| {
                    this.ca = ca_list;
                },
                .str => |ca_str| {
                    this.ca = &.{ca_str};
                },
            }
        }

        if (config.node_linker) |node_linker| {
            this.node_linker = node_linker;
        }

        if (config.security_scanner) |security_scanner| {
            this.security_scanner = security_scanner;
            this.do.prefetch_resolved_tarballs = false;
        }

        if (config.cafile) |cafile| {
            this.ca_file_name = cafile;
        }

        if (config.disable_cache orelse false) {
            this.enable.cache = false;
        }

        if (config.disable_manifest_cache orelse false) {
            this.enable.manifest_cache = false;
        }

        if (config.force orelse false) {
            this.enable.manifest_cache_control = false;
            this.enable.force_install = true;
        }

        if (config.save_yarn_lockfile orelse false) {
            this.do.save_yarn_lock = true;
        }

        if (config.save_lockfile) |save_lockfile| {
            this.do.save_lockfile = save_lockfile;
            this.enable.force_save_lockfile = true;
        }

        if (config.save_dev) |save| {
            this.local_package_features.dev_dependencies = save;
            // remote packages should never install dev dependencies
            // (TODO: unless git dependency with postinstalls)
        }

        if (config.save_optional) |save| {
            this.remote_package_features.optional_dependencies = save;
            this.local_package_features.optional_dependencies = save;
        }

        if (config.save_peer) |save| {
            this.remote_package_features.peer_dependencies = save;
            this.local_package_features.peer_dependencies = save;
        }

        if (config.exact) |exact| {
            this.enable.exact_versions = exact;
        }

        if (config.production) |production| {
            if (production) {
                this.local_package_features.dev_dependencies = false;
                this.enable.fail_early = true;
                this.enable.frozen_lockfile = true;
                this.enable.force_save_lockfile = false;
            }
        }

        if (config.frozen_lockfile) |frozen_lockfile| {
            if (frozen_lockfile) {
                this.enable.frozen_lockfile = true;
            }
        }

        if (config.save_text_lockfile) |save_text_lockfile| {
            this.save_text_lockfile = save_text_lockfile;
        }

        if (config.concurrent_scripts) |jobs| {
            this.max_concurrent_lifecycle_scripts = jobs;
        }

        if (config.cache_directory) |cache_dir| {
            this.cache_directory = cache_dir;
        }

        if (config.ignore_scripts) |ignore_scripts| {
            if (ignore_scripts) {
                this.do.run_scripts = false;
            }
        }

        if (config.minimum_release_age_ms) |min_age_ms| {
            this.minimum_release_age_ms = min_age_ms;
        }

        if (config.minimum_release_age_excludes) |exclusions| {
            this.minimum_release_age_excludes = exclusions;
        }

        if (config.public_hoist_pattern) |public_hoist_pattern| {
            this.public_hoist_pattern = public_hoist_pattern;
        }

        if (config.hoist_pattern) |hoist_pattern| {
            this.hoist_pattern = hoist_pattern;
        }

        this.explicit_global_directory = config.global_dir orelse this.explicit_global_directory;
    }

    const default_disable_progress_bar: bool = brk: {
        if (env.get("BUN_INSTALL_PROGRESS")) |prog| {
            break :brk strings.eqlComptime(prog, "0");
        }

        if (env.isCI()) {
            break :brk true;
        }

        break :brk Output.stderr_descriptor_type != .terminal;
    };

    // technically, npm_config is case in-sensitive
    // load_registry:
    {
        const registry_keys = [_]string{
            "BUN_CONFIG_REGISTRY",
            "NPM_CONFIG_REGISTRY",
            "npm_config_registry",
        };
        var did_set = false;

        inline for (registry_keys) |registry_key| {
            if (!did_set) {
                if (env.get(registry_key)) |registry_| {
                    if (registry_.len > 0 and
                        (strings.startsWith(registry_, "https://") or
                            strings.startsWith(registry_, "http://")))
                    {
                        const prev_scope = this.scope;
                        var api_registry = std.mem.zeroes(Api.NpmRegistry);
                        api_registry.url = registry_;
                        api_registry.token = prev_scope.token;
                        this.scope = try Npm.Registry.Scope.fromAPI("", api_registry, allocator, env);
                        did_set = true;
                    }
                }
            }
        }
    }

    {
        const token_keys = [_]string{
            "BUN_CONFIG_TOKEN",
            "NPM_CONFIG_TOKEN",
            "npm_config_token",
        };
        var did_set = false;

        inline for (token_keys) |registry_key| {
            if (!did_set) {
                if (env.get(registry_key)) |registry_| {
                    if (registry_.len > 0) {
                        this.scope.token = registry_;
                        did_set = true;
                        // stage1 bug: break inside inline is broken
                        // break :load_registry;
                    }
                }
            }
        }
    }

    if (env.get("BUN_CONFIG_YARN_LOCKFILE") != null) {
        this.do.save_yarn_lock = true;
    }

    if (env.get("BUN_CONFIG_HTTP_RETRY_COUNT")) |retry_count| {
        if (std.fmt.parseInt(u16, retry_count, 10)) |int| this.max_retry_count = int else |_| {}
    }

    AsyncHTTP.loadEnv(allocator, log, env);

    if (env.get("BUN_CONFIG_SKIP_SAVE_LOCKFILE")) |check_bool| {
        this.do.save_lockfile = strings.eqlComptime(check_bool, "0");
    }

    if (env.get("BUN_CONFIG_SKIP_LOAD_LOCKFILE")) |check_bool| {
        this.do.load_lockfile = strings.eqlComptime(check_bool, "0");
    }

    if (env.get("BUN_CONFIG_SKIP_INSTALL_PACKAGES")) |check_bool| {
        this.do.install_packages = strings.eqlComptime(check_bool, "0");
    }

    if (env.get("BUN_CONFIG_NO_VERIFY")) |check_bool| {
        this.do.verify_integrity = !strings.eqlComptime(check_bool, "0");
    }

    // Update should never read from manifest cache
    if (subcommand == .update) {
        this.enable.manifest_cache = false;
        this.enable.manifest_cache_control = false;
    }

    if (maybe_cli) |cli| {
        this.do.analyze = cli.analyze;
        this.enable.only_missing = cli.only_missing or cli.analyze;

        if (cli.registry.len > 0) {
            this.scope.url = URL.parse(cli.registry);
        }

        if (cli.cache_dir) |cache_dir| {
            this.cache_directory = cache_dir;
        }

        if (cli.exact) {
            this.enable.exact_versions = true;
        }

        if (cli.token.len > 0) {
            this.scope.token = cli.token;
        }

        if (cli.no_save) {
            this.do.save_lockfile = false;
            this.do.write_package_json = false;
        }

        if (cli.dry_run) {
            this.do.install_packages = false;
            this.dry_run = true;
            this.do.write_package_json = false;
            this.do.save_lockfile = false;
        }

        if (cli.no_summary or cli.silent) {
            this.do.summary = false;
        }

        this.filter_patterns = cli.filters;
        this.pack_destination = cli.pack_destination;
        this.pack_filename = cli.pack_filename;
        this.pack_gzip_level = cli.pack_gzip_level;
        this.json_output = cli.json_output;

        if (cli.no_cache) {
            this.enable.manifest_cache = false;
            this.enable.manifest_cache_control = false;
        }

        if (cli.omit) |omit| {
            if (omit.dev) {
                this.local_package_features.dev_dependencies = false;
                // remote packages should never install dev dependencies
                // (TODO: unless git dependency with postinstalls)
            }

            if (omit.optional) {
                this.local_package_features.optional_dependencies = false;
                this.remote_package_features.optional_dependencies = false;
            }

            if (omit.peer) {
                this.local_package_features.peer_dependencies = false;
                this.remote_package_features.peer_dependencies = false;
            }
        }

        if (cli.ignore_scripts) {
            this.do.run_scripts = false;
        }

        if (cli.trusted) {
            this.do.trust_dependencies_from_args = true;
        }

        if (cli.save_text_lockfile) |save_text_lockfile| {
            this.save_text_lockfile = save_text_lockfile;
        }

        if (cli.minimum_release_age_ms) |min_age_ms| {
            this.minimum_release_age_ms = min_age_ms;
        }

        this.lockfile_only = cli.lockfile_only;

        if (cli.lockfile_only) {
            this.do.prefetch_resolved_tarballs = false;
        }

        if (cli.node_linker) |node_linker| {
            this.node_linker = node_linker;
        }

        const disable_progress_bar = default_disable_progress_bar or cli.no_progress;

        if (cli.verbose) {
            this.log_level = if (disable_progress_bar) LogLevel.verbose_no_progress else LogLevel.verbose;
            PackageManager.verbose_install = true;
        } else if (cli.silent) {
            this.log_level = .silent;
            PackageManager.verbose_install = false;
        } else if (cli.quiet) {
            this.log_level = .quiet;
            PackageManager.verbose_install = false;
        } else {
            this.log_level = if (disable_progress_bar) LogLevel.default_no_progress else LogLevel.default;
            PackageManager.verbose_install = false;
        }

        if (cli.no_verify) {
            this.do.verify_integrity = false;
        }

        if (cli.yarn) {
            this.do.save_yarn_lock = true;
        }

        if (cli.backend) |backend| {
            PackageInstall.supported_method = backend;
        }

        // CPU and OS are now parsed as enums in CommandLineArguments, just copy them
        this.cpu = cli.cpu;
        this.os = cli.os;

        this.do.update_to_latest = cli.latest;
        this.do.recursive = cli.recursive;

        if (cli.positionals.len > 0) {
            this.positionals = cli.positionals;
        }

        if (cli.production) {
            this.local_package_features.dev_dependencies = false;
            this.enable.fail_early = true;
            this.enable.frozen_lockfile = true;
        }

        if (cli.frozen_lockfile) {
            this.enable.frozen_lockfile = true;
        }

        if (cli.force) {
            this.enable.manifest_cache_control = false;
            this.enable.force_install = true;
            this.enable.force_save_lockfile = true;
        }

        if (cli.development) {
            this.update.development = cli.development;
        } else if (cli.optional) {
            this.update.optional = cli.optional;
        } else if (cli.peer) {
            this.update.peer = cli.peer;
        }

        switch (cli.patch) {
            .nothing => {},
            .patch => {
                this.patch_features = .{ .patch = .{} };
            },
            .commit => {
                this.patch_features = .{
                    .commit = .{
                        .patches_dir = cli.patch.commit.patches_dir,
                    },
                };
            },
        }

        if (cli.publish_config.access) |cli_access| {
            this.publish_config.access = cli_access;
        }
        if (cli.publish_config.tag.len > 0) {
            this.publish_config.tag = cli.publish_config.tag;
        }
        if (cli.publish_config.otp.len > 0) {
            this.publish_config.otp = cli.publish_config.otp;
        }
        if (cli.publish_config.auth_type) |auth_type| {
            this.publish_config.auth_type = auth_type;
        }
        this.publish_config.tolerate_republish = cli.tolerate_republish;

        if (cli.ca.len > 0) {
            this.ca = cli.ca;
        }
        if (cli.ca_file_name.len > 0) {
            this.ca_file_name = cli.ca_file_name;
        }

        // `bun pm version` command options
        this.git_tag_version = cli.git_tag_version;
        this.allow_same_version = cli.allow_same_version;
        this.preid = cli.preid;
        this.message = cli.message;
        this.force = cli.force;

        // `bun pm why` command options
        this.top_only = cli.top_only;
        this.depth = cli.depth;
    } else {
        this.log_level = if (default_disable_progress_bar) LogLevel.default_no_progress else LogLevel.default;
        PackageManager.verbose_install = false;
    }

    // If the lockfile is frozen, don't save it to disk.
    if (this.enable.frozen_lockfile) {
        this.do.save_lockfile = false;
        this.enable.force_save_lockfile = false;
    }
}

pub const Do = packed struct(u16) {
    save_lockfile: bool = true,
    load_lockfile: bool = true,
    install_packages: bool = true,
    write_package_json: bool = true,
    run_scripts: bool = true,
    save_yarn_lock: bool = false,
    print_meta_hash_string: bool = false,
    verify_integrity: bool = true,
    summary: bool = true,
    trust_dependencies_from_args: bool = false,
    update_to_latest: bool = false,
    analyze: bool = false,
    recursive: bool = false,
    prefetch_resolved_tarballs: bool = true,
    _: u2 = 0,
};

pub const Enable = packed struct(u16) {
    manifest_cache: bool = true,
    manifest_cache_control: bool = true,
    cache: bool = true,
    fail_early: bool = false,
    frozen_lockfile: bool = false,

    // Don't save the lockfile unless there were actual changes
    // unless...
    force_save_lockfile: bool = false,

    force_install: bool = false,

    exact_versions: bool = false,
    only_missing: bool = false,
    _: u7 = 0,
};

const string = []const u8;
const stringZ = [:0]const u8;

const CommandLineArguments = @import("./CommandLineArguments.zig");
const std = @import("std");

const bun = @import("bun");
const DotEnv = bun.DotEnv;
const FD = bun.FD;
const OOM = bun.OOM;
const Output = bun.Output;
const Path = bun.path;
const URL = bun.URL;
const logger = bun.logger;
const semver = bun.semver;
const strings = bun.strings;
const Api = bun.schema.api;

const HTTP = bun.http;
const AsyncHTTP = HTTP.AsyncHTTP;

const Features = bun.install.Features;
const Npm = bun.install.Npm;
const PackageInstall = bun.install.PackageInstall;
const patch = bun.install.patch;

const PackageManager = bun.install.PackageManager;
const Subcommand = bun.install.PackageManager.Subcommand;
