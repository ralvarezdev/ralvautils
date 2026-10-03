$Script:DevFolderNames = @(
    # JavaScript / TypeScript / Bundlers
    'node_modules', '.turbo', '.next', '.nuxt', '.parsed-cache',
    '.eslintcache', '.prettiercache', '.pnpm-store', '.yarn',

    # Python & environment managers
    '.venv', 'venv', '__pycache__', '.pytest_cache',
    '.mypy_cache', '.ruff_cache', '.tox', '.pixi', 'envs',

    # Go / tooling / general CI
    '.golangci-lint', '.task',

    # Build artifacts
    'dist', 'target', 'build', '_build',
    'obj', 'bin', 'cmake-build-debug', 'cmake-build-release',
    '.vs', 'ipch', '.tlog', '.gradle'
)
